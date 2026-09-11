const express = require('express');
const { customAlphabet } = require('../utils/id');

const ExamPack = require('../models/ExamPack');
const Question = require('../models/Question');
const User = require('../models/User');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();
const newId = customAlphabet('pack');

router.get('/', async (req, res) => {
  const filter = {};
  if (req.query.trackId) filter.trackId = req.query.trackId;
  const packs = await ExamPack.find(filter).sort({ createdAt: 1 });
  res.json({ packs: packs.map((p) => p.toJSON()) });
});

// Accepts a client-supplied `id` (see tracks.js for why) — falls back to a
// server-generated one otherwise.
router.post('/', requireAuth, requireAdmin, async (req, res) => {
  const { id, title, image, questionCount, priceBirr, freeLimit, trackId } = req.body ?? {};
  if (!title || questionCount === undefined || priceBirr === undefined || freeLimit === undefined) {
    return res.status(400).json({ error: 'title, questionCount, priceBirr and freeLimit are required.' });
  }
  const pack = await ExamPack.create({
    _id: id || newId(),
    title,
    image: image ?? '',
    questionCount,
    priceBirr,
    freeLimit,
    trackId: trackId ?? '',
  });
  res.status(201).json({ pack: pack.toJSON() });
});

router.put('/:id', requireAuth, requireAdmin, async (req, res) => {
  const pack = await ExamPack.findById(req.params.id);
  if (!pack) return res.status(404).json({ error: 'Pack not found.' });
  const { title, image, questionCount, priceBirr, freeLimit, trackId } = req.body ?? {};
  if (title !== undefined) pack.title = title;
  if (image !== undefined) pack.image = image;
  if (questionCount !== undefined) pack.questionCount = questionCount;
  if (priceBirr !== undefined) pack.priceBirr = priceBirr;
  if (freeLimit !== undefined) pack.freeLimit = freeLimit;
  if (trackId !== undefined) pack.trackId = trackId;
  await pack.save();
  res.json({ pack: pack.toJSON() });
});

// Deleting a pack cascades to its questions and clears it from every user's
// unlocked/progress state.
router.delete('/:id', requireAuth, requireAdmin, async (req, res) => {
  const id = req.params.id;
  await Question.deleteMany({ packId: id });
  await ExamPack.findByIdAndDelete(id);
  await User.updateMany(
    {},
    { $pull: { unlockedPacks: id }, $unset: { [`progress.${id}`]: '' } },
  );
  res.json({ ok: true });
});

module.exports = router;
