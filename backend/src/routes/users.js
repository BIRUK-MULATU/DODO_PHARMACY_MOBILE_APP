const express = require('express');

const User = require('../models/User');
const ExamPack = require('../models/ExamPack');
const EBook = require('../models/EBook');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();

function summarize(user) {
  let totalAnswered = 0;
  let totalCorrect = 0;
  for (const entry of user.progress.values()) {
    totalAnswered += entry.answered || 0;
    totalCorrect += entry.correct || 0;
  }
  return {
    id: String(user._id),
    name: user.name,
    username: user.username,
    email: user.email,
    phone: user.phone,
    avatar: user.avatar,
    role: user.role,
    createdAt: user.createdAt,
    unlockedPacks: user.unlockedPacks,
    totalAnswered,
    totalCorrect,
    currentStreak: user.currentStreak || 0,
    bestStreak: user.bestStreak || 0,
  };
}

// The admin "Users" page — every account, with enough of a summary to show
// in a list (full detail/activity is a separate call per user, below).
router.get('/', requireAuth, requireAdmin, async (_req, res) => {
  const users = await User.find().sort({ createdAt: -1 });
  res.json({ users: users.map(summarize) });
});

// One user's activity — same shape as GET /api/exam/activity, but for any
// user (admin-only), not just the caller.
router.get('/:id/activity', requireAuth, requireAdmin, async (req, res) => {
  const user = await User.findById(req.params.id);
  if (!user) return res.status(404).json({ error: 'User not found.' });

  const weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  const today = new Date();
  const week = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    const key = d.toISOString().slice(0, 10);
    week.push({
      date: key,
      weekday: weekdayLetters[d.getDay()],
      count: (user.dailyActivity || new Map()).get(key) || 0,
    });
  }
  res.json({
    user: summarize(user),
    week,
    recent: (user.recentActivity || []).map((e) => ({
      packId: e.packId,
      packTitle: e.packTitle,
      wasCorrect: e.wasCorrect,
      at: e.at,
    })),
  });
});

// Direct, ongoing access control — grant or revoke one pack/book for one
// user, independent of any specific payment request (that flow still works
// too; this is for correcting/overriding it, or granting access outright).
router.put('/:id/access', requireAuth, requireAdmin, async (req, res) => {
  const user = await User.findById(req.params.id);
  if (!user) return res.status(404).json({ error: 'User not found.' });
  const { packId, unlock } = req.body ?? {};
  if (!packId || typeof unlock !== 'boolean') {
    return res.status(400).json({ error: 'packId and unlock (boolean) are required.' });
  }

  const known = (await ExamPack.findById(packId)) || (await EBook.findById(packId));
  if (!known) return res.status(404).json({ error: 'No pack or book with that id.' });

  const has = user.unlockedPacks.includes(packId);
  if (unlock && !has) user.unlockedPacks.push(packId);
  if (!unlock && has) user.unlockedPacks = user.unlockedPacks.filter((id) => id !== packId);
  await user.save();

  res.json({ user: summarize(user) });
});

module.exports = router;
