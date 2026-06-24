const express = require('express');
const router = express.Router();
const multer = require('multer');
const aiController = require('../controllers/ai.controller');
const resumeController = require('../controllers/resume.controller');
const syllabusController = require('../controllers/syllabus.controller');
const timetableController = require('../controllers/timetable.controller');
const { authenticate } = require('../middleware/auth.middleware');

// Configure multer memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // limit to 10MB
  }
});

// AI Tutor chat interaction
router.post('/tutor/chat', authenticate, aiController.getTutorChat);

// AI Study Notes Generator
router.post('/notes', authenticate, aiController.generateNotes);

// AI Practice Quiz Generator
router.post('/quiz', authenticate, aiController.generateQuiz);

// AI Voice Tutor explanation helper
router.post('/voice', authenticate, aiController.getVoiceTutor);

// AI Mock Interview grading
router.post('/tutor/interview/grade', authenticate, aiController.gradeInterview);

// AI Resume Analyzer / ATS Grader
router.post('/resume/analyze', authenticate, upload.single('resume'), resumeController.analyzeResume);

// AI Syllabus Parser
router.post('/syllabus/parse', authenticate, upload.single('syllabus'), syllabusController.parseSyllabus);

// AI Timetable Parser
router.post('/timetable/parse', authenticate, upload.single('timetable'), timetableController.parseTimetable);

module.exports = router;
