const express = require('express');

const Question = require('../models/Question');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Full question content — same trust model the in-memory `AppState` always
// used (every question, including `correctIndex`/`explanation`, sat in the
// client's memory; the free-question paywall was, and still is, enforced by
// `AppState.questionLocked`/`maxReachableIndex`, not by withholding
// content). `/api/exam` below is a stricter, gate-on-the-server alternative
// that isn't wired into the app yet — see backend/README.md. Mutating verbs
// stay admin-only.
router.get('/', requireAuth, async (req, res) => {
  const filter = {};
  if (req.query.packId) filter.packId = req.query.packId;
  const questions = await Question.find(filter).sort({ number: 1 });
  res.json({ questions: questions.map((q) => q.toJSON()) });
});

router.post('/', requireAuth, requireAdmin, async (req, res) => {
  const { packId, number, total, prompt, options, correctIndex, explanation } = req.body ?? {};
  if (!packId || !prompt || !options || correctIndex === undefined || !explanation) {
    return res.status(400).json({
      error: 'packId, prompt, options, correctIndex and explanation are required.',
    });
  }
  const question = await Question.create({
    packId,
    number: number ?? 0,
    total: total ?? 0,
    prompt,
    options,
    correctIndex,
    explanation,
  });
  res.status(201).json({ question: question.toJSON() });
});

router.put('/:id', requireAuth, requireAdmin, async (req, res) => {
  const question = await Question.findById(req.params.id);
  if (!question) return res.status(404).json({ error: 'Question not found.' });
  const { packId, number, total, prompt, options, correctIndex, explanation } = req.body ?? {};
  if (packId !== undefined) question.packId = packId;
  if (number !== undefined) question.number = number;
  if (total !== undefined) question.total = total;
  if (prompt !== undefined) question.prompt = prompt;
  if (options !== undefined) question.options = options;
  if (correctIndex !== undefined) question.correctIndex = correctIndex;
  if (explanation !== undefined) question.explanation = explanation;
  await question.save();
  res.json({ question: question.toJSON() });
});

router.delete('/:id', requireAuth, requireAdmin, async (req, res) => {
  await Question.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
});

module.exports = router;
