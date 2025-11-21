# Deploy React App to Azure App Service Using GitHub Actions

This guide explains how to set up a complete CI/CD pipeline to deploy a React application to **Azure App Service** using **GitHub Actions**.

---

## 🚀 1. Create Azure App Service

**Recommended:** Linux App Service

**Settings:**
- Publish: **Code**
- Runtime Stack: **Node 18+**
- Operating System: **Linux**

After creation, proceed to the Deployment Center.

---

## 🔐 2. Download Publish Profile

Go to:

**Azure Portal → App Service → Deployment Center → Deployment Credentials**

Click **Download Publish Profile**.

You will get an XML file. This will be used inside GitHub Actions.

---

## 🔑 3. Add GitHub Secret

In GitHub:

`Repository → Settings → Secrets and Variables → Actions` → **New Repository Secret**

Name:
```
AZURE_WEBAPP_PUBLISH_PROFILE
```
Paste the full XML content.

---

## 🛠 4. Add GitHub Actions Workflow

Create file:
```
.github/workflows/deploy-react.yml
```

Add the following:

```yaml
name: Deploy React App to Azure App Service

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install dependencies
        run: |
          npm install

      - name: Build React App
        run: |
          npm run build

      - name: Upload build artifact
        uses: actions/upload-artifact@v4
        with:
          name: react-build
          path: ./build

      - name: Deploy to Azure App Service
        uses: azure/webapps-deploy@v2
        with:
          app-name: YOUR_AZURE_APP_NAME
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
          package: ./build
```

Replace:
```
YOUR_AZURE_APP_NAME
```
with your App Service name.

---

## ⚙️ 5. Configure Azure App Service for React

Go to:

**App Service → Configuration → General Settings**

Set **Node Version** to match the workflow (Node 18).

### **Startup Command (Linux):**
```
pm2 serve /home/site/wwwroot --no-daemon --spa
```

This ensures:
- React static files are served
- SPA fallback routing works

---

## 🎯 CI/CD Pipeline Summary

Whenever you push to **main**:
1. GitHub installs dependencies
2. Builds React app
3. Uploads build artifact
4. Deploys to Azure App Service

---

## 📌 Optional Enhancements

- Support for monorepos
- Environment variable management
- Node + React full-stack deployment
- Azure Static Web App alternative

Ask if you want any of these versions added!

