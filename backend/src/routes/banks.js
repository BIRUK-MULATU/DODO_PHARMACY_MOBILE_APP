const express = require('express');
const { customAlphabet } = require('../utils/id');

const Bank = require('../models/Bank');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();
const newId = customAlphabet('bank');

// Any logged-in user needs the bank list to pick where to send a transfer —
// not admin-only, unlike the mutating verbs below.
router.get('/', requireAuth, async (_req, res) => {
  const banks = await Bank.find().sort({ createdAt: 1 });
  res.json({ banks: banks.map((b) => b.toJSON()) });
});

// The admin picks the code themselves (e.g. "CBE") rather than one being
// generated — it's a real, recognisable bank identifier, not a slug. Falls
// back to a generated id only if left blank.
router.post('/', requireAuth, requireAdmin, async (req, res) => {
  const { id, name, owner, number } = req.body ?? {};
  if (!name || !owner || !number) {
    return res.status(400).json({ error: 'name, owner and number are required.' });
  }
  const _id = (id || '').trim() || newId();
  const existing = await Bank.findById(_id);
  if (existing) return res.status(409).json({ error: `A bank with code "${_id}" already exists.` });
  const bank = await Bank.create({ _id, name, owner, number });
  res.status(201).json({ bank: bank.toJSON() });
});

router.put('/:id', requireAuth, requireAdmin, async (req, res) => {
  const bank = await Bank.findById(req.params.id);
  if (!bank) return res.status(404).json({ error: 'Bank not found.' });
  const { name, owner, number } = req.body ?? {};
  if (name !== undefined) bank.name = name;
  if (owner !== undefined) bank.owner = owner;
  if (number !== undefined) bank.number = number;
  await bank.save();
  res.json({ bank: bank.toJSON() });
});

router.delete('/:id', requireAuth, requireAdmin, async (req, res) => {
  await Bank.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
});

module.exports = router;
