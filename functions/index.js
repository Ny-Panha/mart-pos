const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const functions = require('firebase-functions');

initializeApp();

const db = getFirestore();
const auth = getAuth();
const DEFAULT_SHOP_ID = 'default-shop';
const ROLES = Object.freeze({ MANAGER: 'ADMIN_MANAGER', ADMIN: 'ADMIN', CASHIER: 'CASHIER' });

function timestampFromInput(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  if (typeof value === 'string') {
    const parsed = new Date(value);
    return Number.isNaN(parsed.valueOf()) ? null : parsed;
  }
  if (typeof value === 'object') {
    const seconds = value.seconds ?? value._seconds;
    const nanos = value.nanoseconds ?? value._nanoseconds ?? 0;
    if (typeof seconds === 'number') return new Date(seconds * 1000 + Math.floor(nanos / 1e6));
  }
  return null;
}

function authUserOptions(email, displayName, temporaryPassword) {
  const options = { email, displayName, disabled: false };
  if (temporaryPassword && String(temporaryPassword).trim()) options.password = String(temporaryPassword).trim();
  return options;
}

function normalizeRole(value) {
  const role = String(value || '').trim().toUpperCase();
  if (role === 'MANAGER' || role === 'SUPER' || role === 'ADMIN_MANAGER') return ROLES.MANAGER;
  if (role === 'ADMIN') return ROLES.ADMIN;
  if (role === 'CASHIER') return ROLES.CASHIER;
  throw new functions.https.HttpsError('invalid-argument', 'Unsupported role.');
}

async function actorFromContext(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign-in is required.');
  }
  const snapshot = await db.collection('users').doc(context.auth.uid).get();
  if (!snapshot.exists) {
    throw new functions.https.HttpsError('permission-denied', 'User profile is not provisioned.');
  }
  const actor = snapshot.data() || {};
  const role = normalizeRole(actor.role);
  if (actor.active === false) {
    throw new functions.https.HttpsError('permission-denied', 'User account is inactive.');
  }
  return { uid: context.auth.uid, role, shopId: actor.shopId || null, profile: actor };
}

function requireManager(actor) {
  if (actor.role !== ROLES.MANAGER) {
    throw new functions.https.HttpsError('permission-denied', 'Manager authorization is required.');
  }
}

function requireManagerOrAdminInShop(actor, shopId) {
  if (actor.role === ROLES.MANAGER) return;
  if (actor.role !== ROLES.ADMIN || !actor.shopId || actor.shopId !== shopId) {
    throw new functions.https.HttpsError('permission-denied', 'Shop administrator authorization is required.');
  }
}

async function recordManagerLog(actor, action, details = {}) {
  try {
    await db.collection('managerLogs').add({
      action,
      actorId: actor.uid,
      actorName: actor.profile.name || actor.profile.displayName || actor.uid,
      entity: details.shopId || details.uid || details.alertId || 'platform',
      severity: 'info',
      message: action.replaceAll('.', ' '),
      details,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('Unable to write manager audit log:', error);
  }
}

function cleanString(value, field, maxLength = 200) {
  const clean = String(value || '').trim();
  if (!clean || clean.length > maxLength) {
    throw new functions.https.HttpsError('invalid-argument', `${field} is required.`);
  }
  return clean;
}

function cleanShopId(value) {
  const shopId = cleanString(value, 'shopId', 96);
  if (!/^[A-Za-z0-9_-]+$/.test(shopId)) {
    throw new functions.https.HttpsError('invalid-argument', 'shopId contains unsupported characters.');
  }
  return shopId;
}

exports.provisionShop = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  requireManager(actor);
  const name = cleanString(data && data.name, 'name');
  const shopId = data && data.shopId ? cleanShopId(data.shopId) : db.collection('shops').doc().id;
  const now = FieldValue.serverTimestamp();
  const shopRef = db.collection('shops').doc(shopId);
  const shop = {
    name,
    ownerName: cleanString(data && data.ownerName, 'ownerName'),
    ownerEmail: cleanString(data && data.ownerEmail, 'ownerEmail', 320).toLowerCase(),
    phone: String((data && data.phone) || '').trim(),
    address: String((data && data.address) || '').trim(),
    slug: String((data && data.slug) || name).trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, ''),
    status: 'active',
    createdBy: actor.uid,
    createdAt: now,
    updatedAt: now,
  };
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(shopRef);
    if (existing.exists) {
      throw new functions.https.HttpsError('already-exists', 'Shop already exists.');
    }
    transaction.set(shopRef, shop);
  });
  await recordManagerLog(actor, 'shop.created', { shopId, name });
  return { shopId, ...shop, createdAt: undefined, updatedAt: undefined };
});

