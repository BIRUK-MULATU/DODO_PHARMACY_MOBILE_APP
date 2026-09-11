const mongoose = require('mongoose');
const { applyToJson } = require('../utils/toJson');

const examPackSchema = new mongoose.Schema(
  {
    _id: { type: String },
    trackId: { type: String, default: '' },
    title: { type: String, required: true },
    image: { type: String, default: '' },
    questionCount: { type: Number, required: true },
    priceBirr: { type: Number, required: true },
    freeLimit: { type: Number, required: true },

    // This pack's own "About Questions" screen content — each pack has its
    // own, not shared across every pack.
    aboutSummary: { type: String, default: '' },
    aboutBullets: { type: [String], default: [] },
    coreCourses: { type: [String], default: [] },
  },
  { _id: false, timestamps: true },
);

applyToJson(examPackSchema);

module.exports = mongoose.model('ExamPack', examPackSchema);
