import express from "express";
import { AppDataSource } from "./data-source";
import bodyParser from "body-parser";
import userRoutes from "./routes/user.routes";
import UserGroupRoutes from "./routes/UserGroup.routes";
import UserGroupAccessRoutes from "./routes/UserGroupAccess.routes";
import userAuditLogRoutes from "./routes/userAuditLog.routes";
import cors from "cors";
import axios from "axios";

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

const HMRC_TOKEN_URL = "https://test-api.service.hmrc.gov.uk/oauth/token";
const REDIRECT_URI = "http://localhost:5173/auth/callback";

/*
{
    "access_token": "ac94a5e34df01e40a0765e3e6798b2f4",
    "refresh_token": "4f6ad2775aab566ac7c93d107cfa9d23",
    "expires_in": 14400,
    "scope": "read:vat write:vat",
    "token_type": "bearer"
}
    */

app.post("/exchange-token", async (req, res) => {
  const { code } = req.body;

  
  try {
    const params = new URLSearchParams();
    params.append("grant_type", "authorization_code");
    params.append("client_id", "gdLG3pHZnYGeYGw2QayYLE2RnrTP");
    params.append("client_secret", "b8027830-543e-45ea-ad79-fda22662225b");
    params.append("redirect_uri", "http://localhost:5173/auth/callback");
    params.append("code", code);

    const response = await axios.post(
      "https://test-api.service.hmrc.gov.uk/oauth/token",
      params,
      { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
    );

    res.json(response.data); // Send tokens back to frontend
  } catch (error: any) {
    console.error("Exchange failed:", error.response?.data || error.message);
    res.status(400).json(error.response?.data || { error: "Token exchange failed" });
  }
});

// ===============================
// 2️⃣ Refresh access token
// ===============================
app.post("/refresh-token", async (req, res) => {
  const { refresh_token } = req.body;
console.log("Refresh token : ", refresh_token)
  if (!refresh_token)
    return res.status(400).json({ error: "Missing refresh token" });

  try {
    const params = new URLSearchParams();
    params.append("grant_type", "refresh_token");
    params.append("client_id", "gdLG3pHZnYGeYGw2QayYLE2RnrTP");
    params.append("client_secret", "b8027830-543e-45ea-ad79-fda22662225b");
    params.append("refresh_token", refresh_token);

    const response = await axios.post(HMRC_TOKEN_URL, params, {
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
    });

    console.log("Refreshed Token Response:", response.data);
    res.json(response.data);
  } catch (error: any) {
    console.error("Refresh token failed:", error.response?.data || error.message);
    res
      .status(400)
      .json(error.response?.data || { error: "Refresh token failed" });
  }
});

app.get("/hello-world", async (req, res) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) return res.status(401).json({ error: "Missing Authorization header" });

    // Extract token
    const token = authHeader.split(" ")[1]; // "Bearer <token>"

    const response = await axios.get(
      `https://test-api.service.hmrc.gov.uk/hello/world`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: "application/vnd.hmrc.1.0+json",
        },
      }
    );

    res.json(response.data);
  } catch (error: any) {
    console.error("HMRC API call failed:", error.response?.data || error.message);
    res.status(400).json({ error: "HMRC API call failed" });
  }
});

const HMRC_PILLAR2_URL =
  "https://test-api.service.hmrc.gov.uk/organisations/pillar-two/uk-tax-return";
const PILLAR2_ID = "XGPLR3661594135"; // X-Pillar2-Id header value

app.post("/pillar2/submit", async (req, res) => {
  const authHeader = req.headers.authorization;

    if (!authHeader) return res.status(401).json({ error: "Missing Authorization header" });

    // Extract token
    const token = authHeader.split(" ")[1]; // "Bearer <token>"
  try {
    // Build request payload
    const payload = {
      accountingPeriodFrom: "2024-01-01",
      accountingPeriodTo: "2024-12-31",
      obligationMTT: true,
      electionUKGAAP: false,
      liabilities: {
        returnType: "NIL_RETURN",
      },
    };

    const response = await axios.post(HMRC_PILLAR2_URL, payload, {
      headers: {
        Authorization: `Bearer ${token}`,
        "Accept": "application/vnd.hmrc.1.0+json",
        "Content-Type": "application/json",
        "X-Pillar2-Id": PILLAR2_ID, // required by HMRC
      },
    });

    console.log("Pillar Two Response:", response.data);
    res.json(response.data);
  } catch (error: any) {
    console.error(
      "HMRC Pillar 2 API call failed:",
      error.response?.data || error.message
    );
    res.status(400).json(error.response?.data || { error: "Pillar 2 API call failed" });
  }
});

// Create Pillar Two Test User
app.post("/api/create-test-user", async (req, res) => {
  const authHeader = req.headers.authorization;

    if (!authHeader) return res.status(401).json({ error: "Missing Authorization header" });

    // Extract token
    const token = authHeader.split(" ")[1]; // "Bearer <token>"

  try {
    const response = await axios.post(
      "https://test-api.service.hmrc.gov.uk/sandbox/test-users",
      {
        type: "organisation",
        services: ["VAT"], // change service if needed
      },
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
          Accept: "application/vnd.hmrc.1.0+json",
        },
      }
    );

    res.json(response.data); // includes userId, credentials, vrn, etc.
  } catch (err: any) {
    console.error("Create test user failed:", err.response?.data || err.message);
    res.status(400).json(err.response?.data || { error: "Failed to create test user" });
  }
});

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
