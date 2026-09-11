const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const User = require('../models/User');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

function signToken(user) {
  return jwt.sign({ sub: user.id }, process.env.JWT_SECRET, { expiresIn: '30d' });
}

// Any email starting with "admin" is an admin — the same rule the UI used to
// apply purely client-side ("Tip: sign in with an admin… email").
function roleForEmail(email) {
  return email.trim().toLowerCase().startsWith('admin') ? 'admin' : 'user';
}

router.post('/signup', async (req, res) => {
  const { name, username, email, password, phone } = req.body ?? {};
  if (!name || !username || !email || !password) {
    return res.status(400).json({ error: 'name, username, email and password are required.' });
  }

  const existing = await User.findOne({ email: email.trim().toLowerCase() });
  if (existing) return res.status(409).json({ error: 'An account with that email already exists.' });

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await User.create({
    name,
    username,
    email: email.trim().toLowerCase(),
    passwordHash,
    phone: phone ?? '',
    role: roleForEmail(email),
  });

  return res.status(201).json({ token: signToken(user), user: user.toJSON() });
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body ?? {};
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password are required.' });
  }

  const user = await User.findOne({ email: String(email).trim().toLowerCase() });
  if (!user) return res.status(401).json({ error: 'Invalid email or password.' });

  const ok = await bcrypt.compare(password, user.passwordHash);
  if (!ok) return res.status(401).json({ error: 'Invalid email or password.' });

  return res.json({ token: signToken(user), user: user.toJSON() });
});

// Dev/demo-only "forgot password": there's no email service wired up here,
// so this mirrors the front end's old fully-simulated flow (a fixed,
// publicly-known code) but now actually updates the real stored password
// instead of only ever touching whatever profile happened to be in the
// client's local memory. Replace with a real emailed-token flow before this
// app is ever exposed outside a dev/demo environment.
const DEV_RESET_CODE = '1234';

router.post('/reset-password', async (req, res) => {
  const { email, code, newPassword } = req.body ?? {};
  if (!email || !code || !newPassword) {
    return res.status(400).json({ error: 'email, code and newPassword are required.' });
  }
  if (code !== DEV_RESET_CODE) {
    return res.status(400).json({ error: `Incorrect code. (Demo code is ${DEV_RESET_CODE}.)` });
  }
  const user = await User.findOne({ email: String(email).trim().toLowerCase() });
  if (!user) return res.status(404).json({ error: 'No account with that email.' });

  user.passwordHash = await bcrypt.hash(newPassword, 10);
  await user.save();
  res.json({ ok: true });
});

router.get('/me', requireAuth, (req, res) => {
  res.json({ user: req.user.toJSON() });
});

router.put('/me', requireAuth, async (req, res) => {
  const { name, username, email, phone, avatar, password } = req.body ?? {};
  const user = req.user;

  if (name !== undefined) user.name = name;
  if (username !== undefined) user.username = username;
  if (phone !== undefined) user.phone = phone;
  if (avatar !== undefined) user.avatar = avatar;
  if (email !== undefined && email.trim().toLowerCase() !== user.email) {
    const taken = await User.findOne({ email: email.trim().toLowerCase() });
    if (taken) return res.status(409).json({ error: 'That email is already in use.' });
    user.email = email.trim().toLowerCase();
    user.role = roleForEmail(user.email);
  }
  if (password) {
    user.passwordHash = await bcrypt.hash(password, 10);
  }

  await user.save();
  res.json({ user: user.toJSON() });
});

module.exports = router;
