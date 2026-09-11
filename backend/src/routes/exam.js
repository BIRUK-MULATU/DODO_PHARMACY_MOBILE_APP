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

// Superseded by POST /packs/:packId/record-answer below (which does this
// same progress update plus streak/activity tracking in one call) — kept
// around, tested, and still fully functional, but the app no longer calls
// this one.
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

// What AppState.recordAnswer actually calls: the single event that drives
// every dashboard visualization that isn't purely derived from `progress`.
// `wasCorrect` is trusted the same way the rest of this app's
// client-reported data is (see "The paywall" in the README) — the client
// already has the real question/answer in hand by the time this fires.
router.post('/packs/:packId/record-answer', requireAuth, async (req, res) => {
  const pack = await ExamPack.findById(req.params.packId);
  if (!pack) return res.status(404).json({ error: 'Pack not found.' });
  const { wasCorrect, packTitle } = req.body ?? {};
  if (typeof wasCorrect !== 'boolean') {
    return res.status(400).json({ error: 'wasCorrect must be a boolean.' });
  }
  const user = req.user;

  const current = progressFor(user, pack.id);
  user.progress.set(pack.id, {
    answered: current.answered + 1,
    correct: current.correct + (wasCorrect ? 1 : 0),
  });

  if (wasCorrect) {
    user.currentStreak = (user.currentStreak || 0) + 1;
    user.bestStreak = Math.max(user.bestStreak || 0, user.currentStreak);
  } else {
    user.currentStreak = 0;
  }

  const dayKey = new Date().toISOString().slice(0, 10);
  const dailyActivity = user.dailyActivity || new Map();
  dailyActivity.set(dayKey, (dailyActivity.get(dayKey) || 0) + 1);
  user.dailyActivity = dailyActivity;

  const entry = {
    packId: pack.id,
    packTitle: packTitle || pack.title,
    wasCorrect,
    at: new Date(),
  };
  user.recentActivity = [entry, ...(user.recentActivity || [])].slice(0, 20);

  await user.save();

  res.json({
    answered: user.progress.get(pack.id).answered,
    correct: user.progress.get(pack.id).correct,
    currentStreak: user.currentStreak,
    bestStreak: user.bestStreak,
  });
});

const _weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S']; // Date#getDay(): 0=Sun

// Backs the dashboard's "This Week" bars and "Recent Activity" list.
router.get('/activity', requireAuth, async (req, res) => {
  const user = req.user;
  const today = new Date();
  const week = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    const key = d.toISOString().slice(0, 10);
    week.push({
      date: key,
      weekday: _weekdayLetters[d.getDay()],
      count: (user.dailyActivity || new Map()).get(key) || 0,
    });
  }
  res.json({
    week,
    recent: (user.recentActivity || []).map((e) => ({
      packId: e.packId,
      packTitle: e.packTitle,
      wasCorrect: e.wasCorrect,
      at: e.at,
    })),
  });
});

module.exports = router;
