const mongoose = require('mongoose');
const { applyToJson } = require('../utils/toJson');

// `_id` is a human-chosen slug (e.g. "pharmacy") — packs reference it by
// string, matching the Dart `Track.id` / `ExamPack.trackId` fields.
const trackSchema = new mongoose.Schema(
  {
    _id: { type: String },
    name: { type: String, required: true },
    figure: { type: String, default: '' },
  },
  { _id: false, timestamps: true },
);

applyToJson(trackSchema);

module.exports = mongoose.model('Track', trackSchema);
