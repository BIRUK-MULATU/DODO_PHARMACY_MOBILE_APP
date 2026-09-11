const mongoose = require('mongoose');
const { applyToJson } = require('../utils/toJson');

// `_id` is the bank's short code (e.g. "CBE"), chosen by the admin — shown
// to users on the payment-method screen, so it's a real account, not a slug.
const bankSchema = new mongoose.Schema(
  {
    _id: { type: String },
    name: { type: String, required: true },
    owner: { type: String, required: true },
    number: { type: String, required: true },
  },
  { _id: false, timestamps: true },
);

applyToJson(bankSchema);

module.exports = mongoose.model('Bank', bankSchema);
