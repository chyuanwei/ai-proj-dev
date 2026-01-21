# Google Apps Script CI/CD Setup

## 設定步驟

### 1. 建立 Google Cloud Service Account

1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 建立新專案或選擇現有專案
3. 啟用 Apps Script API：
   ```
   APIs & Services > Library > 搜尋 "Apps Script API" > Enable
   ```
4. 建立 Service Account：
   ```
   IAM & Admin > Service Accounts > Create Service Account
   - Name: clasp-deploy
   - Description: GitHub Actions deployment
   - Create Key: JSON (下載 .json 檔案)
   ```

### 2. 設定 Service Account 權限

1. 複製 Service Account Email（格式如：`clasp-deploy@your-project.iam.gserviceaccount.com`）
2. 開啟您的 Apps Script 專案：
   ```
   https://script.google.com/d/AKfycbyqciyj4XAglp1K1b_wCrYTxhKBn7mAKkzbcW_A_a-y/edit
   ```
3. 點擊 "Share" > 分享給 Service Account Email，給予 "Editor" 權限

### 3. 設定 GitHub Secrets

1. 前往您的 GitHub 儲存庫：`Settings > Secrets and variables > Actions`
2. 新增 Secret：
   ```
   Name: GAS_CREDENTIALS
   Value: [貼上整個下載的 JSON 檔案內容]
   ```

### 4. 測試部署

推送到 `dev` branch 會自動觸發部署：
```bash
git add .
git commit -m "feat: Add new feature"
git push origin dev
```

### 5. 監控部署

在 GitHub Actions 頁面查看部署狀態：
```
GitHub Repository > Actions > Deploy to Google Apps Script
```

## 檔案說明

- `.github/workflows/deploy.yml` - GitHub Actions 工作流程
- `.clasp.json` - clasp 專案設定
- `src/main.js` - GAS API 程式碼
- `src/*.html` - GitHub Pages 前端程式碼

## 工作流程

```
Push to dev branch
       ↓
GitHub Actions 觸發
       ↓
clasp push --force
       ↓
程式碼部署到 GAS
       ↓
更新測試環境 URL
```

## 疑難排解

### 權限錯誤
- 確認 Service Account 有 Editor 權限
- 確認 Apps Script API 已啟用

### clasp 錯誤
- 確認 `.clasp.json` 的 scriptId 正確
- 確認 Service Account JSON 正確

### 部署失敗
- 檢查 GitHub Actions 日誌
- 確認所有檔案都在正確位置