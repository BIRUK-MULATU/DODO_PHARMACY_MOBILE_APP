const mongoose = require('mongoose');
const { applyToJson } = require('../utils/toJson');

const paymentRequestSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    userName: { type: String, required: true },
    packId: { type: String, required: true },
    packTitle: { type: String, required: true },
    bankCode: { type: String, required: true },
    amountBirr: { type: Number, required: true },
    submittedAt: { type: Date, default: Date.now },
    status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
    receiptImage: { type: String, default: '' },
  },
  { timestamps: true },
);

applyToJson(paymentRequestSchema);

module.exports = mongoose.model('PaymentRequest', paymentRequestSchema);
