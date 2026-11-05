const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { createLearningRoadmap } = require('../controllers/roadmapController');

router.post('/generate', protect, createLearningRoadmap);

module.exports = router;
