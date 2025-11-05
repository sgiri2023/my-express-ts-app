import { useEffect, useState } from "react";
import { connectSocket, getSocket } from "./socket";

function App() {
  const [email, setEmail] = useState("");
  const [role, setRole] = useState("user");
  const [token, setToken] = useState("");
  const [message, setMessage] = useState("");
  const [messages, setMessages] = useState<string[]>([]);

  const handleLogin = async () => {
    const res = await fetch("http://localhost:5000/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, role }),
    });
    const data = await res.json();
    setToken(data.token);
  };

  useEffect(() => {
    if (!token) return;

    const socket = connectSocket(token);

    socket.on("message", (msg) => {
      setMessages((prev) => [...prev, msg]);
    });

    socket.on("connect", () => console.log("✅ Connected"));
    socket.on("connect_error", (err) => console.error("❌ Error:", err.message));

    return () => socket.disconnect();
  }, [token]);

  const sendToAll = () => {
    const socket = getSocket();
    if (socket && message.trim()) {
      socket.emit("message:all", message);
      setMessage("");
    }
  };

  const sendToAdmins = () => {
    const socket = getSocket();
    if (socket && message.trim()) {
      socket.emit("message:admin", message);
      setMessage("");
    }
  };

  return (
    <div style={{ padding: 20 }}>
      <h2>Socket.IO Room Chat</h2>

      {!token ? (
        <div>
          <input
            placeholder="Enter email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <select value={role} onChange={(e) => setRole(e.target.value)}>
            <option value="user">User</option>
            <option value="admin">Admin</option>
          </select>
          <button onClick={handleLogin}>Login</button>
        </div>
      ) : (
        <>
          <input
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Enter message"
          />
          <div>
            <button onClick={sendToAll}>Send to All</button>
            <button onClick={sendToAdmins}>Send to Admins</button>
          </div>

          <ul>
            {messages.map((m, i) => (
              <li key={i}>{m}</li>
            ))}
          </ul>
        </>
      )}
    </div>
  );
}

export default App;
