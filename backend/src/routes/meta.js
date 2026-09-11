const express = require('express');
const staticData = require('../staticData');

const router = express.Router();

// Bundled-asset choice lists + bank accounts — static, not user data.
router.get('/', (_req, res) => res.json(staticData));

module.exports = router;
