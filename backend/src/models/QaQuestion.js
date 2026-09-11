const mongoose = require('mongoose');
const { applyToJson } = require('../utils/toJson');

// A question a learner asked from the app's "Q&A" screen, and (once an
// admin has gotten to it) the official answer. Mirrors PaymentRequest's
// shape: server-generated ObjectId (the client doesn't need to pick a slug
// for something this free-form), userId kept for ownership, userName kept
// redundantly so the admin list reads without a join.
const qaQuestionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    userName: { type: String, required: true },
    question: { type: String, required: true },
    answer: { type: String, default: '' },
    status: { type: String, enum: ['pending', 'answered'], default: 'pending' },
    answeredAt: { type: Date, default: null },
  },
  { timestamps: { createdAt: 'createdAt', updatedAt: false } },
);

applyToJson(qaQuestionSchema);

module.exports = mongoose.model('QaQuestion', qaQuestionSchema);
