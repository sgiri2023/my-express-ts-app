import { Server } from "socket.io";
import { Server as HTTPServer } from "http";
import jwt from "jsonwebtoken";

interface JwtPayload {
  userId: string;
  email: string;
  role: "admin" | "user";
}

const JWT_SECRET = "your_secret_key";

let io: Server;

export const initSocket = (server: HTTPServer) => {
  io = new Server(server, {
    cors: {
      origin: "http://localhost:5173",
      methods: ["GET", "POST"],
    },
  });

  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) return next(new Error("No token"));
      const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload;
      (socket as any).user = decoded;
      next();
    } catch {
      next(new Error("Authentication failed"));
    }
  });

  io.on("connection", (socket) => {
    const user = (socket as any).user as JwtPayload;
    console.log(`🟢 ${user.email} connected (${user.role})`);
    socket.join(user.role);

    socket.on("message:all", (msg) => io.emit("message", `${user.email}: ${msg}`));
    socket.on("message:admin", (msg) =>
      io.to("admin").emit("message", `📢 [To Admin] ${user.email}: ${msg}`)
    );

    socket.on("disconnect", () => {
      console.log(`🔴 ${user.email} disconnected`);
    });
  });

  return io;
};

export const getIO = () => io;
