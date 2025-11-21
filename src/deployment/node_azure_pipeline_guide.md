# Deploy Node.js App to Azure App Service Using GitHub Actions

This guide explains how to deploy a **Node.js API/server** to **Azure App Service** using a fully automated **GitHub Actions CI/CD pipeline**.

---

## 🚀 1. Create Azure App Service

### Recommended Configuration
- Publish: **Code**
- Runtime Stack: **Node 18+**
- OS: **Linux**

Once the App Service is created, proceed to the Deployment Center.

---

## 🔐 2. Download Publish Profile

In Azure Portal:

**App Service → Deployment Center → Deployment Credentials**

Click **Download Publish Profile**.

This provides an XML file containing your deployment credentials.

---

## 🔑 3. Add GitHub Secret

Go to GitHub:

`Repository → Settings → Secrets and Variables → Actions → New Repository Secret`

Name it:
```
AZURE_WEBAPP_PUBLISH_PROFILE
```
Paste the full XML content of your publish profile.

---

## 🛠 4. Add GitHub Actions Workflow

Create the following file inside your repository:
```
.github/workflows/deploy-node.yml
```

Add the following YAML:

```yaml
name: Deploy Node.js App to Azure App Service

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

      - name: Run Build (if any)
        run: |
          npm run build
        if: ${{ exists('package.json') && contains(join(fromJSON(format('"{0}"', inputs)), ''), 'build') }}

      - name: Archive production artifacts
        run: |
          mkdir -p package
          cp -R * package

      - name: Deploy to Azure App Service
        uses: azure/webapps-deploy@v2
        with:
          app-name: YOUR_AZURE_APP_NAME
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
          package: package
```

Replace:
```
YOUR_AZURE_APP_NAME
```
with the actual name of your Azure App Service.

---

## ⚙️ 5. Configure Azure App Service Startup

In Azure Portal:

**App Service → Configuration → General Settings**

### Set Node Version
Choose the same Node version you used in GitHub Actions (recommended: Node 18).

### For Linux App Service
Azure automatically runs your Node app using:
```
npm start
```

Ensure your `package.json` has:
```json
"scripts": {
  "start": "node server.js"
}
```
Or whatever your main file is.

---

## 📦 Folder Structure Considerations

Azure deploys whatever is inside the `package/` folder created by the workflow:
```
package/
  ├─ node_modules/
  ├─ src/
  ├─ dist/ (if using TypeScript build)
  ├─ server.js
  ├─ package.json
  └─ ...
```

Make sure the final deployed folder contains:
- `package.json`
- Your entry file (`server.js`, `app.js`, `dist/main.js`, etc.)
- Any build outputs

---

## 🎯 CI/CD Pipeline Summary

When you push to **main**:
1. GitHub installs dependencies
2. Builds the Node app (if applicable)
3. Packages all files
4. Deploys automatically to Azure App Service

---

## 📌 Optional Enhancements

- PM2 startup support
- TypeScript build pipeline
- Environment variable setup
- Monorepo (React + Node) deployment
- Docker-based Azure App Service deployment

Tell me if you want any of these included!