async function provisionAuthProfile({ uid, email, displayName, role, shopId, createdBy }) {
  const profile = {
    name: displayName,
    displayName,
    email,
    role,
    shopId,
    active: true,
    createdAt: FieldValue.serverTimestamp(),
    createdBy,
  };
  await db.collection('users').doc(uid).set(profile);
  await auth.setCustomUserClaims(uid, { role, shopId });
  return profile;
}

exports.provisionShopAdmin = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  requireManager(actor);
  const shopId = cleanShopId(data && data.shopId);
  const shopRef = await db.collection('shops').doc(shopId).get();
  if (!shopRef.exists) throw new functions.https.HttpsError('not-found', 'Shop not found.');
  const displayName = cleanString(data && data.displayName, 'displayName');
  const email = cleanString(data && data.email, 'email', 320).toLowerCase();
  let firebaseUser;
  try {
    firebaseUser = await auth.createUser(authUserOptions(email, displayName, data && data.temporaryPassword));
    await provisionAuthProfile({ uid: firebaseUser.uid, email, displayName, role: ROLES.ADMIN, shopId, createdBy: actor.uid });
  } catch (error) {
    if (firebaseUser) await auth.deleteUser(firebaseUser.uid).catch(() => {});
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', error.message || 'Unable to provision shop administrator.');
  }
  await recordManagerLog(actor, 'shop.admin_provisioned', { shopId, uid: firebaseUser.uid });
  return { uid: firebaseUser.uid, shopId, role: ROLES.ADMIN, displayName, email };
});

async function provisionExistingUser({ data, context, role }) {
  const actor = await actorFromContext(context);
  const uid = cleanString(data && data.uid, 'uid', 128);
  const displayName = cleanString(data && (data.name || data.displayName), 'name');
  const targetShop = cleanShopId(data && data.shopId ? data.shopId : actor.shopId);
  requireManagerOrAdminInShop(actor, targetShop);
  if (role === ROLES.MANAGER) requireManager(actor);
  const existingAuth = await auth.getUser(uid);
  const existingProfile = await db.collection('users').doc(uid).get();
  if (existingProfile.exists && existingProfile.data().role) {
    throw new functions.https.HttpsError('already-exists', 'User profile already exists.');
  }
  await provisionAuthProfile({
    uid,
    email: existingAuth.email || String((data && data.email) || ''),
    displayName,
    role,
    shopId: targetShop,
    createdBy: actor.uid,
  });
  return { uid, shopId: targetShop, role, name: displayName };
}

exports.provisionShopCashier = functions.https.onCall(
  (data, context) => provisionExistingUser({ data, context, role: ROLES.CASHIER }),
);
exports.provisionCashier = exports.provisionShopCashier;

exports.provisionUser = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  const role = normalizeRole(data && data.role);
  const shopId = role === ROLES.MANAGER ? null : cleanShopId(data && data.shopId);
  requireManagerOrAdminInShop(actor, shopId || actor.shopId || '');
  if (actor.role === ROLES.ADMIN && role !== ROLES.CASHIER) {
    throw new functions.https.HttpsError('permission-denied', 'Shop administrators may provision cashiers only.');
  }
  if (role === ROLES.MANAGER) requireManager(actor);

  const email = cleanString(data && data.email, 'email', 320).toLowerCase();
  const displayName = cleanString(data && data.name, 'name');
  let firebaseUser;
  try {
    firebaseUser = await auth.createUser({ email, password: data.password, displayName, disabled: false });
  } catch (error) {
    throw new functions.https.HttpsError('already-exists', error.message || 'Unable to create auth user.');
  }

  const profile = {
    name: displayName,
    displayName,
    email,
    role,
    shopId,
    active: true,
    createdAt: FieldValue.serverTimestamp(),
    createdBy: actor.uid,
  };
  try {
    await db.collection('users').doc(firebaseUser.uid).set(profile);
    await auth.setCustomUserClaims(firebaseUser.uid, { role, shopId });
    if (actor.role === ROLES.MANAGER) {
      await recordManagerLog(actor, 'user.provisioned', { uid: firebaseUser.uid, role, shopId });
    }
  } catch (error) {
    // Keep Auth and Firestore in sync if profile creation fails.
    await auth.deleteUser(firebaseUser.uid);
    throw new functions.https.HttpsError('internal', 'Unable to provision user profile.');
  }
  return { uid: firebaseUser.uid, ...profile, createdAt: undefined };
});

