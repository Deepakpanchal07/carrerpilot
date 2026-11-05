const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { startInterviewController } = require('../controllers/interviewController');

router.post('/start', protect, startInterviewController);

module.exports = router;
