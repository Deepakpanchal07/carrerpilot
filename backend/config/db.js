const mongoose = require("mongoose");

const connectDB = async () => {
  try {
    if (!process.env.MONGO_URI) {
      throw new Error("MONGO_URI environment variable is not defined in .env");
    }

    const uri = process.env.MONGO_URI.trim();
    const isAtlas = uri.startsWith("mongodb+srv://") || uri.includes("mongodb.net");

    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 8000,
    });

    console.log(`✅ MongoDB Connected: ${conn.connection.host} (${isAtlas ? "Atlas Cloud ☁️" : "Local Compass 💻"})`);
    console.log(`🗄️ Database: ${conn.connection.name}`);
    return conn;
  } catch (error) {
    console.error(`❌ Database Connection Error: ${error.message}`);
    const isAtlas = (process.env.MONGO_URI || "").includes("mongodb.net");
    if (isAtlas) {
      console.error("💡 Atlas Tip: Make sure your IP is whitelisted in Atlas (Network Access -> Allow 0.0.0.0/0) and user credentials are valid.");
    } else {
      console.error("💡 Local Tip: Ensure MongoDB service is running (net start MongoDB) or update MONGO_URI in backend/.env to your Atlas connection string.");
    }
    return null;
  }
};

module.exports = connectDB;
