const mongoose = require('mongoose');
const { applyToJson } = require('../utils/toJson');

// Singleton document (fixed _id) — the drawer "About" screen content.
const aboutInfoSchema = new mongoose.Schema(
  {
    _id: { type: String, default: 'singleton' },
    version: { type: String, default: '1.0.0' },
    intro: { type: String, default: '' },
    features: { type: [String], default: [] },
    unlocking: { type: String, default: '' },
    supportEmail: { type: String, default: '' },
    supportTelegram: { type: String, default: '' },
    supportPhone: { type: String, default: '' },
    footer: { type: String, default: '' },
  },
  { _id: false, timestamps: true },
);

applyToJson(aboutInfoSchema);

module.exports = mongoose.model('AboutInfo', aboutInfoSchema);
