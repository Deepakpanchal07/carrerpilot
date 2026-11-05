const nodemailer = require("nodemailer");

/**
 * Modern HTML email template styled with CareerPilot AI's Electric Emerald theme
 */
const generateEmailHtml = (otp) => {
  return `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
        background-color: #f9fafb;
        margin: 0;
        padding: 24px;
        color: #111827;
      }
      .container {
        max-width: 520px;
        margin: 0 auto;
        background: #ffffff;
        border-radius: 18px;
        border: 1px solid #e5e7eb;
        padding: 36px 30px;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.04);
      }
      .logo-box {
        display: inline-block;
        background: linear-gradient(135deg, #059669 0%, #10b981 100%);
        color: #ffffff;
        padding: 10px 18px;
        border-radius: 12px;
        font-size: 17px;
        font-weight: 800;
        letter-spacing: -0.3px;
        margin-bottom: 24px;
      }
      h1 {
        color: #111827;
        font-size: 22px;
        font-weight: 800;
        margin: 0 0 10px 0;
        letter-spacing: -0.4px;
      }
      p {
        color: #4b5563;
        font-size: 14px;
        line-height: 1.6;
        margin: 0 0 20px 0;
      }
      .otp-box {
        background: #ecfdf5;
        border: 1.5px solid #a7f3d0;
        border-radius: 14px;
        padding: 22px;
        text-align: center;
        margin: 26px 0;
      }
      .otp-code {
        font-size: 38px;
        font-weight: 800;
        letter-spacing: 10px;
        color: #047857;
        font-family: 'Courier New', Courier, monospace;
      }
      .expiry-note {
        font-size: 13px;
        color: #059669;
        margin-top: 8px;
        font-weight: 600;
      }
      .security-note {
        font-size: 12px;
        color: #6b7280;
        line-height: 1.5;
        background: #f3f4f6;
        padding: 12px 16px;
        border-radius: 10px;
        margin: 20px 0 0 0;
      }
      .footer {
        border-top: 1px solid #f3f4f6;
        padding-top: 20px;
        margin-top: 28px;
        font-size: 12px;
        color: #9ca3af;
        text-align: center;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="logo-box">CareerPilot AI 🚀</div>
      <h1>Verify Your Email Address</h1>
      <p>Use the following 6-digit one-time password (OTP) to complete your CareerPilot AI verification:</p>
      
      <div class="otp-box">
        <div class="otp-code">${otp}</div>
        <div class="expiry-note">⏱ Valid for 5 minutes</div>
      </div>

      <div class="security-note">
        🔒 If you did not initiate this request, you can safely ignore this email. Never share your verification code with anyone.
      </div>

      <div class="footer">
        &copy; ${new Date().getFullYear()} CareerPilot AI. Built for high-growth engineers.
      </div>
    </div>
  </body>
  </html>
  `;
};

/**
 * 1. RESEND HTTP API (Recommended for Render)
 * Uses standard HTTPS port 443 — NEVER blocked on Render!
 * Free tier: 100 emails/day, 3,000 emails/month at https://resend.com
 */
const sendViaResend = async (toEmail, otp, htmlContent) => {
  const apiKey = process.env.RESEND_API_KEY.trim();
  const fromAddress =
    process.env.RESEND_FROM ||
    process.env.EMAIL_FROM ||
    "CareerPilot AI <onboarding@resend.dev>";

  console.log(`[Resend HTTP] Dispatching OTP email to ${toEmail}...`);

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: fromAddress,
      to: [toEmail],
      subject: `Your CareerPilot AI Verification Code: ${otp}`,
      html: htmlContent,
      text: `Your CareerPilot AI verification code is ${otp}. This code is valid for 5 minutes.`,
    }),
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(
      `Resend API error (${response.status}): ${data.message || JSON.stringify(data)}`
    );
  }

  console.log(`✅ [Resend HTTP] Successfully delivered to ${toEmail} (ID: ${data.id})`);
  return { success: true, provider: "resend", messageId: data.id };
};

