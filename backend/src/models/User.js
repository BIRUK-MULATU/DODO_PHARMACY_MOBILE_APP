const mongoose = require('mongoose');

const progressEntrySchema = new mongoose.Schema(
  {
    answered: { type: Number, default: 0 },
    correct: { type: Number, default: 0 },
  },
  { _id: false },
);

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    username: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    phone: { type: String, default: '' },
    avatar: { type: String, default: 'assets/images/avatar.png' },

    // Any email starting with "admin" is an admin — same rule the front end
    // used to apply purely client-side; now it's also enforced server-side.
    role: { type: String, enum: ['user', 'admin'], default: 'user' },

    // Packs (or synthetic book "packs") this user has paid for and unlocked.
    unlockedPacks: { type: [String], default: [] },

    // Per-pack answered/correct counts, keyed by packId.
    progress: {
      type: Map,
      of: progressEntrySchema,
      default: () => new Map(),
    },

    uploadAttempts: { type: Number, default: 0 },
  },
  { timestamps: true },
);

// `id` instead of `_id`/`__v`, and never send the password hash back.
userSchema.set('toJSON', {
  virtuals: true,
  versionKey: false,
  transform: (_doc, ret) => {
    ret.id = String(ret._id);
    delete ret._id;
    delete ret.passwordHash;
    return ret;
  },
});

module.exports = mongoose.model('User', userSchema);
