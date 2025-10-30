const crypto = require('crypto');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Auxiliar: inicializa firebase-admin una sola vez
// En desarrollo local, si NO se proporciona FIREBASE_SERVICE_ACCOUNT, usamos un almacenamiento en memoria como respaldo
const IN_MEMORY_STORE = new Map(); // tokenHash -> { email, expiresAt }

function initAdmin() {
  if (admin.apps && admin.apps.length) return admin;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount = sa) });
  } else {
    // initialize default if running in GCP (not necessary on Vercel)
    try { admin.initializeApp(); } catch (e) {}
  }
  return admin;
}

function makeToken() {
  return crypto.randomBytes(32).toString('hex');
}

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

async function sendEmailSMTP(toEmail, resetLink) {
  // Si faltan variables SMTP, lanzar error (se captura y actúa en el caller).
  // En producción no se devolverá el stack al cliente; los logs quedan en el servidor.
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER) throw new Error('SMTP no configurado (variables SMTP_HOST/SMTP_USER faltantes)');
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT) || 587,
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });
  const mailOptions = {
    from: process.env.SMTP_FROM,
    to: toEmail,
    subject: 'Recupera tu PIN',
    html: `<p>Haz clic en el siguiente enlace para reconfigurar tu PIN (expira en 20 minutos):</p><p><a href="${resetLink}">${resetLink}</a></p>`,
  };
  await transporter.sendMail(mailOptions);
}

async function sendEmailEmailJS(toEmail, resetLink) {
  // Comprueba que las variables de EmailJS estén presentes.
  if (!process.env.EMAILJS_SERVICE_ID || !process.env.EMAILJS_TEMPLATE_ID || !process.env.EMAILJS_USER_ID) throw new Error('EmailJS no configurado (EMAILJS_SERVICE_ID/TEMPLATE_ID/USER_ID faltantes)');
  const payload = {
    service_id: process.env.EMAILJS_SERVICE_ID,
    template_id: process.env.EMAILJS_TEMPLATE_ID,
    user_id: process.env.EMAILJS_USER_ID,
    template_params: {
      to_email: toEmail,
      reset_link: resetLink,
    },
  };
  const resp = await fetch('https://api.emailjs.com/api/v1.0/email/send', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  if (!resp.ok) {
    const txt = await resp.text();
    throw new Error(`EmailJS error ${resp.status} ${txt}`);
  }
}

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const body = req.method === 'GET' ? req.query : req.body || {};

  const email = body.email;
  if (!email) {
    // 400: falta parámetro obligatorio
    return res.status(400).json({
      success: false,
      reason: 'missing_email',
      // Mensaje en español, amigable para usuario; más detalle si estamos en desarrollo
      message: process.env.NODE_ENV === 'production' ? 'Falta el correo electrónico.' : 'Falta el parámetro "email" en el body o query.'
    });
  }

  const adminSdk = initAdmin();
  let db = null;
  const useFirestore = !!process.env.FIREBASE_SERVICE_ACCOUNT;
  if (useFirestore) {
    db = adminSdk.firestore();
  }

  const token = makeToken();
  const tokenHash = hashToken(token);
  const expiresAt = Date.now() + 1000 * 60 * 20; // 20 minutes

  try {
    if (useFirestore && db) {
      await db.collection('pin_reset_tokens').doc(tokenHash).set({
        email,
        createdAt: adminSdk.firestore.FieldValue.serverTimestamp(),
        expiresAt,
      });
    } else {
      // fallback: store in memory (development only)
      IN_MEMORY_STORE.set(tokenHash, { email, expiresAt });
    }
    const frontend = (process.env.FRONTEND_HOST || '').replace(/\/$/, '') || `https://${process.env.VERCEL_URL || ''}`;
    const resetLink = `${frontend}/redirectReset?token=${encodeURIComponent(token)}`;

  // Intentar EmailJS, luego SMTP; si no hay transporte, devolver el debugLink
    let sent = false;
    try {
      if (process.env.EMAILJS_SERVICE_ID) {
        await sendEmailEmailJS(email, resetLink);
        sent = true;
      }
    } catch (e) {
      console.warn('EmailJS failed', e.message || e);
    }
    if (!sent) {
      try {
        if (process.env.SMTP_HOST) {
          await sendEmailSMTP(email, resetLink);
          sent = true;
        }
      } catch (e) {
        console.warn('SMTP send failed', e.message || e);
      }
    }

    if (!sent) {
      // No se envió correo: devolvemos el debugLink para pruebas locales.
      return res.json({
        success: true,
        debugLink: resetLink,
        // Mensaje de advertencia en español
        warning: process.env.NODE_ENV === 'production' ? 'No se encontró ningún transporte de correo configurado.' : 'No email transport configured - returning debugLink for development testing.'
      });
    }

    return res.json({ success: true });
  } catch (e) {
    // Loguear en el servidor (stack en desarrollo y producción para auditoría interna)
    if (process.env.NODE_ENV === 'production') {
      console.error('request-reset error (producción)');
      // Guardar error resumido para no filtrar detalles al cliente
    } else {
      console.error('request-reset error', e && e.stack ? e.stack : e);
    }
    // Respuesta al cliente: código de razón para consumo por cliente y mensaje en español.
    return res.status(500).json({
      success: false,
      reason: 'internal',
      message: process.env.NODE_ENV === 'production' ? 'Error interno del servidor.' : `Error interno: ${e && e.message ? e.message : String(e)}`
    });
  }
};

// Export the in-memory store so other handlers can access it in dev (when FIREBASE_SERVICE_ACCOUNT is not set)
try {
  module.exports.IN_MEMORY_STORE = IN_MEMORY_STORE;
} catch (e) {
  // ignore
}
