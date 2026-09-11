const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./routes/auth');
const trackRoutes = require('./routes/tracks');
const packRoutes = require('./routes/packs');
const questionRoutes = require('./routes/questions');
const examRoutes = require('./routes/exam');
const bookRoutes = require('./routes/books');
const paymentRoutes = require('./routes/payments');
const aboutRoutes = require('./routes/about');
const metaRoutes = require('./routes/meta');
const leaderboardRoutes = require('./routes/leaderboard');
const bankRoutes = require('./routes/banks');
const userRoutes = require('./routes/users');
const qaRoutes = require('./routes/qa');

const app = express();

// CORS_ORIGIN restricts which web origins may call this API (comma-separated
// if there's more than one, e.g. the deployed app's own domain). Only
// matters for the web build — native apps don't send an Origin header at
// all. Left wide open by default so local development (`flutter run -d
// chrome` against localhost) just works; set CORS_ORIGIN before deploying
// anywhere public.
const corsOrigins = process.env.CORS_ORIGIN?.split(',').map((o) => o.trim()).filter(Boolean);
if (!corsOrigins?.length) {
  console.warn(
    '[cors] CORS_ORIGIN is not set — accepting requests from any web origin. ' +
      'Set it to your deployed app\'s domain(s) before this is public.',
  );
}
app.use(cors({ origin: corsOrigins?.length ? corsOrigins : true }));

// Receipts/avatars/covers travel as base64 data URIs — comfortably raise the
// body limit above Express's 100kb default.
app.use(express.json({ limit: '20mb' }));

app.get('/health', (_req, res) => res.json({ ok: true }));

// A generous baseline limit on everything under /api, plus a much tighter
// one on auth specifically (below) — not a substitute for real abuse
// monitoring at scale, but a reasonable floor for this app's size.
app.use(
  '/api',
  rateLimit({
    windowMs: 60 * 1000,
    limit: 120,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

// Auth endpoints are the ones worth brute-forcing (guessing a password,
// hammering the reset-code, enumerating signup emails) — cap them tighter
// than the rest of the API. Keyed by IP; fine for a single-instance deploy,
// revisit (a shared store) if this ever runs behind multiple instances.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts. Try again in a few minutes.' },
});
app.use('/api/auth', authLimiter);

app.use('/api/auth', authRoutes);
app.use('/api/tracks', trackRoutes);
app.use('/api/packs', packRoutes);
app.use('/api/questions', questionRoutes);
app.use('/api/exam', examRoutes);
app.use('/api/books', bookRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/about', aboutRoutes);
app.use('/api/meta', metaRoutes);
app.use('/api/leaderboard', leaderboardRoutes);
app.use('/api/banks', bankRoutes);
app.use('/api/users', userRoutes);
app.use('/api/qa', qaRoutes);

// 404 for anything else under /api.
app.use('/api', (_req, res) => res.status(404).json({ error: 'Not found.' }));

// Last-resort error handler so a thrown/rejected error becomes JSON, not an
// HTML stack trace or a hung request.
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error.' });
});

module.exports = app;
