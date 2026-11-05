const multer = require("multer");
const path = require("path");

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const extension = path.extname(file.originalname || "").toLowerCase();
  const mimetype = (file.mimetype || "").toLowerCase();

  const isPdfExtension = extension === ".pdf";
  const isPdfMimetype =
    mimetype.includes("pdf") ||
    mimetype === "application/octet-stream" ||
    mimetype === "binary/octet-stream" ||
    mimetype === "";

  if (isPdfExtension || isPdfMimetype) {
    cb(null, true);
  } else {
    cb(new Error("Only valid PDF files are allowed"));
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB Limit
  },
});

const uploadPdf = (fieldName) => {
  const single = upload.single(fieldName);

  return (req, res, next) => {
    single(req, res, (err) => {
      if (err) {
        if (err instanceof multer.MulterError) {
          if (err.code === "LIMIT_FILE_SIZE") {
            return res.status(400).json({
              success: false,
              message: "File size exceeds the 5MB limit",
            });
          }
          return res.status(400).json({
            success: false,
            message: err.message,
          });
        }
        return res.status(400).json({
          success: false,
          message: err.message || "Invalid file upload",
        });
      }
      next();
    });
  };
};

module.exports = {
  upload,
  uploadPdf,
};
