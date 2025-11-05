import express from "express";
import http from "http";
import cors from "cors";
import jwt from "jsonwebtoken";
import { initSocket, getIO } from "./socket";

const app = express();
app.use(cors());
app.use(express.json());

const JWT_SECRET = "your_secret_key";

// 🧾 Simple login route
app.post("/login", (req, res) => {
  const { email, role } = req.body;
  const token = jwt.sign({ userId: Date.now().toString(), email, role }, JWT_SECRET);
  res.json({ token });
});

// 🚀 API to send message to a room (like "admin" or "user")
app.post("/send-message", (req, res) => {
  const { room, message } = req.body;
  const io = getIO();

  if (!room || !message) {
    return res.status(400).json({ error: "room and message are required" });
  }

  io.to(room).emit("message", `📨 [From API → ${room}] ${message}`);
  console.log(`📤 Message sent to room '${room}': ${message}`);

  return res.status(200).json({ success: true, message: `Sent to ${room}` });
});

const server = http.createServer(app);
initSocket(server);

server.listen(5000, () =>
  console.log("🚀 Server running on http://localhost:5000")
);
