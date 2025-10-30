# 🔐 OAuth 2.0 Flow with Microsoft Entra ID (Azure AD)

## 🗾️ Overview

Microsoft Entra ID (formerly Azure Active Directory) implements **OAuth 2.0 and OpenID Connect** to authorize apps to access Microsoft APIs or your own protected APIs.

This documentation explains how to implement the **Authorization Code Flow** for server-side web apps and APIs.

---

## ⚙️ Components

| Role | Description |
|------|--------------|
| **App (Client)** | Your application registered in Entra ID |
| **Authorization Server** | Microsoft Entra ID (e.g. `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/authorize`) |
| **Resource API** | Microsoft Graph or your custom API |
| **User / Resource Owner** | The person logging in and granting permissions |

---

## 🧱 OAuth Flow Overview

```
+------------+       +------------------+        +-----------------+
|  User/App  |  ->   |  Entra ID Auth   |  ->    |  Token Endpoint |
|            |       |  (Authorize URL) |        |  (Token URL)    |
+------------+       +------------------+        +-----------------+
         |                      |                        |
         v                      v                        v
    User Login         Authorization Code         Access + Refresh Token
```

---

## 🪪 Step 1: Register Your App in Entra ID

1. Go to **Entra ID → App registrations → New registration**
2. Note your:
   - **Application (client) ID**
   - **Directory (tenant) ID**
   - **Redirect URI** (e.g., `https://yourapp.com/auth/callback`)
3. Under **Certificates & secrets**, create a **Client Secret**.

---

## 🌐 Step 2: Get Authorization Code

Your app redirects users to Entra ID for sign-in.

### **Endpoint**
```
GET https://login.microsoftonline.com/{tenant}/oauth2/v2.0/authorize
```

### **Query Parameters**

| Parameter | Description |
|------------|-------------|
| `client_id` | Your App (Client) ID |
| `response_type` | `code` |
| `redirect_uri` | Must match your registered URI |
| `response_mode` | `query` or `form_post` |
| `scope` | Scopes requested (e.g., `User.Read offline_access`) |
| `state` | Random string to protect against CSRF |

### **Example Request**
```bash
GET https://login.microsoftonline.com/contoso.onmicrosoft.com/oauth2/v2.0/authorize?
client_id=11111111-2222-3333-4444-555555555555&
response_type=code&
redirect_uri=https://yourapp.com/auth/callback&
response_mode=query&
scope=User.Read offline_access&
state=12345
```

### **User Login & Consent**
- The user logs in to their Microsoft account.
- They grant the requested permissions.
- The browser redirects to your redirect URI with a code:

```
https://yourapp.com/auth/callback?code=AUTH_CODE_ABC&state=12345
```

---

## 🔑 Step 3: Exchange Authorization Code for Token

### **Endpoint**
```
POST https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token
```

### **Headers**
```
Content-Type: application/x-www-form-urlencoded
```

### **Body Parameters**

| Parameter | Description |
|------------|-------------|
| `client_id` | Your App (Client) ID |
| `scope` | Same as used in authorization request |
| `code` | Authorization code from previous step |
| `redirect_uri` | Same redirect URI |
| `grant_type` | `authorization_code` |
| `client_secret` | Your app’s client secret |

### **Example Request**
```bash
POST https://login.microsoftonline.com/contoso.onmicrosoft.com/oauth2/v2.0/token
Content-Type: application/x-www-form-urlencoded

client_id=11111111-2222-3333-4444-555555555555&
scope=User.Read offline_access&
code=AUTH_CODE_ABC&
redirect_uri=https://yourapp.com/auth/callback&
grant_type=authorization_code&
client_secret=SECRET_VALUE
```

### **Example Response**
```json
{
  "token_type": "Bearer",
  "scope": "User.Read",
  "expires_in": 3600,
  "ext_expires_in": 3600,
  "access_token": "ACCESS_TOKEN_123",
  "refresh_token": "REFRESH_TOKEN_456",
  "id_token": "eyJ0eXAiOiJKV1QiLCJhbGci..."
}
```

---

## ⚡ Step 4: Call Microsoft Graph or Custom API

Use the **Access Token** in the `Authorization` header to call APIs.

### **Example: Get User Profile**
```
GET https://graph.microsoft.com/v1.0/me
```

### **Headers**
```
Authorization: Bearer ACCESS_TOKEN_123
```

### **Example Response**
```json
{
  "displayName": "Sumit Giri",
  "jobTitle": "Software Engineer",
  "mail": "sumit@contoso.com",
  "id": "abcd1234"
}
```

---

## 🔄 Step 5: Refresh Access Token

When the access token expires (typically after 1 hour), you can request a new one using the **refresh token**.

### **Endpoint**
```
POST https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token
```

### **Body Parameters**

| Parameter | Description |
|------------|-------------|
| `grant_type` | `refresh_token` |
| `client_id` | Your client ID |
| `client_secret` | Your client secret |
| `refresh_token` | The refresh token |
| `scope` | Same as before |

### **Example Request**
```bash
POST https://login.microsoftonline.com/contoso.onmicrosoft.com/oauth2/v2.0/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&
client_id=11111111-2222-3333-4444-555555555555&
client_secret=SECRET_VALUE&
refresh_token=REFRESH_TOKEN_456&
scope=User.Read offline_access
```

### **Example Response**
```json
{
  "access_token": "NEW_ACCESS_TOKEN_789",
  "refresh_token": "NEW_REFRESH_TOKEN_999",
  "expires_in": 3600
}
```

---

## 🧱 Example Endpoints for Your Backend

| Endpoint | Description |
|-----------|--------------|
| `/auth/login` | Redirects to Entra ID authorization endpoint |
| `/auth/callback` | Handles redirect and exchanges code for tokens |
| `/auth/refresh` | Refreshes access token |
| `/api/user` | Calls Microsoft Graph `/me` using access token |

---

## 🧮 Example Node.js Implementation

```js
import express from "express";
import axios from "axios";
const app = express();

const CLIENT_ID = "11111111-2222-3333-4444-555555555555";
const CLIENT_SECRET = "SECRET_VALUE";
const TENANT_ID = "contoso.onmicrosoft.com";
const REDIRECT_URI = "https://yourapp.com/auth/callback";
const SCOPE = "User.Read offline_access";

app.get("/auth/login", (req, res) => {
  const url = `https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/authorize?client_id=${CLIENT_ID}&response_type=code&redirect_uri=${REDIRECT_URI}&response_mode=query&scope=${SCOPE}&state=12345`;
  res.redirect(url);
});

app.get("/auth/callback", async (req, res) => {
  const { code } = req.query;
  const tokenResponse = await axios.post(
    `https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token`,
    new URLSearchParams({
      client_id: CLIENT_ID,
      scope: SCOPE,
      code,
      redirect_uri: REDIRECT_URI,
      grant_type: "authorization_code",
      client_secret: CLIENT_SECRET,
    })
  );
  res.json(tokenResponse.data);
});

app.listen(3000, () => console.log("Server running on port 3000"));
```

---

## ✅ Summary Table

| Step | Action | Endpoint |
|------|---------|-----------|
| 1 | Redirect user to sign in | `/oauth2/v2.0/authorize` |
| 2 | Get access & refresh tokens | `/oauth2/v2.0/token` |
| 3 | Call Microsoft Graph | `/v1.0/me` |
| 4 | Refresh token | `/oauth2/v2.0/token` |

