// Shared `toJSON` transform so every model serialises the way the Flutter
// models expect: `id` (string) instead of Mongo's `_id`/`__v`.
function applyToJson(schema) {
  schema.set('toJSON', {
    virtuals: true,
    versionKey: false,
    transform: (_doc, ret) => {
      ret.id = String(ret._id);
      delete ret._id;
      return ret;
    },
  });
}

module.exports = { applyToJson };
