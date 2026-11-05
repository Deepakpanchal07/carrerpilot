const {
  generateInterviewQuestion,
} = require("../services/geminiService");

const startInterviewController = async (req, res) => {
  try {
    const { jobRole, previousAnswers = [] } = req.body;

    // Validate job role
    if (!jobRole || typeof jobRole !== "string" || !jobRole.trim()) {
      return res.status(400).json({
        success: false,
        message: "Job role is required and must be a valid text string.",
      });
    }

    if (jobRole.trim().length > 100) {
      return res.status(400).json({
        success: false,
        message: "Job role exceeds maximum length of 100 characters.",
      });
    }

    // Validate interview history
    if (!Array.isArray(previousAnswers)) {
      return res.status(400).json({
        success: false,
        message: "Invalid interview history: must be an array.",
      });
    }

    if (previousAnswers.length > 20) {
      return res.status(400).json({
        success: false,
        message: "Interview history exceeds maximum allowed rounds (20).",
      });
    }

    for (let i = 0; i < previousAnswers.length; i++) {
      const item = previousAnswers[i];
      if (
        !item ||
        typeof item !== "object" ||
        typeof item.question !== "string" ||
        typeof item.answer !== "string"
      ) {
        return res.status(400).json({
          success: false,
          message: `Invalid format in interview history round ${i + 1}.`,
        });
      }
      if (item.answer.length > 5000 || item.question.length > 2000) {
        return res.status(400).json({
          success: false,
          message: `Interview answer or question is too long in round ${i + 1}.`,
        });
      }
    }

    // Generate AI interview response
    const result = await generateInterviewQuestion(
      jobRole.trim(),
      previousAnswers
    );

    return res.status(200).json({
      success: true,
      message: "Interview response generated successfully.",
      data: {
        result,
      },
    });
  } catch (error) {
    console.error("Interview Controller Error:", error.message);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to generate interview response.",
    });
  }
};

module.exports = {
  startInterviewController,
};
