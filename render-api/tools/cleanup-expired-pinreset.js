const admin = require('firebase-admin');
const { argv } = require('process');

async function main() {
  if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    console.error('FIREBASE_SERVICE_ACCOUNT not set. Exiting.');
    process.exit(1);
  }

  const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  admin.initializeApp({ credential: admin.credential.cert(sa) });
  const db = admin.firestore();

  const dryRun = argv.includes('--dry-run') || argv.includes('-n');
  const limit = 500;
  console.log('Scanning Registros for expired pinReset... (dryRun=' + dryRun + ')');

  const now = Date.now();
  const snapshot = await db.collection('Registros').get();
  let count = 0;
  const toDelete = [];

  snapshot.forEach(doc => {
    const data = doc.data() || {};
    const pr = data.pinReset;
    if (!pr || !pr.expiresAt) return;
    const expiresMillis = typeof pr.expiresAt === 'object' && pr.expiresAt.toMillis ? pr.expiresAt.toMillis() : pr.expiresAt;
    if (expiresMillis && expiresMillis < now) {
      toDelete.push(doc.ref);
    }
  });

  console.log('Found', toDelete.length, 'expired pinReset entries');
  if (dryRun) return;

  // Delete in batches
  const batches = [];
  while (toDelete.length) {
    const batchRefs = toDelete.splice(0, limit);
    const batch = db.batch();
    batchRefs.forEach(ref => batch.update(ref, { pinReset: admin.firestore.FieldValue.delete() }));
    batches.push(batch.commit());
  }

  await Promise.all(batches);
  console.log('Deleted expired pinReset fields');
}

main().catch(e => {
  console.error('cleanup error', e);
  process.exit(1);
});
