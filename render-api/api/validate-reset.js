const crypto = require('crypto');
const admin = require('firebase-admin');

function initAdmin() {
  if (admin.apps && admin.apps.length) return admin;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({ credential: admin.credential.cert(sa) });
  } else {
    try { admin.initializeApp(); } catch (e) {}
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
      valid: false,
      reason: 'missing_token',
      message:
        process.env.NODE_ENV === 'production'
          ? 'Falta el token.'
          : 'Falta el parámetro "token" en la query o body.'
    });
  }

  const adminSdk = initAdmin();
  const useFirestore = !!process.env.FIREBASE_SERVICE_ACCOUNT;
  const db = useFirestore ? adminSdk.firestore() : null;
  const inMemory = require('./request-reset').IN_MEMORY_STORE || null;

  try {
    const tokenHash = hashToken(token);
    let data = null;

    if (useFirestore && db) {
      const userQuery = await db
        .collection('Registros')
        .where('pinReset.tokenHash', '==', tokenHash)
        .limit(1)
        .get();

      if (userQuery.empty) {
        return res.status(404).json({
          valid: false,
          reason: 'not_found',
          message:
            process.env.NODE_ENV === 'production'
              ? 'Token no encontrado.'
              : `Token no encontrado en Firestore (hash: ${tokenHash})`
        });
      }

      const userDoc = userQuery.docs[0];
      data = userDoc.data().pinReset || {};
    } else if (inMemory) {
      data = inMemory.get(tokenHash) || null;
      if (!data) {
        return res.status(404).json({
          valid: false,
          reason: 'not_found',
          message:
            process.env.NODE_ENV === 'production'
              ? 'Token no encontrado.'
              : 'Token no encontrado en almacenamiento en memoria.'
        });
      }
    } else {
      return res.status(500).json({ valid: false, reason: 'no_store' });
    }

    if (!data) {
      return res.status(404).json({ valid: false, reason: 'not_found' });
    }

    let expiresAtMs = 0;
    if (data.expiresAt) {
      if (typeof data.expiresAt === 'object' && data.expiresAt.toMillis) {
        expiresAtMs = data.expiresAt.toMillis();
      } else {
        expiresAtMs = Number(data.expiresAt);
      }
    }

    if (Date.now() > expiresAtMs) {
      try {
        if (useFirestore && db) {
          const expiredQuery = await db
            .collection('Registros')
            .where('pinReset.tokenHash', '==', tokenHash)
            .limit(1)
            .get();

          if (!expiredQuery.empty) {
            const userRef = expiredQuery.docs[0].ref;
            await userRef.update({
              pinReset: adminSdk.firestore.FieldValue.delete(),
            });
          }
        } else if (inMemory) {
          inMemory.delete(tokenHash);
        }
      } catch (e) {
        console.error('Error eliminando token expirado', e);
      }

      return res.status(410).json({
        valid: false,
        reason: 'expired',
        message:
          process.env.NODE_ENV === 'production'
            ? 'Token expirado.'
            : 'El token ha expirado y fue eliminado.',
      });
    }

    return res.json({
      valid: true,
      email: data.email,
    });
  } catch (e) {
    console.error('validate-reset error', e && e.stack ? e.stack : e);
    return res.status(500).json({
      valid: false,
      reason: 'internal',
      message:
        process.env.NODE_ENV === 'production'
          ? 'Error interno del servidor.'
          : `Error interno: ${e && e.message ? e.message : String(e)}`
    });
  }
};
