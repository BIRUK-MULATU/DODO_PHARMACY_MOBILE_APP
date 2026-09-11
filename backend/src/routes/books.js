const express = require('express');
const { customAlphabet } = require('../utils/id');

const EBook = require('../models/EBook');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();
const newId = customAlphabet('book');

function withMeta(book) {
  return { ...book.toJSON(), pageCount: book.pages.length, hasPdf: Boolean(book.pdfData) };
}

// Metadata only (title/cover/price/subjects/pageCount/hasPdf) — never the
// pages or the PDF. The catalog list only ever needs this; an admin gets
// full content too (they need it to prefill the edit form), since they can
// already read/write every book through the CRUD routes below anyway.
router.get('/', requireAuth, async (req, res) => {
  const books = await EBook.find().sort({ createdAt: 1 });
  const isAdmin = req.user.role === 'admin';
  res.json({
    books: books.map((b) => {
      const json = withMeta(b);
      if (!isAdmin) {
        json.pages = [];
        json.pdfData = null;
      }
      return json;
    }),
  });
});

// Full content for one book, gated by whether the caller has unlocked it —
// pages/PDF beyond the free window are simply absent from the response
// otherwise. Admins always get full content (editing a book they haven't
// personally "purchased" is still a normal admin action).
router.get('/:id', requireAuth, async (req, res) => {
  const book = await EBook.findById(req.params.id);
  if (!book) return res.status(404).json({ error: 'Book not found.' });

  const unlocked = req.user.unlockedPacks.includes(book.id) || req.user.role === 'admin';
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
