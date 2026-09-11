// Bundled-asset choice lists — genuinely static, since they're presets from
// the Flutter app's own asset bundle, not editable content. Bank accounts
// used to live here too, but are real admin-editable data now (see
// `models/Bank.js` / `routes/banks.js`), not a constant.

const trackFigures = [
  'assets/images/pharmacist.png',
  'assets/images/nurse.png',
  'assets/images/kid.png',
  'assets/images/avatar.png',
];

const packImages = [
  'assets/images/home_banner_1.png',
  'assets/images/home_banner_2.png',
  'assets/images/book_cover.png',
  'assets/images/pay_hero.png',
  'assets/images/celebrate_hero.png',
];

const bookCovers = [
  'assets/images/book_cover.png',
  'assets/images/home_banner_1.png',
  'assets/images/home_banner_2.png',
  'assets/images/celebrate_hero.png',
  'assets/images/pay_hero.png',
];

const avatarChoices = [
  'assets/images/avatar.png',
  'assets/images/pharmacist.png',
  'assets/images/nurse.png',
  'assets/images/kid.png',
];

module.exports = { trackFigures, packImages, bookCovers, avatarChoices };
