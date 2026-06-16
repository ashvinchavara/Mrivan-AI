const express = require('express');
const router = express.Router();
const crmController = require('../controllers/crm.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// 1. Schools (Admin only)
router.post('/schools', authenticate, authorize(['admin']), crmController.createSchool);

// 2. Classes (Admin/Teacher actions)
router.post('/classes', authenticate, authorize(['admin']), crmController.createClass);
router.get('/classes', authenticate, authorize(['admin', 'teacher']), crmController.getClasses);

// 3. Students list
router.get('/students', authenticate, authorize(['admin', 'teacher']), crmController.getStudents);

// 4. Attendance
router.post('/attendance', authenticate, authorize(['teacher']), crmController.recordAttendance);
router.get('/attendance', authenticate, crmController.getAttendance); // Filtering is handled in controller based on role

// 5. Homework
router.post('/homework', authenticate, authorize(['teacher']), crmController.assignHomework);
router.post('/homework/submit', authenticate, authorize(['student']), crmController.submitHomework);

module.exports = router;