async function updateUserAccessImpl(data, context) {
  const actor = await actorFromContext(context);
  const uid = cleanString(data && data.uid, 'uid', 128);
  const target = await db.collection('users').doc(uid).get();
  if (!target.exists) throw new functions.https.HttpsError('not-found', 'User profile not found.');
  const targetData = target.data() || {};
  const targetRole = normalizeRole(targetData.role);
  const targetShop = targetData.shopId || null;
  requireManagerOrAdminInShop(actor, targetShop || actor.shopId || '');
  if (actor.role === ROLES.ADMIN && targetRole !== ROLES.CASHIER) {
    throw new functions.https.HttpsError('permission-denied', 'Shop administrators may manage cashiers only.');
  }
  if (targetRole === ROLES.MANAGER) requireManager(actor);
  if (actor.uid === uid && (data.role !== undefined || data.active === false)) {
    throw new functions.https.HttpsError('failed-precondition', 'You cannot change your own role or deactivate your account.');
  }

  const requestedRole = data.role === undefined ? targetRole : normalizeRole(data.role);
  const removesLastActiveAdmin = targetRole === ROLES.ADMIN && targetData.active !== false &&
    (data.active === false || requestedRole !== ROLES.ADMIN);
  if (removesLastActiveAdmin && targetShop) {
    const activeAdmins = await db.collection('users')
      .where('shopId', '==', targetShop)
      .get();
    const activeAdminCount = activeAdmins.docs.filter((doc) => {
      const user = doc.data() || {};
      return normalizeRole(user.role) === ROLES.ADMIN && user.active !== false;
    }).length;
    if (activeAdminCount <= 1) {
      throw new functions.https.HttpsError('failed-precondition', 'The shop must keep one active administrator.');
    }
  }

  const patch = {};
  if (data.name !== undefined) patch.name = cleanString(data.name, 'name');
  if (data.active !== undefined) patch.active = Boolean(data.active);
  if (data.role !== undefined) {
    const nextRole = normalizeRole(data.role);
    if (nextRole === ROLES.MANAGER) requireManager(actor);
    patch.role = nextRole;
    patch.shopId = nextRole === ROLES.MANAGER ? null : cleanShopId(data.shopId || targetShop);
  }
  if (!Object.keys(patch).length) {
    throw new functions.https.HttpsError('invalid-argument', 'No mutable fields supplied.');
  }
  patch.updatedAt = FieldValue.serverTimestamp();
  await db.collection('users').doc(uid).update(patch);
  const claims = { role: patch.role || normalizeRole(targetData.role), shopId: patch.shopId === undefined ? targetShop : patch.shopId };
  await auth.setCustomUserClaims(uid, claims);
  if (actor.role === ROLES.MANAGER) {
    await recordManagerLog(actor, 'user.access_updated', { uid, ...patch });
  }
  return { uid, ...patch, updatedAt: undefined };
}

exports.updateUserAccess = functions.https.onCall(updateUserAccessImpl);

exports.setShopUserRole = functions.https.onCall(async (data, context) => {
  const uid = cleanString(data && data.uid, 'uid', 128);
  const role = normalizeRole(data && data.role);
  return updateUserAccessImpl({ uid, role, shopId: data && data.shopId }, context);
});

exports.setShopUserActive = functions.https.onCall(async (data, context) => {
  const uid = cleanString(data && data.uid, 'uid', 128);
  const active = Boolean(data && data.active);
  return updateUserAccessImpl({ uid, active }, context);
});

