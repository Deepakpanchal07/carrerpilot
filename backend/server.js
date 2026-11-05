const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, ".env") });
require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const connectDB = require("./config/db");
const authRoutes = require("./routes/authRoutes");
const resumeRoutes = require("./routes/resumeRoutes");
const roadmapRoutes = require("./routes/roadmapRoutes");
const interviewRoutes = require("./routes/interviewRoutes");

const app = express();

// Security Headers
app.use(helmet());

// CORS Configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(",").map((o) => o.trim())
  : null;

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (e.g., mobile apps, curl, Postman)
      if (!origin) return callback(null, true);

      // If specific ALLOWED_ORIGINS are configured
      if (allowedOrigins && allowedOrigins.length > 0) {
        if (allowedOrigins.includes("*") || allowedOrigins.includes(origin)) {
          return callback(null, true);
        }
      }

      // Always permit local development hosts (Flutter Web & local tests)
      if (
        origin.startsWith("http://localhost") ||
        origin.startsWith("http://127.0.0.1")
      ) {
        return callback(null, true);
      }

      // Automatically permit all Vercel domains (preview & production deployments)
      if (origin.endsWith(".vercel.app") || origin.includes("vercel.app")) {
        return callback(null, true);
      }

      if (!allowedOrigins) {
        return callback(null, true);
      }

      return callback(new Error("Not allowed by CORS"));
    },
    credentials: true,
  })
);

app.use(express.json({ limit: "2mb" }));

// Welcome route
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Welcome to CareerPilot AI 🚀",
  });
});

// Health check route
app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "CareerPilot AI Backend is running",
  });
});

// API routes
app.use("/api/auth", authRoutes);
app.use("/api/resume", resumeRoutes);
app.use("/api/interview", interviewRoutes);
app.use("/api/roadmap", roadmapRoutes);

// Centralized JSON Error Handler
app.use((err, req, res, next) => {
  console.error("Global Error Handler:", err.message);

  if (err.name === "MulterError") {
    return res.status(400).json({
      success: false,
      message:
        err.code === "LIMIT_FILE_SIZE"
          ? "File size exceeds the 5MB limit"
          : err.message,
    });
  }

  const statusCode =
    err.statusCode || (res.statusCode >= 400 ? res.statusCode : 500);

  res.status(statusCode).json({
    success: false,
    message: err.message || "Internal Server Error",
  });
});

const startServer = async () => {
  const PORT = process.env.PORT || 5000;
  const HOST = "0.0.0.0";

  app.listen(PORT, HOST, () => {
    console.log(`🚀 CareerPilot AI Server is running on http://${HOST}:${PORT}`);

    // Report active email provider
    if (process.env.RESEND_API_KEY && process.env.RESEND_API_KEY.trim()) {
      console.log(`📧 Email Provider: Resend HTTP API (Render-ready over HTTPS 443)`);
    } else if (process.env.BREVO_API_KEY && process.env.BREVO_API_KEY.trim()) {
      console.log(`📧 Email Provider: Brevo HTTP API (Render-ready over HTTPS 443)`);
    } else if (process.env.SENDGRID_API_KEY && process.env.SENDGRID_API_KEY.trim()) {
      console.log(`📧 Email Provider: SendGrid HTTP API (Render-ready over HTTPS 443)`);
    } else if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
      console.log(
        `📧 Email Provider: SMTP (${process.env.EMAIL_USER.trim()}) ` +
        `[Note: Outbound SMTP ports 25/465/587 are blocked on Render free tier. Use RESEND_API_KEY for Render]`
      );
    } else {
      console.log(`📧 Email Provider: Render Console Fallback (OTPs printed directly in server logs)`);
    }
  });

  await connectDB();
};

startServer();
