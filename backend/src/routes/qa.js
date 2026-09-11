const express = require('express');

const QaQuestion = require('../models/QaQuestion');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Learner: ask a question from the app's "Q&A" screen.
router.post('/', requireAuth, async (req, res) => {
  const question = (req.body?.question ?? '').trim();
  if (!question) {
    return res.status(400).json({ error: 'question is required.' });
  }
  if (question.length > 2000) {
    return res.status(400).json({ error: 'question is too long (2000 characters max).' });
  }

  const created = await QaQuestion.create({
    userId: req.user._id,
    userName: req.user.name,
    question,
  });

  res.status(201).json({ question: created.toJSON() });
});

// Learner: their own question/answer history, newest first.
router.get('/mine', requireAuth, async (req, res) => {
  const questions = await QaQuestion.find({ userId: req.user._id }).sort({ createdAt: -1 });
  res.json({ questions: questions.map((q) => q.toJSON()) });
});

// Admin: every question across every learner — pending first (the ones
// needing attention), newest first within each group.
router.get('/', requireAuth, requireAdmin, async (_req, res) => {
  // status: -1 sorts 'pending' before 'answered' (descending alphabetically —
  // 'p' > 'a') so the ones needing attention float to the top.
  const questions = await QaQuestion.find().sort({ status: -1, createdAt: -1 });
  res.json({ questions: questions.map((q) => q.toJSON()) });
});

// Admin: answer (or re-answer/edit) a question.
router.put('/:id/answer', requireAuth, requireAdmin, async (req, res) => {
  const answer = (req.body?.answer ?? '').trim();
  if (!answer) {
    return res.status(400).json({ error: 'answer is required.' });
  }

  const question = await QaQuestion.findById(req.params.id);
  if (!question) return res.status(404).json({ error: 'Question not found.' });

  question.answer = answer;
  question.status = 'answered';
  question.answeredAt = new Date();
  await question.save();

  res.json({ question: question.toJSON() });
});

// Admin: remove a question (spam, duplicate, etc.).
router.delete('/:id', requireAuth, requireAdmin, async (req, res) => {
  await QaQuestion.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
});

module.exports = router;
