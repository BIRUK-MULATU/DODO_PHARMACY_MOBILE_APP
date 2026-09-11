const express = require('express');
const { customAlphabet } = require('../utils/id');

const Track = require('../models/Track');
const ExamPack = require('../models/ExamPack');
const Question = require('../models/Question');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();
const newId = customAlphabet('track');

router.get('/', async (_req, res) => {
  const tracks = await Track.find().sort({ createdAt: 1 });
  res.json({ tracks: tracks.map((t) => t.toJSON()) });
});

// Accepts a client-supplied `id` when given (the Flutter admin screens
// pre-generate one so they can add the new item to the local list right
// away, before the network round-trip finishes) — falls back to a
// server-generated one otherwise.
router.post('/', requireAuth, requireAdmin, async (req, res) => {
  const { id, name, figure } = req.body ?? {};
  if (!name) return res.status(400).json({ error: 'name is required.' });
  const track = await Track.create({ _id: id || newId(), name, figure: figure ?? '' });
  res.status(201).json({ track: track.toJSON() });
});

router.put('/:id', requireAuth, requireAdmin, async (req, res) => {
  const { name, figure } = req.body ?? {};
  const track = await Track.findById(req.params.id);
  if (!track) return res.status(404).json({ error: 'Track not found.' });
  if (name !== undefined) track.name = name;
  if (figure !== undefined) track.figure = figure;
  await track.save();
  res.json({ track: track.toJSON() });
});

// Deleting a track cascades to its packs, and their packs' questions.
router.delete('/:id', requireAuth, requireAdmin, async (req, res) => {
  const id = req.params.id;
  const packs = await ExamPack.find({ trackId: id });
  const packIds = packs.map((p) => p.id);
  await Question.deleteMany({ packId: { $in: packIds } });
  await ExamPack.deleteMany({ trackId: id });
  await Track.findByIdAndDelete(id);
  res.json({ ok: true });
});

module.exports = router;