exports.bootstrapFirstManager = functions.https.onCall(async (data, context) => {
  // The first manager cannot be authorized from Firestore because no profile
  // exists yet. An operator must set BOOTSTRAP_MANAGER_UID at deploy time;
  // this endpoint then permits exactly that Auth UID once, while no manager
  // profile exists. Existing shop users do not prevent a safe first-manager
  // bootstrap. It never trusts role or shopId supplied by the client.
  if (!context.auth || !process.env.BOOTSTRAP_MANAGER_UID || context.auth.uid !== process.env.BOOTSTRAP_MANAGER_UID) {
    throw new functions.https.HttpsError('permission-denied', 'Bootstrap manager authorization is not configured.');
  }
  const managers = await db.collection('users')
    .where('role', 'in', [ROLES.MANAGER, 'admin_manager', 'MANAGER', 'manager', 'SUPER', 'super'])
    .limit(1)
    .get();
  const profileRef = db.collection('users').doc(context.auth.uid);
  if (!managers.empty || (await profileRef.get()).exists) {
    throw new functions.https.HttpsError('failed-precondition', 'A manager already exists or this account is already provisioned.');
  }
  const authUser = await auth.getUser(context.auth.uid);
  const displayName = cleanString((data && (data.name || data.displayName)) || authUser.displayName || authUser.email, 'name');
  await provisionAuthProfile({ uid: context.auth.uid, email: authUser.email || '', displayName, role: ROLES.MANAGER, shopId: null, createdBy: 'bootstrap' });
  return { uid: context.auth.uid, role: ROLES.MANAGER, shopId: null };
});

exports.setShopSubscription = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  requireManager(actor);
  const shopId = cleanShopId(data && data.shopId);
  const plan = cleanString(data && data.plan, 'plan', 64).toUpperCase();
  const status = cleanString(data && data.status, 'status', 32).toLowerCase();
  const subscription = {
    shopId,
    plan,
    status,
    seats: Number.isInteger(data.seats) && data.seats > 0 ? data.seats : 1,
    updatedBy: actor.uid,
    updatedAt: FieldValue.serverTimestamp(),
  };
  await db.collection('subscriptions').doc(shopId).set(subscription, { merge: true });
  await db.collection('shops').doc(shopId).set({ subscription: { plan, status, seats: subscription.seats }, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  await recordManagerLog(actor, 'subscription.updated', { shopId, plan, status, seats: subscription.seats });
  return { shopId, plan, status, seats: subscription.seats };
});

exports.getPlatformAggregate = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  requireManager(actor);
  const shopId = data && data.shopId ? cleanShopId(data.shopId) : null;
  const collections = ['shops', 'users', 'products', 'sales', 'purchases', 'customers'];
  const snapshots = await Promise.all(collections.map((name) => {
    let query = db.collection(name);
    if (shopId && !['shops', 'users'].includes(name)) query = query.where('shopId', '==', shopId);
    if (shopId && name === 'users') query = query.where('shopId', '==', shopId);
    return query.get();
  }));
  const [shops, users, products, sales, purchases, customers] = snapshots;
  const totalSales = sales.docs.reduce((sum, doc) => sum + Number((doc.data() || {}).total || 0), 0);
  const totalPurchases = purchases.docs.reduce((sum, doc) => sum + Number((doc.data() || {}).totalCost || 0), 0);
  return {
    shopId,
    shops: shops.size,
    users: users.size,
    products: products.size,
    sales: sales.size,
    purchases: purchases.size,
    customers: customers.size,
    totalSales,
    totalPurchases,
    generatedAt: Timestamp.now().toDate().toISOString(),
  };
});

exports.getPlatformDashboard = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  requireManager(actor);
  const from = timestampFromInput(data && data.from);
  const to = timestampFromInput(data && data.to);
  const [shopsSnapshot, usersSnapshot, productsSnapshot, salesSnapshot] = await Promise.all([
    db.collection('shops').get(),
    db.collection('users').get(),
    db.collection('products').get(),
    db.collection('sales').get(),
  ]);
  const shops = shopsSnapshot.docs.map((doc) => doc.data() || {});
  const users = usersSnapshot.docs.map((doc) => doc.data() || {});
  const products = productsSnapshot.docs.map((doc) => doc.data() || {});
  const sales = salesSnapshot.docs.map((doc) => doc.data() || {}).filter((sale) => {
    const date = timestampFromInput(sale.createdAt);
    return (!from || (date && date >= from)) && (!to || (date && date <= to));
  });
  const normalizedRole = (role) => String(role || '').toUpperCase();
  const revenueSeries = new Map();
  for (const sale of sales) {
    const date = timestampFromInput(sale.createdAt);
    if (!date) continue;
    const label = date.toISOString().slice(0, 10);
    revenueSeries.set(label, (revenueSeries.get(label) || 0) + Number(sale.total || 0));
  }
  return {
    shops: shops.length,
    activeShops: shops.filter((shop) => String(shop.status || 'active').toLowerCase() === 'active').length,
    admins: users.filter((user) => normalizedRole(user.role) === ROLES.ADMIN).length,
    cashiers: users.filter((user) => normalizedRole(user.role) === ROLES.CASHIER).length,
    products: products.length,
    lowStock: products.filter((product) => Number(product.stockQty || 0) <= Number(product.lowStockThreshold || 0)).length,
    revenue: sales.reduce((sum, sale) => sum + Number(sale.total || 0), 0),
    orders: sales.length,
    revenueSeries: [...revenueSeries.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([label, value]) => ({ label, value })),
  };
});

