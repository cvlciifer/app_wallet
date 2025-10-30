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
    // 400: falta token en la petición
    return res.status(400).json({
      success: false,
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
  if (!doc.exists) return res.status(404).json({ success: false, reason: 'not_found', message: process.env.NODE_ENV === 'production' ? 'Token no encontrado.' : 'Token no encontrado en Firestore.' });
      data = doc.data();
  if (!data) return res.status(404).json({ success: false, reason: 'not_found', message: process.env.NODE_ENV === 'production' ? 'Token no encontrado.' : 'Token no encontrado en Firestore.' });
      await docRef.delete();
      return res.json({ success: true, email: data.email });
    } else if (inMemory) {
      // En desarrollo con almacenamiento en memoria
      data = inMemory.get(tokenHash) || null;
  if (!data) return res.status(404).json({ success: false, reason: 'not_found', message: process.env.NODE_ENV === 'production' ? 'Token no encontrado.' : 'Token no encontrado en almacenamiento en memoria.' });
  inMemory.delete(tokenHash);
  return res.json({ success: true, email: data.email });
    } else {
      // No hay almacén disponible
      return res.status(500).json({ success: false, reason: 'no_store' });
    }
  } catch (e) {
    if (process.env.NODE_ENV === 'production') {
      console.error('consume-reset error (producción)');
    } else {
      console.error('consume-reset error', e && e.stack ? e.stack : e);
    }
    return res.status(500).json({
      success: false,
      reason: 'internal',
      message: process.env.NODE_ENV === 'production' ? 'Error interno del servidor.' : `Error interno: ${e && e.message ? e.message : String(e)}`
    });
  }
};
