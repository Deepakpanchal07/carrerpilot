const { generateLearningRoadmap } = require("../services/geminiService");

const VALID_SKILL_LEVELS = ["Beginner", "Intermediate", "Advanced"];

const createLearningRoadmap = async (req, res) => {
  try {
    const { jobRole, skillLevel, dailyStudyHours } = req.body;

    if (!jobRole || typeof jobRole !== "string" || !jobRole.trim()) {
      return res.status(400).json({
        success: false,
        message: "Job role is required and must be a valid text string",
      });
    }

    if (jobRole.trim().length > 100) {
      return res.status(400).json({
        success: false,
        message: "Job role exceeds maximum length of 100 characters",
      });
    }

    if (!skillLevel || !VALID_SKILL_LEVELS.includes(skillLevel)) {
      return res.status(400).json({
        success: false,
        message: `Skill level must be one of: ${VALID_SKILL_LEVELS.join(", ")}`,
      });
    }

    const hours = Number(dailyStudyHours);
    if (isNaN(hours) || hours <= 0 || hours > 24) {
      return res.status(400).json({
        success: false,
        message: "Daily study hours must be a positive number between 1 and 24",
      });
    }

    const roadmap = await generateLearningRoadmap(
      jobRole.trim(),
      skillLevel,
      hours
    );

    return res.status(200).json({
      success: true,
      roadmap,
    });
  } catch (error) {
    console.error("Roadmap Controller Error:", error.message);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to generate learning roadmap",
    });
  }
};

module.exports = { createLearningRoadmap };
