const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, ".env") });
const nodemailer = require("nodemailer");

async function testEmail() {
  const user = process.env.EMAIL_USER ? process.env.EMAIL_USER.replace(/['"]/g, '').trim() : null;
  const pass = process.env.EMAIL_PASS ? process.env.EMAIL_PASS.replace(/['"]/g, '').trim().replace(/\s+/g, '') : null;

  console.log("Testing with User:", user);
  console.log("Testing with Pass length:", pass ? pass.length : 0);

  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: user,
      pass: pass,
    },
  });

  try {
    const verified = await transporter.verify();
    console.log("Transporter verification:", verified);

    const info = await transporter.sendMail({
      from: `"CareerPilot AI" <${user}>`,
      to: user,
      subject: "Test OTP from CareerPilot AI",
      text: "Your test OTP code is: 123456",
    });

    console.log("Email sent successfully! Message ID:", info.messageId);
  } catch (error) {
    console.error("Transporter Error:", error);
  }
}

testEmail();

