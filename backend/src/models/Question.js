const mongoose = require('mongoose');
const { applyToJson } = require('../utils/toJson');

const questionSchema = new mongoose.Schema(
  {
    packId: { type: String, required: true, index: true },
    number: { type: Number, required: true },
    total: { type: Number, required: true },
    prompt: { type: String, required: true },
    options: { type: [String], required: true },
    correctIndex: { type: Number, required: true },
    explanation: { type: String, required: true },
  },
  { timestamps: true },
);

applyToJson(questionSchema);

module.exports = mongoose.model('Question', questionSchema);
