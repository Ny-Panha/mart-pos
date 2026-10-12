const { after, before, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, Timestamp, writeBatch } = require('firebase/firestore');
const fs = require('node:fs');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore: getAdminFirestore } = require('firebase-admin/firestore');
const { applyPlan, buildPlan, countMigratedRecords, DEFAULT_SHOP_ID } = require('../../scripts/migrate-default-shop');

const PROJECT_ID = 'demo-mart-pos';
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: fs.readFileSync('../firestore.rules', 'utf8') },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const seed = {
      'users/manager': { role: 'ADMIN_MANAGER', active: true },
      'users/admin-a': { role: 'ADMIN', shopId: 'shop-a', active: true },
      'users/cashier-a': { role: 'CASHIER', shopId: 'shop-a', active: true },
      'users/cashier-b': { role: 'CASHIER', shopId: 'shop-a', active: true },
      'users/admin-b': { role: 'ADMIN', shopId: 'shop-b', active: true },
      'shops/shop-a': { name: 'Shop A' },
      'shops/shop-b': { name: 'Shop B' },
      'products/product-a': { shopId: 'shop-a', name: 'A product', stockQty: 10 },
      'products/product-b': { shopId: 'shop-b', name: 'B product', stockQty: 10 },
      'sales/sale-a': { shopId: 'shop-a', cashierId: 'cashier-a', total: 12 },
      'sales/sale-b': { shopId: 'shop-a', cashierId: 'cashier-b', total: 6 },
      'daily_closes/shift-a': { shopId: 'shop-a', cashierId: 'cashier-a' },
      'daily_closes/shift-b': { shopId: 'shop-a', cashierId: 'cashier-b' },
      'purchases/purchase-a': { shopId: 'shop-a', totalCost: 5 },
      'managerLogs/log-a': { action: 'shop.created' },
    };
    await Promise.all(Object.entries(seed).map(([path, data]) => setDoc(doc(db, path), data)));
  });
});

test('manager can read platform data and cross-shop sales', async () => {
  const db = testEnv.authenticatedContext('manager').firestore();
  await assertSucceeds(getDoc(doc(db, 'shops/shop-b')));
  await assertSucceeds(getDoc(doc(db, 'sales/sale-b')));
  await assertSucceeds(getDoc(doc(db, 'managerLogs/log-a')));
  await assertFails(setDoc(doc(db, 'managerLogs/client-write'), { action: 'forged' }));
});

test('admin reads only its shop and cannot mutate platform records', async () => {
  const db = testEnv.authenticatedContext('admin-a').firestore();
  await assertSucceeds(getDoc(doc(db, 'products/product-a')));
  await assertFails(getDoc(doc(db, 'products/product-b')));
  await assertSucceeds(getDoc(doc(db, 'sales/sale-b')));
  await assertFails(setDoc(doc(db, 'shops/shop-a'), { name: 'Changed' }));
  await assertFails(getDoc(doc(db, 'managerLogs/log-a')));
});

test('cashier is limited to own-shop POS records and personal history', async () => {
  const db = testEnv.authenticatedContext('cashier-a').firestore();
  await assertSucceeds(getDoc(doc(db, 'products/product-a')));
  await assertSucceeds(getDoc(doc(db, 'sales/sale-a')));
  await assertFails(getDoc(doc(db, 'sales/sale-b')));
  await assertSucceeds(getDoc(doc(db, 'daily_closes/shift-a')));
  await assertFails(getDoc(doc(db, 'daily_closes/shift-b')));
  await assertFails(getDoc(doc(db, 'purchases/purchase-a')));
  await assertFails(getDoc(doc(db, 'users/admin-a')));
  await assertFails(setDoc(doc(db, 'products/new-product'), { shopId: 'shop-a' }));
  await assertSucceeds(setDoc(doc(db, 'sales/new-sale'), {
    shopId: 'shop-a', cashierId: 'cashier-a', total: 9,
  }));
  await assertFails(setDoc(doc(db, 'sales/forged-sale'), {
    shopId: 'shop-a', cashierId: 'cashier-b', total: 9,
  }));
  await assertSucceeds(setDoc(doc(db, 'counters/shop-a_invoices'), {
    shopId: 'shop-a', seq: 1,
  }));
  await assertSucceeds(updateDoc(doc(db, 'counters/shop-a_invoices'), { seq: 2 }));
  await assertFails(updateDoc(doc(db, 'counters/shop-a_invoices'), { seq: 4 }));

  const batch = writeBatch(db);
  batch.set(doc(db, 'sales/checkout-sale'), {
    shopId: 'shop-a', cashierId: 'cashier-a', total: 4,
  });
  batch.update(doc(db, 'products/product-a'), {
    stockQty: 9,
    updatedAt: Timestamp.now(),
  });
  batch.set(doc(db, 'stockMovements/checkout-movement'), {
    shopId: 'shop-a', type: 'out', createdBy: 'cashier-a',
    productId: 'product-a', qty: 1, refId: 'checkout-sale',
  });
  await assertSucceeds(batch.commit());
});

test('default-shop migration preserves counts and is repeatable', async () => {
  process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
  const app = initializeApp({ projectId: PROJECT_ID }, 'migration-test');
  const db = getAdminFirestore(app);
  await Promise.all([
    db.collection('users').doc('legacy-admin').set({
      name: 'Legacy Admin', role: 'admin', active: true,
    }),
    db.collection('users').doc('legacy-manager').set({
      name: 'Legacy Manager', role: 'super', active: true,
    }),
    db.collection('products').doc('legacy-product').set({
      name: 'Legacy product', stockQty: 4,
    }),
    db.collection('productCodes').doc('LEGACY-CODE').set({
      productId: 'legacy-product',
    }),
  ]);

  const countsBefore = await countMigratedRecords(db);
  const plan = await buildPlan(db);
  await applyPlan(db, plan);

  const remaining = await buildPlan(db);
  const countsAfter = await countMigratedRecords(db);
  const expectedCounts = { ...countsBefore, shops: countsBefore.shops + 1 };
  const migratedUser = await db.collection('users').doc('legacy-admin').get();
  const migratedManager = await db.collection('users').doc('legacy-manager').get();
  const migratedProduct = await db.collection('products').doc('legacy-product').get();
  const migratedCode = await db.collection('productCodes').doc('default-shop__LEGACY-CODE').get();
  const legacyCode = await db.collection('productCodes').doc('LEGACY-CODE').get();
  const migrationShop = await db.collection('shops').doc(DEFAULT_SHOP_ID).get();

  assert.deepEqual(remaining, []);
  assert.deepEqual(countsAfter, expectedCounts);
  assert.equal(migratedUser.data().role, 'ADMIN');
  assert.equal(migratedUser.data().shopId, DEFAULT_SHOP_ID);
  assert.equal(migratedManager.data().role, 'ADMIN_MANAGER');
  assert.equal(migratedManager.data().shopId, null);
  assert.equal(migratedProduct.data().shopId, DEFAULT_SHOP_ID);
  assert.equal(migratedCode.data().shopId, DEFAULT_SHOP_ID);
  assert.equal(legacyCode.exists, false);
  assert.equal(migrationShop.exists, true);
  await app.delete();
});
