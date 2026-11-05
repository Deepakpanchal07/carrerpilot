const express = require("express");
const router = express.Router();

const { uploadPdf } = require("../middleware/uploadMiddleware");
const { protect } = require("../middleware/authMiddleware");

const {
  analyzeResumeController,
  matchResumeController,
} = require("../controllers/resumeController");

// Resume Analyzer
router.post(
  "/analyze",
  protect,
  uploadPdf("resume"),
  analyzeResumeController
);

// Job Description Matcher
router.post(
  "/match",
  protect,
  uploadPdf("resume"),
  matchResumeController
);

module.exports = router;
