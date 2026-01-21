# PowerShell 脚本：完全自动化更新代码到 GAS 并部署
# 使用方法：.\update-gas.ps1 [--deploymentId ID]
# 功能：推送代码 + 自动更新部署（Web App URL 保持不变）

param(
    # 默认使用你的 Web App 部署 ID（可以在 GAS 编辑器中找到）
    [string]$DeploymentId = "AKfycbxl1BaKd_AgfBLeS-fNfdKcB1BrfVjY_V-ZS9CdjqydHZdqtgBsyFwaujnnTKLbTB3gGQ"
)

Write-Host "Starting automated update to Google Apps Script..." -ForegroundColor Green

# 1. 备份并准备 index.html
Write-Host "`n1. Preparing files..." -ForegroundColor Cyan
if (Test-Path "src\index.html") {
    Copy-Item "src\index.html" "src\index.html.backup" -Force
}
if (Test-Path "src\index.gas.html") {
    Copy-Item "src\index.gas.html" "src\index.html" -Force
    Write-Host "  ✓ Using GAS version of index.gas.html" -ForegroundColor Yellow
}

# 2. 临时禁用 .claspignore 中的 index.html
$claspignoreContent = Get-Content ".claspignore" -Raw
$originalIgnoreContent = $claspignoreContent
$claspignoreContent = $claspignoreContent -replace "src/index.html", "# src/index.html (temporarily enabled)"
Set-Content ".claspignore" -Value $claspignoreContent -NoNewline

try {
    # 3. 推送代码到 GAS
    Write-Host "`n2. Pushing code to GAS..." -ForegroundColor Cyan
    npx @google/clasp push --force
    
    Write-Host "`n✓ Code push successful!" -ForegroundColor Green
    
    # 4. 自动部署更新
    if ($DeploymentId -eq "") {
        Write-Host "`n3. Checking for existing Web App deployment..." -ForegroundColor Cyan
        # 提示用户输入 Deployment ID，或者从最近的部署中选择
        Write-Host "  Hint: If you know your Web App deployment ID, you can run:" -ForegroundColor Yellow
        Write-Host "    .\update-gas.ps1 -DeploymentId '你的部署ID'" -ForegroundColor White
        Write-Host "`n  Alternatively, visit the GAS editor to manually update deployment:" -ForegroundColor Yellow
        Write-Host "    https://script.google.com/home/projects/120HJmF_WI9Q0OCA51GRM70vHB710JlfRb9OHjOIwfI1USMBuNw1o-0bf/edit" -ForegroundColor Cyan
        Write-Host "    -> 部署 -> 管理部署 -> 编辑 -> 选择最新版本 -> 更新" -ForegroundColor White
    } else {
        Write-Host "`n3. Updating existing deployment..." -ForegroundColor Cyan
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        npx @google/clasp deploy -i $DeploymentId -d "自动部署更新 - $timestamp"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✓ Deployment update successful! Web App URL remains unchanged" -ForegroundColor Green
        } else {
            Write-Host "`n⚠ Deployment update failed, please check if Deployment ID is correct" -ForegroundColor Yellow
        }
    }
    
} finally {
    # 5. 恢复文件
    Write-Host "`n4. Restoring files..." -ForegroundColor Cyan
    if (Test-Path "src\index.html.backup") {
        Copy-Item "src\index.html.backup" "src\index.html" -Force
        Remove-Item "src\index.html.backup" -Force
        Write-Host "  ✓ Restored GitHub version of index.html" -ForegroundColor Yellow
    }
    
    # 6. 恢复 .claspignore
    Set-Content ".claspignore" -Value $originalIgnoreContent -NoNewline
}

Write-Host "`nComplete!" -ForegroundColor Green