exports.createShopLocation = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  requireManager(actor);
  const shopId = cleanShopId(data && data.shopId);
  const shop = await db.collection('shops').doc(shopId).get();
  if (!shop.exists) throw new functions.https.HttpsError('not-found', 'Shop not found.');
  const ref = db.collection('locations').doc();
  const location = {
    shopId,
    name: cleanString(data && data.name, 'name'),
    address: String((data && data.address) || '').trim(),
    phone: String((data && data.phone) || '').trim(),
    active: true,
    createdBy: actor.uid,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
  await ref.set(location);
  await recordManagerLog(actor, 'location.created', { shopId, locationId: ref.id });
  return { locationId: ref.id, ...location, createdAt: undefined, updatedAt: undefined };
});

exports.updateShopLocation = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  requireManager(actor);
  const locationId = cleanString(data && data.locationId, 'locationId', 128);
  const ref = db.collection('locations').doc(locationId);
  const existing = await ref.get();
  if (!existing.exists) throw new functions.https.HttpsError('not-found', 'Location not found.');
  const patch = {
    name: cleanString(data && data.name, 'name'),
    address: String((data && data.address) || '').trim(),
    phone: String((data && data.phone) || '').trim(),
    active: data && data.active !== undefined ? Boolean(data.active) : true,
    updatedAt: FieldValue.serverTimestamp(),
  };
  await ref.update(patch);
  await recordManagerLog(actor, 'location.updated', { locationId });
  return { locationId, ...patch, updatedAt: undefined };
});

exports.deleteShopLocation = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  requireManager(actor);
  const locationId = cleanString(data && data.locationId, 'locationId', 128);
  await db.collection('locations').doc(locationId).delete();
  await recordManagerLog(actor, 'location.deleted', { locationId });
  return { locationId, deleted: true };
});

exports.updatePlatformSettings = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  requireManager(actor);
  const settings = data && data.settings && typeof data.settings === 'object' ? data.settings : {};
  const safeSettings = {
    maintenanceMessage: String(settings.maintenanceMessage || '').trim().slice(0, 1000),
    posEnabled: settings.posEnabled !== false,
    updatedBy: actor.uid,
    updatedAt: FieldValue.serverTimestamp(),
  };
  await db.collection('platformSettings').doc('global').set(safeSettings, { merge: true });
  await recordManagerLog(actor, 'platform.settings_updated');
  return { ...safeSettings, updatedAt: undefined };
});

exports.resolvePlatformAlert = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  requireManager(actor);
  const alertId = cleanString(data && data.alertId, 'alertId', 128);
  await db.collection('platformAlerts').doc(alertId).set({ resolved: true, resolvedBy: actor.uid, resolvedAt: FieldValue.serverTimestamp() }, { merge: true });
  await recordManagerLog(actor, 'platform.alert_resolved', { alertId });
  return { alertId, resolved: true };
});

exports.setShopPosAccess = functions.https.onCall(async (data, context) => {
  const actor = await actorFromContext(context);
  requireManager(actor);
  const shopId = cleanShopId(data && data.shopId);
  const enabled = Boolean(data && data.enabled);
  const shop = await db.collection('shops').doc(shopId).get();
  if (!shop.exists) throw new functions.https.HttpsError('not-found', 'Shop not found.');
  await db.collection('shops').doc(shopId).set({ posAccessEnabled: enabled, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  await recordManagerLog(actor, 'shop.pos_access_updated', { shopId, enabled });
  return { shopId, enabled };
});

