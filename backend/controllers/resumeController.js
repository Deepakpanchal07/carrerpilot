const pdf = require("pdf-parse");

const {
  analyzeResume,
  matchResumeWithJob,
} = require("../services/geminiService");

const isMagicPdf = (buffer) => {
  if (!buffer || buffer.length < 4) return false;
  // Per PDF spec ISO 32000-1, %PDF- can appear anywhere within the first 1024 bytes
  const header = buffer.slice(0, Math.min(buffer.length, 1024)).toString("latin1");
  return header.includes("%PDF");
};

// RESUME ANALYZER
const analyzeResumeController = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "No file uploaded",
      });
    }

    if (!isMagicPdf(req.file.buffer)) {
      return res.status(400).json({
        success: false,
        message: "Uploaded file is corrupted or not a valid PDF document",
      });
    }

    const pdfData = await pdf(req.file.buffer);
    const resumeText = pdfData.text ? pdfData.text.trim() : "";

    if (!resumeText) {
      return res.status(400).json({
        success: false,
        message: "Uploaded PDF is empty or unreadable",
      });
    }

    const analysis = await analyzeResume(resumeText);

    return res.status(200).json({
      success: true,
      message: "Resume analyzed successfully",
      data: { analysis },
    });
  } catch (error) {
    console.error("Resume Controller Error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to analyze resume",
    });
  }
};

// JOB DESCRIPTION MATCHER
const matchResumeController = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Please upload your resume PDF",
      });
    }

    if (!isMagicPdf(req.file.buffer)) {
      return res.status(400).json({
        success: false,
        message: "Uploaded file is corrupted or not a valid PDF document",
      });
    }

    const { jobDescription } = req.body;

    if (!jobDescription || typeof jobDescription !== "string" || !jobDescription.trim()) {
      return res.status(400).json({
        success: false,
        message: "Please provide a valid job description",
      });
    }

    if (jobDescription.trim().length > 20000) {
      return res.status(400).json({
        success: false,
        message: "Job description is too long (maximum 20,000 characters allowed)",
      });
    }

    const pdfData = await pdf(req.file.buffer);
    const resumeText = pdfData.text ? pdfData.text.trim() : "";

    if (!resumeText) {
      return res.status(400).json({
        success: false,
        message: "Uploaded PDF is empty or unreadable",
      });
    }

    const matchingResult = await matchResumeWithJob(
      resumeText,
      jobDescription.trim()
    );

    return res.status(200).json({
      success: true,
      message: "Job matching completed successfully",
      data: {
        matchingResult,
      },
    });
  } catch (error) {
    console.error("Job Matching Controller Error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to match resume",
    });
  }
};

module.exports = {
  analyzeResumeController,
  matchResumeController,
};
