// src/socket.ts
import { io, Socket } from "socket.io-client";

let socket: Socket | null = null;

export const createSocketConnection = (token: string): Socket => {
  socket = io("http://localhost:5000", {
    transports: ["websocket"],
    autoConnect: true,
    auth: { token }, // ✅ send token during handshake
  });

  return socket;
};

export const getSocket = (): Socket | null => socket;