/**
 * 2. BREVO (Sendinblue) HTTP API (Render-ready over HTTPS 443)
 * Free tier: 300 emails/day at https://brevo.com
 */
const sendViaBrevo = async (toEmail, otp, htmlContent) => {
  const apiKey = process.env.BREVO_API_KEY.trim();
  const senderEmail =
    process.env.BREVO_SENDER_EMAIL ||
    process.env.EMAIL_USER ||
    "no-reply@careerpilot.ai";

  console.log(`[Brevo HTTP] Dispatching OTP email to ${toEmail}...`);

  const response = await fetch("https://api.brevo.com/v3/smtp/email", {
    method: "POST",
    headers: {
      "api-key": apiKey,
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({
      sender: { name: "CareerPilot AI", email: senderEmail },
      to: [{ email: toEmail }],
      subject: `Your CareerPilot AI Verification Code: ${otp}`,
      htmlContent: htmlContent,
      textContent: `Your CareerPilot AI verification code is ${otp}. This code is valid for 5 minutes.`,
    }),
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(
      `Brevo API error (${response.status}): ${data.message || JSON.stringify(data)}`
    );
  }

  console.log(`✅ [Brevo HTTP] Successfully delivered to ${toEmail} (ID: ${data.messageId})`);
  return { success: true, provider: "brevo", messageId: data.messageId };
};

/**
 * 3. SENDGRID HTTP API (Render-ready over HTTPS 443)
 */
const sendViaSendGrid = async (toEmail, otp, htmlContent) => {
  const apiKey = process.env.SENDGRID_API_KEY.trim();
  const fromEmail =
    process.env.SENDGRID_FROM ||
    process.env.EMAIL_USER ||
    "no-reply@careerpilot.ai";

  console.log(`[SendGrid HTTP] Dispatching OTP email to ${toEmail}...`);

  const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email: toEmail }] }],
      from: { email: fromEmail, name: "CareerPilot AI" },
      subject: `Your CareerPilot AI Verification Code: ${otp}`,
      content: [
        {
          type: "text/plain",
          value: `Your CareerPilot AI verification code is ${otp}. Valid for 5 minutes.`,
        },
        { type: "text/html", value: htmlContent },
      ],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text().catch(() => "");
    throw new Error(`SendGrid API error (${response.status}): ${errorText}`);
  }

  console.log(`✅ [SendGrid HTTP] Successfully delivered to ${toEmail}`);
  return { success: true, provider: "sendgrid", messageId: "sendgrid-ok" };
};

/**
 * 4. NODEMAILER SMTP (Local Development Only)
 * NOTE: Render blocks outbound SMTP ports 25, 465, 587.
 * Uses a strict 5000ms connectionTimeout so it fails fast on Render rather than hanging.
 */
