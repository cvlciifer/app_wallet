const crypto = require('crypto');
const admin = require('firebase-admin');

function initAdmin() {
  if (admin.apps && admin.apps.length) return admin;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({ credential: admin.credential.cert(sa) });
  } else {
    try { admin.initializeApp(); } catch(e) {}
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
    // 400: falta el token en la petición
    return res.status(400).json({
      valid: false,
      reason: 'missing_token',
      message: process.env.NODE_ENV === 'production' ? 'Falta el token.' : 'Falta el parámetro "token" en la query o body.'
    });
  }

  const adminSdk = initAdmin();
  const useFirestore = !!process.env.FIREBASE_SERVICE_ACCOUNT;
  const db = useFirestore ? adminSdk.firestore() : null;
  // fallback en memoria (compartido a través del require cache)
  const inMemory = require('./request-reset').IN_MEMORY_STORE || null;

  try {
    const tokenHash = hashToken(token);
    let data = null;
    if (useFirestore && db) {
      const docRef = db.collection('pin_reset_tokens').doc(tokenHash);
      const doc = await docRef.get();
  if (!doc.exists) return res.status(404).json({ valid: false, reason: 'not_found', message: process.env.NODE_ENV === 'production' ? 'Token no encontrado.' : 'Token no encontrado en Firestore (hash: ' + tokenHash + ')'});
      data = doc.data();
    } else if (inMemory) {
      // Si estamos en modo desarrollo con almacenamiento en memoria
  data = inMemory.get(tokenHash) || null;
  if (!data) return res.status(404).json({ valid: false, reason: 'not_found', message: process.env.NODE_ENV === 'production' ? 'Token no encontrado.' : 'Token no encontrado en almacenamiento en memoria.' });
    } else {
      // No hay almacenamiento disponible (ni Firestore ni memoria)
      return res.status(500).json({ valid: false, reason: 'no_store' });
    }
    if (!data) return res.status(404).json({ valid: false, reason: 'not_found' });
    const expiresAt = data.expiresAt || 0;
    if (Date.now() > Number(expiresAt)) {
      try { if (useFirestore && db) { await db.collection('pin_reset_tokens').doc(tokenHash).delete(); } else if (inMemory) { inMemory.delete(tokenHash); } } catch(e){}
      return res.status(410).json({ valid: false, reason: 'expired', message: process.env.NODE_ENV === 'production' ? 'Token expirado.' : 'El token ha expirado y fue eliminado.' });
    }
    return res.json({ valid: true, email: data.email });
  } catch (e) {
    // En producción logueamos un mensaje genérico; en dev incluimos stack para depuración.
    if (process.env.NODE_ENV === 'production') {
      console.error('validate-reset error (producción)');
    } else {
      console.error('validate-reset error', e && e.stack ? e.stack : e);
    }
    return res.status(500).json({
      valid: false,
      reason: 'internal',
      message: process.env.NODE_ENV === 'production' ? 'Error interno del servidor.' : `Error interno: ${e && e.message ? e.message : String(e)}`
    });
  }
};
