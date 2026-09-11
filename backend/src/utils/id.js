const crypto = require('crypto');

// Human-readable unique ids for the slug-keyed collections (Track, ExamPack,
// EBook), mirroring the `${prefix}-${timestamp}-${seq}` scheme the front end
// used to generate client-side before there was a backend.
function customAlphabet(prefix) {
  return () => `${prefix}-${Date.now()}-${crypto.randomBytes(4).toString('hex')}`;
}

module.exports = { customAlphabet };