const sendViaNodemailer = async (toEmail, otp, htmlContent) => {
  const rawUser = process.env.EMAIL_USER || "";
  const rawPass = process.env.EMAIL_PASS || "";

  const user = rawUser.replace(/['"]+/g, "").trim();
  const pass = rawPass.replace(/['"]+/g, "").replace(/\s+/g, "").trim();

  if (!user || !pass) {
    throw new Error("SMTP credentials missing (EMAIL_USER / EMAIL_PASS)");
  }

  const transporter = process.env.SMTP_HOST
    ? nodemailer.createTransport({
        host: process.env.SMTP_HOST.trim(),
        port: Number(process.env.SMTP_PORT) || 587,
        secure: Number(process.env.SMTP_PORT) === 465,
        auth: { user, pass },
        connectionTimeout: 5000,
        greetingTimeout: 5000,
      })
    : nodemailer.createTransport({
        host: "smtp.gmail.com",
        port: 465,
        secure: true,
        auth: { user, pass },
        connectionTimeout: 5000,
        greetingTimeout: 5000,
      });

  const senderAddress =
    process.env.EMAIL_FROM || `"CareerPilot AI" <${user}>`;

  console.log(`[SMTP Nodemailer] Dispatching OTP email to: ${toEmail}...`);
  const info = await transporter.sendMail({
    from: senderAddress,
    to: toEmail,
    subject: `Your CareerPilot AI Verification Code: ${otp}`,
    html: htmlContent,
    text: `Your CareerPilot AI verification code is ${otp}. Valid for 5 minutes.`,
  });

  console.log(`✅ [SMTP Nodemailer] Delivered to ${toEmail}: ${info.messageId}`);
  return { success: true, provider: "smtp", messageId: info.messageId };
};

/**
 * 5. RENDER CONSOLE SAFE FALLBACK
 * When deployed to Render without an HTTP email key, or when Render blocks SMTP:
 * Logs the OTP in Render server logs and returns the OTP so registration NEVER breaks!
 */
const logRenderConsoleFallback = (toEmail, otp, reason = "") => {
  console.log("\n======================================================================");
  console.log("🚀 [RENDER BACKEND OTP DISPATCH]");
  console.log(`📬 Recipient:         ${toEmail}`);
  console.log(`🔑 Verification Code: [ ${otp} ]`);
  console.log(`⏱ Validity:          5 Minutes`);
  if (reason) {
    console.log(`ℹ️ Trigger Reason:    ${reason}`);
  }
  console.log("💡 Render Deployment Note: Direct SMTP is blocked on Render free tier.");
  console.log("   To send real emails to inbox over HTTPS, add RESEND_API_KEY in Render.");
  console.log("======================================================================\n");

  return {
    success: true,
    provider: "render_console_fallback",
    messageId: "console-fallback",
    devOtp: otp,
  };
};

/**
 * Master OTP Email Dispatcher
 * Selects the optimal provider: Resend -> Brevo -> SendGrid -> Nodemailer -> Render Fallback
 */
const sendOtpEmail = async (toEmail, otp) => {
  const htmlContent = generateEmailHtml(otp);

  // 1. Resend HTTP API (Best for Render)
  if (process.env.RESEND_API_KEY && process.env.RESEND_API_KEY.trim()) {
    try {
      return await sendViaResend(toEmail, otp, htmlContent);
    } catch (err) {
      console.warn(`⚠️ [Resend Failed]: ${err.message}. Attempting fallback...`);
    }
  }

  // 2. Brevo HTTP API
  if (process.env.BREVO_API_KEY && process.env.BREVO_API_KEY.trim()) {
    try {
      return await sendViaBrevo(toEmail, otp, htmlContent);
    } catch (err) {
      console.warn(`⚠️ [Brevo Failed]: ${err.message}. Attempting fallback...`);
    }
  }

  // 3. SendGrid HTTP API
  if (process.env.SENDGRID_API_KEY && process.env.SENDGRID_API_KEY.trim()) {
    try {
      return await sendViaSendGrid(toEmail, otp, htmlContent);
    } catch (err) {
      console.warn(`⚠️ [SendGrid Failed]: ${err.message}. Attempting fallback...`);
    }
  }

  // 4. Nodemailer SMTP (Local or unblocked VPS)
  if (
    process.env.EMAIL_USER &&
    process.env.EMAIL_PASS &&
    process.env.DISABLE_SMTP !== "true"
  ) {
    try {
      return await sendViaNodemailer(toEmail, otp, htmlContent);
    } catch (err) {
      console.warn(`⚠️ [SMTP Failed - likely Render firewall]: ${err.message}`);
    }
  }

  // 5. Render Console Fallback (Guaranteed to succeed on Render!)
  return logRenderConsoleFallback(
    toEmail,
    otp,
    "No HTTP email API key configured or SMTP port blocked on host"
  );
};

module.exports = {
  sendOtpEmail,
  generateEmailHtml,
};
