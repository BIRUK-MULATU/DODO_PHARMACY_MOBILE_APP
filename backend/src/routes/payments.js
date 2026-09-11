const express = require('express');

const PaymentRequest = require('../models/PaymentRequest');
const ExamPack = require('../models/ExamPack');
const EBook = require('../models/EBook');
const User = require('../models/User');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Learner: submit a receipt for a pack (or a book, which travels through the
// same flow using its own id as the "packId" — see `purchasableForBook`).
router.post('/', requireAuth, async (req, res) => {
  const { packId, packTitle, bankCode, amountBirr, receiptImage } = req.body ?? {};
  if (!packId || !bankCode) {
    return res.status(400).json({ error: 'packId and bankCode are required.' });
  }

  // Resolve title/price from the real record when it's a known pack or book,
  // falling back to what the client sent (covers synthetic book "packs").
  let title = packTitle;
  let amount = amountBirr;
  const pack = await ExamPack.findById(packId);
  if (pack) {
    title = pack.title;
    amount = pack.priceBirr;
  } else {
    const book = await EBook.findById(packId);
    if (book) {
      title = book.title;
      amount = book.priceBirr;
    }
  }
  if (!title || amount === undefined) {
    return res.status(400).json({ error: 'Unknown packId — pass packTitle and amountBirr explicitly.' });
  }

  const request = await PaymentRequest.create({
    userId: req.user._id,
    userName: req.user.name,
    packId,
    packTitle: title,
    bankCode,
    amountBirr: amount,
    receiptImage: receiptImage ?? '',
  });

  req.user.uploadAttempts += 1;
  await req.user.save();

  res.status(201).json({ request: request.toJSON() });
});

router.get('/mine', requireAuth, async (req, res) => {
  const requests = await PaymentRequest.find({ userId: req.user._id }).sort({ submittedAt: -1 });
  res.json({ requests: requests.map((r) => r.toJSON()) });
});

router.get('/', requireAuth, requireAdmin, async (_req, res) => {
  const requests = await PaymentRequest.find().sort({ submittedAt: -1 });
  res.json({ requests: requests.map((r) => r.toJSON()) });
});

router.put('/:id/decide', requireAuth, requireAdmin, async (req, res) => {
  const { status } = req.body ?? {};
  if (!['approved', 'rejected'].includes(status)) {
    return res.status(400).json({ error: "status must be 'approved' or 'rejected'." });
  }
  const request = await PaymentRequest.findById(req.params.id);
  if (!request) return res.status(404).json({ error: 'Request not found.' });

  request.status = status;
  await request.save();

  const user = await User.findById(request.userId);
  if (user) {
    if (status === 'approved') {
      if (!user.unlockedPacks.includes(request.packId)) user.unlockedPacks.push(request.packId);
    } else {
      user.unlockedPacks = user.unlockedPacks.filter((id) => id !== request.packId);
    }
    await user.save();
  }

  res.json({ request: request.toJSON() });
});

module.exports = router;
