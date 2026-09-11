const mongoose = require('mongoose');
const { applyToJson } = require('../utils/toJson');

const eBookSchema = new mongoose.Schema(
  {
    _id: { type: String },
    title: { type: String, required: true },
    priceBirr: { type: Number, required: true },
    cover: { type: String, default: '' },
    subjects: { type: [String], default: [] },
    pages: { type: [String], default: [] },
    freePages: { type: Number, default: 4 },

    // A PDF the admin uploaded, stored inline as base64 (fine at this app's
    // scale — small reference books, not a media library).
    pdfData: { type: String, default: null },
    pdfName: { type: String, default: null },
  },
  { _id: false, timestamps: true },
);

applyToJson(eBookSchema);

module.exports = mongoose.model('EBook', eBookSchema);
