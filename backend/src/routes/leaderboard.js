const express = require('express');

const User = require('../models/User');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

function totalCorrect(user) {
  let sum = 0;
  for (const entry of user.progress.values()) sum += entry.correct || 0;
  return sum;
}

// Ranks every account by total correct answers across every pack. Fine to
// compute on the fly at this app's scale (a handful to a few thousand
// users); revisit (a maintained counter + indexed sort) if that changes.
router.get('/me', requireAuth, async (req, res) => {
  const users = await User.find({}, '_id progress');
  const ranked = users
    .map((u) => ({ id: String(u._id), correct: totalCorrect(u) }))
    .sort((a, b) => b.correct - a.correct);

  const position = ranked.findIndex((r) => r.id === String(req.user._id));
  res.json({
    rank: position === -1 ? ranked.length : position + 1,
    totalUsers: ranked.length,
  });
});

module.exports = router;
