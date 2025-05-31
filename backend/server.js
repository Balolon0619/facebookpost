const express = require("express");
const mysql = require("mysql2");
const multer = require("multer");
const cors = require("cors");
const path = require("path");
const moment = require("moment-timezone");

const app = express();
const port = 3000;

app.use(cors());
app.use("/uploads", express.static("uploads")); // serve uploaded images

const db = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "", // replace with your MySQL password
  database: "fbpostingyaw",
});

db.connect((err) => {
  if (err) throw err;
  console.log("Connected to MySQL");
});

// Create table (override the timestamp default)
db.query(`
  CREATE TABLE IF NOT EXISTS posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    image VARCHAR(255),
    subtext TEXT,
    created_at DATETIME
  );
`);

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "./uploads/");
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});

const upload = multer({ storage: storage });

// POST endpoint: create post
app.post("/api/posts", upload.single("image"), (req, res) => {
  const { subtext } = req.body;
  const image = req.file ? req.file.filename : "";
  const createdAt = moment().tz("Asia/Manila").format("YYYY-MM-DD HH:mm:ss");

  const query = "INSERT INTO posts (image, subtext, created_at) VALUES (?, ?, ?)";
  db.query(query, [image, subtext, createdAt], (err, result) => {
    if (err) {
      console.error("Insert error:", err);
      res.status(500).json({ message: "Error posting the image." });
    } else {
      res.status(200).json({ message: "Post created successfully!" });
    }
  });
});

// GET endpoint: retrieve all posts
app.get("/api/posts", (req, res) => {
  db.query("SELECT * FROM posts ORDER BY created_at DESC", (err, results) => {
    if (err) {
      console.error("Fetch error:", err);
      res.status(500).json({ message: "Error retrieving posts." });
    } else {
      res.status(200).json(results);
    }
  });
});

// Start server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
