const express = require('express');

const ExamPack = require('../models/ExamPack');
const Question = require('../models/Question');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

function progressFor(user, packId) {
  const entry = user.progress.get(packId);
  return { answered: entry?.answered ?? 0, correct: entry?.correct ?? 0 };
}

// Mirrors `AppState.questionLocked` / `maxReachableIndex` — the free-question
// paywall, enforced here so a client can no longer bypass it just by not
// asking the (trusting, in-memory) app state a question.
function isLocked(pack, user, index) {
  const unlocked = user.unlockedPacks.includes(pack.id);
  if (unlocked) return false;
  const { answered } = progressFor(user, pack.id);
  return answered >= pack.freeLimit || index >= pack.freeLimit;
}

router.get('/packs/:packId/state', requireAuth, async (req, res) => {
  const pack = await ExamPack.findById(req.params.packId);
  if (!pack) return res.status(404).json({ error: 'Pack not found.' });
  const unlocked = req.user.unlockedPacks.includes(pack.id);
  const { answered, correct } = progressFor(req.user, pack.id);
  const maxReachableIndex = unlocked
    ? pack.questionCount - 1
    : Math.min(Math.max(pack.freeLimit, 0), pack.questionCount - 1);
  res.json({ unlocked, answered, correct, maxReachableIndex });
});

router.get('/packs/:packId/questions/:index', requireAuth, async (req, res) => {
  const pack = await ExamPack.findById(req.params.packId);
  if (!pack) return res.status(404).json({ error: 'Pack not found.' });
  const index = Number(req.params.index);
  if (!Number.isInteger(index) || index < 0) {
    return res.status(400).json({ error: 'index must be a non-negative integer.' });
  }

  if (isLocked(pack, req.user, index)) {
    return res.json({ locked: true, index, total: pack.questionCount });
  }

  // Loops the pack's authored questions so the exam can run past what's been
  // written so far — same demo-friendly behaviour the in-memory app had.
  let pool = await Question.find({ packId: pack.id }).sort({ number: 1 });
  if (pool.length === 0) pool = await Question.find().sort({ number: 1 });
  if (pool.length === 0) {
    return res.status(404).json({ error: 'No questions exist yet.' });
  }
  const question = pool[index % pool.length];

  res.json({ locked: false, index, total: pack.questionCount, question: question.toJSON() });
});

router.post('/packs/:packId/questions/:index/answer', requireAuth, async (req, res) => {
  const pack = await ExamPack.findById(req.params.packId);
  if (!pack) return res.status(404).json({ error: 'Pack not found.' });
  const index = Number(req.params.index);
  const { selectedIndex } = req.body ?? {};
  if (!Number.isInteger(index) || index < 0 || !Number.isInteger(selectedIndex)) {
    return res.status(400).json({ error: 'index and selectedIndex must be integers.' });
  }
  if (isLocked(pack, req.user, index)) {
    return res.status(403).json({ error: 'This question is behind the paywall.' });
  }

  let pool = await Question.find({ packId: pack.id }).sort({ number: 1 });
  if (pool.length === 0) pool = await Question.find().sort({ number: 1 });
  if (pool.length === 0) return res.status(404).json({ error: 'No questions exist yet.' });
  const question = pool[index % pool.length];
  const wasCorrect = selectedIndex === question.correctIndex;

  const current = progressFor(req.user, pack.id);
  req.user.progress.set(pack.id, {
    answered: current.answered + 1,
    correct: current.correct + (wasCorrect ? 1 : 0),
  });
  await req.user.save();

  res.json({
    correct: wasCorrect,
    correctIndex: question.correctIndex,
    explanation: question.explanation,
  });
});

// Persists the answered/correct counts the client already tracked and
// computed itself (`AppState.recordAnswer`) — trusted the same way the rest
// of this app's client-reported data is (see "The paywall" in the README).
// Used so progress survives a restart / follows the account across devices;
// the stricter, index-checked `/answer` above is the not-yet-adopted
// alternative that would make this redundant.
router.put('/packs/:packId/progress', requireAuth, async (req, res) => {
  const pack = await ExamPack.findById(req.params.packId);
  if (!pack) return res.status(404).json({ error: 'Pack not found.' });
  const { answered, correct } = req.body ?? {};
  if (!Number.isInteger(answered) || !Number.isInteger(correct)) {
    return res.status(400).json({ error: 'answered and correct must be integers.' });
  }
  req.user.progress.set(pack.id, { answered, correct });
  await req.user.save();
  res.json({ ok: true });
});

module.exports = router;
