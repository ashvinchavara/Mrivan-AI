const express = require('express');
const router = express.Router();
const testController = require('../controllers/test.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Create test (Admins & Teachers only)
router.post('/', authenticate, authorize(['admin', 'teacher']), testController.createMockTest);

// List available tests
router.get('/', authenticate, testController.getMockTests);

// Get specific test details (with questions)
router.get('/:id', authenticate, testController.getMockTestDetails);

// Submit test attempt for auto-grading (Students only)
router.post('/:id/attempt', authenticate, authorize(['student']), testController.attemptMockTest);

module.exports = router;
