#!/usr/bin/env node

/**
 * Plan/apply the one-time migration from the legacy unscoped Firestore shape.
 *
 * Safe default: this script only prints a deterministic plan. Applying it
 * requires both --apply and ALLOW_LIVE_MIGRATION=1. It is intentionally not
 * executed by Firebase deploys or CI.
 */

let firebaseAdminApp;
let firebaseAdminFirestore;
try {
  firebaseAdminApp = require('firebase-admin/app');
  firebaseAdminFirestore = require('firebase-admin/firestore');
} catch (_) {
  // The migration is run from the repository root after `npm install` in
  // functions/. Keep the script independent from a root package.json.
  const { createRequire } = require('node:module');
  const path = require('node:path');
  const functionsRequire = createRequire(path.join(__dirname, '../functions/package.json'));
  firebaseAdminApp = functionsRequire('firebase-admin/app');
  firebaseAdminFirestore = functionsRequire('firebase-admin/firestore');
}
const { initializeApp, getApps } = firebaseAdminApp;
const { getFirestore, FieldValue } = firebaseAdminFirestore;

const DEFAULT_SHOP_ID = 'default-shop';
const SHOP_NAME = 'Default Shop';
const SCOPED_COLLECTIONS = [
  'categories',
  'products',
  'productCodes',
  'customers',
  'sales',
  'heldBills',
  'stockMovements',
  'daily_closes',
  'counters',
  'suppliers',
  'purchases',
  'auditLogs',
  'locations',
  'reports',
  'alerts',
  'notificationLogs',
  'settings',
  'attendance',
  'invoices',
  'notifications',
  'shopSettings',
];

function productCodeDocumentId(shopId, code) {
  return `${shopId}__${encodeURIComponent(String(code).trim().toUpperCase())}`;
}

function normalizeRole(value) {
  const role = String(value || '').trim().toUpperCase();
  if (role === 'MANAGER' || role === 'SUPER' || role === 'ADMIN_MANAGER') return 'ADMIN_MANAGER';
  if (role === 'ADMIN') return 'ADMIN';
  if (role === 'CASHIER') return 'CASHIER';
  return role || 'CASHIER';
}

function isApplyMode() {
  return process.argv.includes('--apply') && process.env.ALLOW_LIVE_MIGRATION === '1';
}

function getDb() {
  if (!getApps().length) initializeApp();
  return getFirestore();
}

async function buildPlan(db) {
  const operations = [];
  const defaultShopRef = db.collection('shops').doc(DEFAULT_SHOP_ID);
  const defaultShop = await defaultShopRef.get();
  if (!defaultShop.exists) {
    operations.push({ type: 'create', path: `shops/${DEFAULT_SHOP_ID}`, data: { name: SHOP_NAME, status: 'active', migrationKey: DEFAULT_SHOP_ID } });
  }

  const users = await db.collection('users').get();
  for (const doc of users.docs) {
    const data = doc.data() || {};
    const role = normalizeRole(data.role);
    const patch = {};
    if (data.role !== role) patch.role = role;
    if (role === 'ADMIN_MANAGER') {
      if (data.shopId !== null) patch.shopId = null;
    } else if (!data.shopId) {
      patch.shopId = DEFAULT_SHOP_ID;
    }
    if (Object.keys(patch).length) operations.push({ type: 'update', path: `users/${doc.id}`, data: patch });
  }

  for (const collection of SCOPED_COLLECTIONS) {
    const snapshot = await db.collection(collection).get();
    for (const doc of snapshot.docs) {
      const data = doc.data() || {};
      const shopId = data.shopId || DEFAULT_SHOP_ID;
      if (collection === 'productCodes') {
        if (!doc.id.startsWith(`${shopId}__`)) {
          const nextId = productCodeDocumentId(shopId, doc.id);
          const nextRef = db.collection(collection).doc(nextId);
          const existing = await nextRef.get();
          if (existing.exists) {
            throw new Error(`Product code migration collision at ${collection}/${nextId}`);
          }
          operations.push({
            type: 'move',
            fromPath: `${collection}/${doc.id}`,
            path: `${collection}/${nextId}`,
            data: { ...data, code: data.code || doc.id, shopId },
          });
          continue;
        }
      }
      if (!data.shopId) operations.push({ type: 'update', path: `${collection}/${doc.id}`, data: { shopId: DEFAULT_SHOP_ID } });
    }
  }
  return operations;
}

async function applyPlan(db, operations) {
  let batch = db.batch();
  let writeCount = 0;
  for (const operation of operations) {
    const [collection, id] = operation.path.split('/');
    const ref = db.collection(collection).doc(id);
    if (operation.type === 'create') batch.create(ref, { ...operation.data, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
    else if (operation.type === 'move') {
      batch.create(ref, { ...operation.data, updatedAt: FieldValue.serverTimestamp() });
      const [fromCollection, fromId] = operation.fromPath.split('/');
      batch.delete(db.collection(fromCollection).doc(fromId));
    }
    else batch.set(ref, { ...operation.data, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    writeCount += operation.type === 'move' ? 2 : 1;
    if (writeCount >= 400) {
      await batch.commit();
      batch = db.batch();
      writeCount = 0;
    }
  }
  if (writeCount) await batch.commit();
}

async function countMigratedRecords(db) {
  const names = ['shops', 'users', ...SCOPED_COLLECTIONS];
  const entries = await Promise.all(names.map(async (name) => {
    const snapshot = await db.collection(name).count().get();
    return [name, snapshot.data().count];
  }));
  return Object.fromEntries(entries);
}

async function main() {
  const db = getDb();
  const countsBefore = await countMigratedRecords(db);
  const operations = await buildPlan(db);
  console.log(JSON.stringify({ mode: isApplyMode() ? 'apply' : 'dry-run', defaultShopId: DEFAULT_SHOP_ID, countsBefore, operationCount: operations.length, operations }, null, 2));
  if (!isApplyMode()) {
    console.log('Dry-run only. Re-run with --apply and ALLOW_LIVE_MIGRATION=1 to write changes.');
    return;
  }
  await applyPlan(db, operations);
  const [countsAfter, remainingOperations] = await Promise.all([
    countMigratedRecords(db),
    buildPlan(db),
  ]);
  const expectedCounts = { ...countsBefore };
  if (operations.some((operation) => operation.type === 'create' && operation.path === `shops/${DEFAULT_SHOP_ID}`)) {
    expectedCounts.shops += 1;
  }
  const countsMatch = JSON.stringify(expectedCounts) === JSON.stringify(countsAfter);
  if (!countsMatch || remainingOperations.length) {
    throw new Error(`Migration verification failed: countMatch=${countsMatch}, remainingOperations=${remainingOperations.length}`);
  }
  console.log(JSON.stringify({ applied: operations.length, countsAfter, verified: true }, null, 2));
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

module.exports = { buildPlan, applyPlan, countMigratedRecords, DEFAULT_SHOP_ID, productCodeDocumentId };

