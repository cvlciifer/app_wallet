const crypto = require('crypto');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

const IN_MEMORY_STORE = new Map();

function maskEmail(email) {
  if (!email) return '';
  const parts = email.split('@');
  if (parts.length !== 2) return email;
  const name = parts[0];
  const domain = parts[1];
  const visible = name.length > 2 ? 2 : 1;
  return name.slice(0, visible) + Array(Math.max(0, name.length - visible)).fill('*').join('') + '@' + domain;
}
function initAdmin() {
  if (admin.apps.length) return admin;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({ credential: admin.credential.cert(sa) });
  } else {
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

async function sendEmailSMTP(toEmail, subject, htmlBody, textBody) {
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER)
    throw new Error('SMTP no configurado');

  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT) || 587,
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  await transporter.sendMail({
    from: process.env.SMTP_FROM,
    to: toEmail,
    subject,
    html: htmlBody,
    text: textBody || undefined,
  });
}

async function sendEmailEmailJS(toEmail, htmlBody, textBody) {
  if (
    !process.env.EMAILJS_SERVICE_ID ||
    !process.env.EMAILJS_TEMPLATE_ID ||
    !process.env.EMAILJS_USER_ID
  )
    throw new Error('EmailJS no configurado');

  const payload = {
    service_id: process.env.EMAILJS_SERVICE_ID,
    template_id: process.env.EMAILJS_TEMPLATE_ID,
    user_id: process.env.EMAILJS_USER_ID,
    template_params: {
      to_email: toEmail,
      reset_links_html: htmlBody,
      reset_links_text: textBody,
    },
  };

  const resp = await fetch('https://api.emailjs.com/api/v1.0/email/send', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!resp.ok) throw new Error(`EmailJS error ${resp.status}`);
}

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const body = req.method === 'GET' ? req.query : req.body || {};
  const email = body.email;
  if (!email) {
    return res.status(400).json({
      success: false,
      reason: 'missing_email',
      message:
        process.env.NODE_ENV === 'production'
          ? 'Falta el correo electrónico.'
          : 'Falta el parámetro "email".',
    });
  }

  const adminSdk = initAdmin();
  const useFirestore = !!process.env.FIREBASE_SERVICE_ACCOUNT;
  const db = useFirestore ? adminSdk.firestore() : null;

  const isProd = process.env.NODE_ENV === 'production';
  const hasAdminCreds = !!process.env.FIREBASE_SERVICE_ACCOUNT;

  if (isProd && !hasAdminCreds) {
    console.error(JSON.stringify({ event: 'request-reset', level: 'error', message: 'Missing FIREBASE_SERVICE_ACCOUNT in production' }));
    return res.status(500).json({ success: false, reason: 'server_misconfigured', message: 'Server not configured' });
  }

    const token = makeToken();
    const tokenHash = hashToken(token);
    const expiresAtMillis = Date.now() + 1000 * 60 * 20; // 20 minutos
    const expiresAt = useFirestore && db ? adminSdk.firestore.Timestamp.fromMillis(expiresAtMillis) : expiresAtMillis;

  try {
    if (useFirestore && db) {

      const userQuery = await db.collection('Registros')
        .where('email', '==', email)
        .limit(1)
        .get();

      if (userQuery.empty) throw new Error('Usuario no encontrado');
      const userRef = userQuery.docs[0].ref;

      await userRef.set(
        {
          pinReset: {
            tokenHash,
            expiresAt,
            createdAt: useFirestore && db ? adminSdk.firestore.Timestamp.fromMillis(Date.now()) : Date.now(),
          },
        },
        { merge: true }
      );

      console.info(JSON.stringify({ event: 'request-reset', level: 'info', email: maskEmail(email), tokenHash, createdAt: new Date().toISOString() }));
    } else {
      IN_MEMORY_STORE.set(tokenHash, { email, expiresAt: expiresAtMillis });
      console.info(JSON.stringify({ event: 'request-reset', level: 'info', email: maskEmail(email), tokenHash, createdAt: new Date().toISOString(), store: 'in-memory' }));
    }

    const deepLink = `adminwallet://resetPin?token=${encodeURIComponent(token)}`;
    const frontendHost =
      (process.env.FRONTEND_HOST || '').replace(/\/$/, '') ||
      (process.env.VERCEL_URL
        ? `https://${process.env.VERCEL_URL}`
        : '');
    const webLink = frontendHost
    ? `${frontendHost}/?token=${encodeURIComponent(token)}`
    : null;

    if (process.env.NODE_ENV !== 'production') {
      console.log('Generated resetLink (deep):', deepLink, ' webFallback:', webLink);
    }

    const displayLink = webLink || deepLink;

    // Texto plano para clientes que muestran sólo el snippet (evita que Gmail oculte contenido)
    const textBody = `Haz click en el siguiente enlace para reconfigurar tu PIN (expira en 20 minutos):\n\n${displayLink}\n\nSi ya tienes la app instalada, se abrirá automáticamente al abrir este enlace.\nEn caso contrario, puedes abrir la app manualmente e ingresar tu PIN nuevamente.\n\nSi no fuiste tu quien pidió recuperar el PIN, no hagas click en el enlace.`;

    // HTML: poner la advertencia visible antes del enlace y usar un texto de ancla corto
    const htmlBody = `
      <p><strong>Si no fuiste tú quien pidió recuperar el PIN, no hagas click en el enlace.</strong></p>
      <p>Haz click en el siguiente enlace para reconfigurar tu PIN (expira en 20 minutos):</p>
      <p><a href="${displayLink}">Abrir enlace para reconfigurar tu PIN</a></p>
      <p style="font-size:12px;color:#666;word-break:break-all;">${displayLink}</p>
      <p>Si no fuiste tú quien solicitó la recuperación de PIN, ignora este correo y no hagas clic en el enlace.</p>
      <p>Este enlace es de uso exclusivo para el titular de la cuenta y no debe compartirse con terceros.</p>
    `;

    let sent = false;

    try {
      if (process.env.EMAILJS_SERVICE_ID) {
        await sendEmailEmailJS(email, htmlBody, textBody);
        sent = true;
      }
    } catch (e) {
      console.warn('EmailJS failed', e.message);
    }

    if (!sent) {
      try {
        if (process.env.SMTP_HOST) {
          await sendEmailSMTP(email, 'Recupera tu PIN', htmlBody, textBody);
          sent = true;
        }
      } catch (e) {
        console.warn('SMTP send failed', e.message);
      }
    }

    if (!sent) {
      console.warn(JSON.stringify({ event: 'email-send', level: 'warn', email: maskEmail(email), reason: 'no_transport' }));
      return res.json({
        success: true,
        debugLink: { deep: deepLink, web: webLink },
        warning:
          process.env.NODE_ENV === 'production'
            ? 'No se encontró transporte de correo.'
            : 'No email transport configured - returning debugLink.',
      });
    }

    if (process.env.DEBUG_RETURN_LINK === 'true' && !isProd) {
      return res.json({
        success: true,
        debugLink: { deep: deepLink, web: webLink },
      });
    }

    return res.json({ success: true });
  } catch (e) {
    console.error(JSON.stringify({ event: 'request-reset-error', level: 'error', error: e.message || e.stack || e }));
    return res.status(500).json({
      success: false,
      reason: 'internal',
      message:
        process.env.NODE_ENV === 'production'
          ? 'Error interno del servidor.'
          : e.message,
    });
  }
};

try {
  module.exports.IN_MEMORY_STORE = IN_MEMORY_STORE;
} catch (e) {}
