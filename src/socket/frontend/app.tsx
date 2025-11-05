// src/App.tsx
import { useState } from "react";
import { useSocket } from "./hooks/useSocket";

function App() {
  const [email, setEmail] = useState("");
  const [role, setRole] = useState("user");
  const [token, setToken] = useState<string | null>(null);
  const [message, setMessage] = useState("");

  const { messages, sendToAll, sendToAdmins, connected } = useSocket(token);

  const handleLogin = async () => {
    const res = await fetch("http://localhost:5000/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, role }),
    });
    const data = await res.json();
    setToken(data.token);
  };

  const handleSendAll = () => {
    if (message.trim()) {
      sendToAll(message);
      setMessage("");
    }
  };

  const handleSendAdmins = () => {
    if (message.trim()) {
      sendToAdmins(message);
      setMessage("");
    }
  };

  return (
    <div
      style={{
        padding: 20,
        maxWidth: 500,
        margin: "0 auto",
        fontFamily: "Arial, sans-serif",
      }}
    >
      <h2>⚡ Socket.IO Chat (Hook Version)</h2>

      {!token ? (
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
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
          <p>
            Status:{" "}
            <strong style={{ color: connected ? "green" : "red" }}>
              {connected ? "Connected" : "Disconnected"}
            </strong>
          </p>

          <div style={{ marginTop: 20 }}>
            <input
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Enter message"
              style={{ width: "70%", marginRight: 10 }}
            />
            <button onClick={handleSendAll}>Send to All</button>
            <button onClick={handleSendAdmins} style={{ marginLeft: 10 }}>
              Send to Admins
            </button>
          </div>

          <div style={{ marginTop: 30 }}>
            <h3>📨 Messages</h3>
            <ul style={{ listStyle: "none", paddingLeft: 0 }}>
              {messages.map((m, i) => (
                <li
                  key={i}
                  style={{
                    background: "#f3f3f3",
                    margin: "5px 0",
                    padding: 5,
                  }}
                >
                  {m}
                </li>
              ))}
            </ul>
          </div>
        </>
      )}
    </div>
  );
}

export default App;
