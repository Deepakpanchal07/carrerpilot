const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, ".env") });
require("dotenv").config();
const mongoose = require("mongoose");

async function testAtlasConnection() {
  const uri = process.env.MONGO_URI;

  console.log("\n==================================================");
  console.log("🔍 Testing MongoDB Connection...");
  console.log("==================================================");

  if (!uri) {
    console.error("❌ Error: MONGO_URI is missing in backend/.env");
    process.exit(1);
  }

  // Hide password in console output for privacy
  const maskedUri = uri.replace(/:([^:@]+)@/, ":****@");
  console.log(`📡 Connecting to: ${maskedUri}`);

  const isAtlas = uri.startsWith("mongodb+srv://") || uri.includes("mongodb.net");
  console.log(`🌐 Target: ${isAtlas ? "MongoDB Atlas (Cloud ☁️)" : "Local MongoDB (Compass 💻)"}`);

  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 8000,
    });

    console.log("\n✅ SUCCESS! MongoDB Connected Successfully!");
    console.log(`🏢 Cluster Host:    ${conn.connection.host}`);
    console.log(`🗄️ Database Name:   ${conn.connection.name}`);
    console.log(`🔌 Connection State: Connected (Ready State: ${conn.connection.readyState})`);

    // List collections
    const collections = await conn.connection.db.listCollections().toArray();
    console.log(`📁 Collections in DB (${collections.length}):`);
    collections.forEach((c) => console.log(`   - ${c.name}`));

    console.log("\n==================================================");
    console.log("🎉 Atlas is fully ready for local use and Render deployment!");
    console.log("==================================================\n");

    await mongoose.disconnect();
    process.exit(0);
  } catch (error) {
    console.error("\n❌ CONNECTION FAILED:", error.message);
    console.log("\n🛠️ Troubleshooting Tips for MongoDB Atlas:");
    if (error.message.includes("bad auth") || error.message.includes("Authentication failed")) {
      console.log("👉 1. Check your Database User password in backend/.env.");
      console.log("      Ensure special characters in password are URL-encoded if needed.");
    } else if (error.message.includes("querySrv") || error.message.includes("ENOTFOUND")) {
      console.log("👉 1. Check your Cluster URL. It should end with .mongodb.net");
    } else {
      console.log("👉 1. IP Whitelist: Go to MongoDB Atlas -> 'Network Access'");
      console.log("      Click 'Add IP Address' -> Select 'Allow Access from Anywhere' (0.0.0.0/0)");
      console.log("👉 2. Database User: Ensure the user has 'Read and write to any database' role.");
    }
    console.log("==================================================\n");
    process.exit(1);
  }
}

testAtlasConnection();

