const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const trackRoutes = require('./routes/tracks');
const packRoutes = require('./routes/packs');
const questionRoutes = require('./routes/questions');
const examRoutes = require('./routes/exam');
const bookRoutes = require('./routes/books');
const paymentRoutes = require('./routes/payments');
const aboutRoutes = require('./routes/about');
const metaRoutes = require('./routes/meta');

const app = express();

app.use(cors());
// Receipts/avatars/covers travel as base64 data URIs — comfortably raise the
// body limit above Express's 100kb default.
app.use(express.json({ limit: '20mb' }));

app.get('/health', (_req, res) => res.json({ ok: true }));

app.use('/api/auth', authRoutes);
app.use('/api/tracks', trackRoutes);
app.use('/api/packs', packRoutes);
app.use('/api/questions', questionRoutes);
app.use('/api/exam', examRoutes);
app.use('/api/books', bookRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/about', aboutRoutes);
app.use('/api/meta', metaRoutes);

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
