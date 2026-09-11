const express = require('express');
const { customAlphabet } = require('../utils/id');

const EBook = require('../models/EBook');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();
const newId = customAlphabet('book');

function withMeta(book) {
  return { ...book.toJSON(), pageCount: book.pages.length, hasPdf: Boolean(book.pdfData) };
}

// Full content for every book, same trust model the client always had (the
// in-memory `MockData` version held every page for every book regardless of
// payment status — the free/paid split was, and still is, enforced by the
// reader UI/`AppState`, not by withholding content). `GET /:id` below is a
// stricter, gate-on-the-server alternative that isn't wired into the app
// yet — see backend/README.md.
router.get('/', async (_req, res) => {
  const books = await EBook.find().sort({ createdAt: 1 });
  res.json({ books: books.map(withMeta) });
});

// Stricter alternative to the list above: only ever reveals pages/PDF up to
// the free window unless the caller has actually unlocked the book. Not
// called by the app today — a future hardening pass could switch the reader
// to fetch through this instead of trusting the bulk list.
router.get('/:id', requireAuth, async (req, res) => {
  const book = await EBook.findById(req.params.id);
  if (!book) return res.status(404).json({ error: 'Book not found.' });

  const unlocked = req.user.unlockedPacks.includes(book.id);
  const json = withMeta(book);
  if (!unlocked) {
    json.pdfData = null;
    json.pages = book.pages.slice(0, book.freePages);
  }
  json.unlocked = unlocked;
  res.json({ book: json });
});

// Accepts a client-supplied `id` (see tracks.js for why) — falls back to a
// server-generated one otherwise.
router.post('/', requireAuth, requireAdmin, async (req, res) => {
  const { id, title, priceBirr, cover, subjects, pages, freePages, pdfData, pdfName } = req.body ?? {};
  if (!title || priceBirr === undefined) {
    return res.status(400).json({ error: 'title and priceBirr are required.' });
  }
  const book = await EBook.create({
    _id: id || newId(),
    title,
    priceBirr,
    cover: cover ?? '',
    subjects: subjects ?? [],
    pages: pages ?? [],
    freePages: freePages ?? 4,
    pdfData: pdfData ?? null,
    pdfName: pdfName ?? null,
  });
  res.status(201).json({ book: book.toJSON() });
});

router.put('/:id', requireAuth, requireAdmin, async (req, res) => {
  const book = await EBook.findById(req.params.id);
  if (!book) return res.status(404).json({ error: 'Book not found.' });
  const { title, priceBirr, cover, subjects, pages, freePages, pdfData, pdfName } = req.body ?? {};
  if (title !== undefined) book.title = title;
  if (priceBirr !== undefined) book.priceBirr = priceBirr;
  if (cover !== undefined) book.cover = cover;
  if (subjects !== undefined) book.subjects = subjects;
  if (pages !== undefined) book.pages = pages;
  if (freePages !== undefined) book.freePages = freePages;
  if (pdfData !== undefined) book.pdfData = pdfData;
  if (pdfName !== undefined) book.pdfName = pdfName;
  await book.save();
  res.json({ book: book.toJSON() });
});

router.delete('/:id', requireAuth, requireAdmin, async (req, res) => {
  await EBook.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
});

module.exports = router;
