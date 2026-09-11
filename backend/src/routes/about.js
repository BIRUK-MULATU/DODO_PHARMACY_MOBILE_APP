const express = require('express');

const AboutInfo = require('../models/AboutInfo');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();

router.get('/', async (_req, res) => {
  const about = await AboutInfo.findById('singleton');
  res.json({ about: about ? about.toJSON() : null });
});

router.put('/', requireAuth, requireAdmin, async (req, res) => {
  const { version, intro, features, unlocking, supportEmail, supportTelegram, supportPhone, footer } =
    req.body ?? {};
  const about = await AboutInfo.findByIdAndUpdate(
    'singleton',
    { version, intro, features, unlocking, supportEmail, supportTelegram, supportPhone, footer },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
  res.json({ about: about.toJSON() });
});

module.exports = router;
