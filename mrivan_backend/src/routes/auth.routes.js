const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth.middleware');

// Sync user profile from Supabase Auth with public profiles table
router.post('/sync', authenticate, authController.syncProfile);

module.exports = router;
