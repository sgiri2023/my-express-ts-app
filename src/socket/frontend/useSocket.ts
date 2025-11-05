// src/hooks/useSocket.ts
import { useEffect, useState } from "react";
import { createSocketConnection, getSocket } from "../socket";
import { Socket } from "socket.io-client";

interface UseSocketReturn {
  messages: string[];
  sendToAll: (msg: string) => void;
  sendToAdmins: (msg: string) => void;
  connected: boolean;
}

export const useSocket = (token: string | null): UseSocketReturn => {
  const [messages, setMessages] = useState<string[]>([]);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    if (!token) return;

    const socket: Socket = createSocketConnection(token);

    socket.on("connect", () => {
      console.log("✅ Connected:", socket.id);
      setConnected(true);
    });

    socket.on("disconnect", () => {
      console.log("⚠️ Disconnected");
      setConnected(false);
    });

    socket.on("message", (msg: string) => {
      setMessages((prev) => [...prev, msg]);
    });

    socket.on("connect_error", (err) => {
      console.error("❌ Connection error:", err.message);
    });

    return () => {
      socket.off("message");
      socket.disconnect();
      setConnected(false);
    };
  }, [token]);

  const sendToAll = (msg: string) => {
    const socket = getSocket();
    if (socket && msg.trim()) {
      socket.emit("message:all", msg);
    }
  };

  const sendToAdmins = (msg: string) => {
    const socket = getSocket();
    if (socket && msg.trim()) {
      socket.emit("message:admin", msg);
    }
  };

  return { messages, sendToAll, sendToAdmins, connected };
};
