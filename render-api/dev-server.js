// Pequeño wrapper con Express para ejecutar los handlers serverless de forma local sin Vercel CLI.
// Uso: define las variables de entorno (FIREBASE_SERVICE_ACCOUNT, FRONTEND_HOST, etc.) y ejecuta: node dev-server.js

const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');

// Polyfill para fetch en Node < 18
if (typeof fetch === 'undefined') {
  global.fetch = (...args) => import('node-fetch').then(m => m.default(...args));
}

const requestReset = require(path.join(__dirname, 'api', 'request-reset'));
const validateReset = require(path.join(__dirname, 'api', 'validate-reset'));
const consumeReset = require(path.join(__dirname, 'api', 'consume-reset'));

const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

app.options('/api/*', (req, res) => res.sendStatus(200));

app.post('/api/request-reset', async (req, res) => {
  try {
    await requestReset(req, res);
  } catch (e) {
    console.error('request-reset handler error', e);
    res.status(500).json({ success: false, reason: 'handler_error' });
  }
});

app.get('/api/request-reset', async (req, res) => {
  try { await requestReset(req, res); } catch (e) { console.error(e); res.status(500).end(); }
});

app.get('/api/validate-reset', async (req, res) => {
  try { await validateReset(req, res); } catch (e) { console.error(e); res.status(500).end(); }
});
app.post('/api/validate-reset', async (req, res) => {
  try { await validateReset(req, res); } catch (e) { console.error(e); res.status(500).end(); }
});

app.post('/api/consume-reset', async (req, res) => {
  try { await consumeReset(req, res); } catch (e) { console.error(e); res.status(500).end(); }
});
app.get('/api/consume-reset', async (req, res) => {
  try { await consumeReset(req, res); } catch (e) { console.error(e); res.status(500).end(); }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`dev-server listening on http://localhost:${PORT}`));
