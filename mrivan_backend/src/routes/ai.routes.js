const express = require('express');
const router = express.Router();
const aiController = require('../controllers/ai.controller');
const { authenticate } = require('../middleware/auth.middleware');

// AI Tutor chat interaction
router.post('/tutor/chat', authenticate, aiController.getTutorChat);

// AI Study Notes Generator
router.post('/notes', authenticate, aiController.generateNotes);

// AI Practice Quiz Generator
router.post('/quiz', authenticate, aiController.generateQuiz);

// AI Voice Tutor explanation helper
router.post('/voice', authenticate, aiController.getVoiceTutor);

module.exports = router;
