// Content that mirrors the Flutter app's own asset bundle — it isn't user
// data, so it lives as a constant here rather than in Mongo, same as
// `MockData` did on the client before the backend existed.

const banks = [
  {
    code: 'CBE',
    name: 'Commercial Bank of Ethiopia',
    owner: 'Yishak Abraham',
    number: '1000641510584',
  },
  {
    code: 'BOA',
    name: 'Bank of Abyssinia',
    owner: 'Yishak Abraham',
    number: '1000641510584',
  },
];

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

module.exports = { banks, trackFigures, packImages, bookCovers, avatarChoices };
