// src/context/SocketContext.tsx
import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { useSelector } from "react-redux";
import {
  createSocketConnection,
  getSocket,
  disconnectSocket,
  reconnectWithNewToken,
} from "../socket";
import { Socket } from "socket.io-client";
import { RootState } from "../store"; // adjust if your root state file has another name

interface SocketContextType {
  socket: Socket | null;
  connected: boolean;
  messages: string[];
  sendToAll: (msg: string) => void;
  sendToAdmins: (msg: string) => void;
}

const SocketContext = createContext<SocketContextType | undefined>(undefined);

export const SocketProvider = ({ children }: { children: ReactNode }) => {
  const token = useSelector((state: RootState) => state.auth.token);
  const [socket, setSocket] = useState<Socket | null>(null);
  const [connected, setConnected] = useState(false);
  const [messages, setMessages] = useState<string[]>([]);

  useEffect(() => {
    if (!token) {
      disconnectSocket();
      setSocket(null);
      return;
    }

    let currentSocket: Socket;
    const existingSocket = getSocket();

    if (existingSocket && existingSocket.connected) {
      reconnectWithNewToken(token);
      currentSocket = existingSocket;
    } else {
      currentSocket = createSocketConnection(token);
    }

    setSocket(currentSocket);

    currentSocket.on("connect", () => {
      console.log("✅ Connected:", currentSocket.id);
      setConnected(true);
    });

    currentSocket.on("disconnect", () => {
      console.log("⚠️ Disconnected");
      setConnected(false);
    });

    currentSocket.on("message", (msg: string) => {
      setMessages((prev) => [...prev, msg]);
    });

    currentSocket.on("connect_error", (err) => {
      console.error("❌ Connection error:", err.message);
    });

    return () => {
      currentSocket.off("message");
      currentSocket.off("connect");
      currentSocket.off("disconnect");
    };
  }, [token]);

  const sendToAll = (msg: string) => {
    const s = getSocket();
    if (s && msg.trim()) s.emit("message:all", msg);
  };

  const sendToAdmins = (msg: string) => {
    const s = getSocket();
    if (s && msg.trim()) s.emit("message:admin", msg);
  };

  return (
    <SocketContext.Provider
      value={{ socket, connected, messages, sendToAll, sendToAdmins }}
    >
      {children}
    </SocketContext.Provider>
  );
};

export const useSocketContext = () => {
  const ctx = useContext(SocketContext);
  if (!ctx) throw new Error("useSocketContext must be used inside <SocketProvider>");
  return ctx;
};
