const crypto = require('crypto');
const admin = require('firebase-admin');

function initAdmin() {
  if (admin.apps && admin.apps.length) return admin;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({ credential: admin.credential.cert(sa) });
  } else {
    try { admin.initializeApp(); } catch(e){}
  }
  return admin;
}

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const body = req.method === 'GET' ? req.query : req.body || {};
  const token = body.token;
  if (!token) {
    return res.status(400).json({
      success: false,
      reason: 'missing_token',
      message: process.env.NODE_ENV === 'production'
        ? 'Falta el token.'
        : 'Falta el parámetro "token" en la query o body.'
    });
  }

  const adminSdk = initAdmin();
  const useFirestore = !!process.env.FIREBASE_SERVICE_ACCOUNT;
  const db = useFirestore ? adminSdk.firestore() : null;
  const inMemory = require('./request-reset').IN_MEMORY_STORE || null;

    const isProd = process.env.NODE_ENV === 'production';
    const hasAdminCreds = !!process.env.FIREBASE_SERVICE_ACCOUNT;

    if (isProd && !hasAdminCreds) {
      console.error(JSON.stringify({ event: 'consume-reset', level: 'error', message: 'Missing FIREBASE_SERVICE_ACCOUNT in production' }));
      return res.status(500).json({ success: false, reason: 'server_misconfigured', message: 'Server not configured' });
    }

    function maskEmail(email) {
      if (!email) return '';
      const parts = email.split('@');
      if (parts.length !== 2) return email;
      const name = parts[0];
      const domain = parts[1];
      const visible = name.length > 2 ? 2 : 1;
      return name.slice(0, visible) + Array(Math.max(0, name.length - visible)).fill('*').join('') + '@' + domain;
    }

  try {
  const tokenHash = hashToken(token);
  console.info(JSON.stringify({ event: 'consume-reset-attempt', level: 'info', tokenHash }));

    if (useFirestore && db) {
      const userQuery = await db.collection('Registros')
        .where('pinReset.tokenHash', '==', tokenHash)
        .limit(1)
        .get();

      if (userQuery.empty) {
        return res.status(404).json({
          success: false,
          reason: 'not_found',
          message: 'Token no encontrado.'
        });
      }

      const userRef = userQuery.docs[0].ref;

      // Transaction: re-read, validate token hash + expiry, then delete pinReset atomically
      let email;
      try {
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(userRef);
          if (!snap.exists) throw new Error('Usuario no encontrado');
          const data = snap.data() || {};
          const pr = data.pinReset;
          if (!pr || pr.tokenHash !== tokenHash) throw new Error('Token inválido');

          // supports both Firestore Timestamp and millis (in-memory/dev)
          const expiresAt = pr.expiresAt;
          const nowMillis = Date.now();
          const expiresMillis = typeof expiresAt === 'object' && expiresAt.toMillis ? expiresAt.toMillis() : expiresAt;
          if (!expiresMillis || expiresMillis < nowMillis) {
            const err = new Error('expired');
            err.code = 'EXPIRED';
            throw err;
          }

          email = data.email;
          tx.update(userRef, { pinReset: adminSdk.firestore.FieldValue.delete() });
        });
      } catch (err) {
        if (err && err.code === 'EXPIRED') {
          return res.status(400).json({ success: false, reason: 'expired', message: 'Token expirado.' });
        }
        return res.status(400).json({ success: false, reason: 'invalid', message: err.message || 'Token inválido.' });
      }

      try {
        const userRecord = await adminSdk.auth().getUserByEmail(email);
        const customToken = await adminSdk.auth().createCustomToken(userRecord.uid);
        return res.json({ success: true, email, customToken });
      } catch (e) {
        console.warn('consume-reset: user not found or token creation failed', e.message || e);
        return res.json({ success: true, email });
      }

    } else if (inMemory) {
      const data = inMemory.get(tokenHash) || null;
      if (!data) return res.status(404).json({ success: false, reason: 'not_found', message: 'Token no encontrado en almacenamiento en memoria.' });
      // check expiry stored as millis in in-memory store
      const now = Date.now();
      if (!data.expiresAt || data.expiresAt < now) {
        inMemory.delete(tokenHash);
        return res.status(400).json({ success: false, reason: 'expired', message: 'Token expirado.' });
      }
      inMemory.delete(tokenHash);

      const email = data.email;
      try {
        const userRecord = await adminSdk.auth().getUserByEmail(email);
        const customToken = await adminSdk.auth().createCustomToken(userRecord.uid);
        return res.json({ success: true, email, customToken });
      } catch (e) {
        console.warn('consume-reset (inMemory): user not found or token creation failed', e.message || e);
        return res.json({ success: true, email });
      }
    } else {
      return res.status(500).json({ success: false, reason: 'no_store' });
    }

  } catch (e) {
    console.error('consume-reset error', e.stack || e);
    return res.status(500).json({
      success: false,
      reason: 'internal',
      message: process.env.NODE_ENV === 'production'
        ? 'Error interno del servidor.'
        : `Error interno: ${e.message || e}`
    });
  }
};