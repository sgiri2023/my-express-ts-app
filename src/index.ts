import express from "express";
import { AppDataSource } from "./data-source";
import bodyParser from "body-parser";
import userRoutes from "./routes/user.routes";
import UserGroupRoutes from "./routes/UserGroup.routes";
import UserGroupAccessRoutes from "./routes/UserGroupAccess.routes";
import userAuditLogRoutes from "./routes/userAuditLog.routes";
import cors from "cors";

const app = express();

// ✅ Allow CORS from frontend (Vite on port 5173)
app.use(
  cors({
    origin: "http://localhost:5173", // frontend URL
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true, // allow cookies/auth headers
  })
);

app.use(bodyParser.json());
app.use(express.json());

app.use("/api/users", userRoutes);
app.use("/api/audit-logs", userAuditLogRoutes);
app.use("/api/groups", UserGroupRoutes);
app.use("/api/user-group-access", UserGroupAccessRoutes);

AppDataSource.initialize()
  .then(() => {
    console.log("Data Source initialized");
    app.listen(8000, () =>
      console.log("Server running at http://localhost:8000")
    );
  })
  .catch((err) => console.error("Data Source initialization error:", err));
