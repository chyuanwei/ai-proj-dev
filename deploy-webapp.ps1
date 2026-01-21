# PowerShell 脚本：推送到 GAS 并更新 Web App 部署
# 使用方法：.\deploy-webapp.ps1

Write-Host "开始部署到 Google Apps Script..." -ForegroundColor Green

# 1. 备份并准备 index.html
Write-Host "`n1. 准备文件..." -ForegroundColor Cyan
if (Test-Path "src\index.html") {
    Copy-Item "src\index.html" "src\index.html.backup" -Force
}
if (Test-Path "src\index.gas.html") {
    Copy-Item "src\index.gas.html" "src\index.html" -Force
    Write-Host "  ✓ 已使用 GAS 版本的 index.gas.html" -ForegroundColor Yellow
}

# 2. 临时禁用 .claspignore 中的 index.html
$claspignoreContent = Get-Content ".claspignore" -Raw
$originalIgnoreContent = $claspignoreContent
$claspignoreContent = $claspignoreContent -replace "src/index.html", "# src/index.html (temporarily enabled)"
Set-Content ".claspignore" -Value $claspignoreContent -NoNewline

try {
    # 3. 推送代码到 GAS
    Write-Host "`n2. 推送代码到 GAS..." -ForegroundColor Cyan
    npx @google/clasp push --force
    
    Write-Host "`n✓ 代码推送成功！" -ForegroundColor Green
    
    # 4. 部署新版本
    Write-Host "`n3. 创建新部署版本..." -ForegroundColor Cyan
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $deployOutput = npx @google/clasp deploy --description "Auto deployment - $timestamp" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✓ 部署成功！" -ForegroundColor Green
        Write-Host "`n部署信息：" -ForegroundColor Yellow
        Write-Host $deployOutput
        
        Write-Host "`n重要提示：" -ForegroundColor Yellow
        Write-Host "  1. 如果是第一次部署，请访问以下链接设置 Web App：" -ForegroundColor White
        Write-Host "     https://script.google.com/home/projects/120HJmF_WI9Q0OCA51GRM70vHB710JlfRb9OHjOIwfI1USMBuNw1o-0bf/edit" -ForegroundColor Cyan
        Write-Host "     -> 点击 '部署' -> '管理部署' -> '编辑' -> 选择 '网页应用程式'" -ForegroundColor White
        Write-Host "`n  2. 如果已经设置过 Web App，在 GAS 编辑器中：" -ForegroundColor White
        Write-Host "     -> 点击 '部署' -> '管理部署' -> '编辑' -> 项目版本选择 'HEAD'" -ForegroundColor White
        Write-Host "     -> 点击 '更新' 即可使用最新代码（URL 保持不变）" -ForegroundColor White
    } else {
        Write-Host "`n⚠ 部署命令执行，请检查上方输出" -ForegroundColor Yellow
    }
    
} finally {
    # 5. 恢复文件
    Write-Host "`n4. 恢复文件..." -ForegroundColor Cyan
    if (Test-Path "src\index.html.backup") {
        Copy-Item "src\index.html.backup" "src\index.html" -Force
        Remove-Item "src\index.html.backup" -Force
        Write-Host "  ✓ 已恢复 GitHub 版本的 index.html" -ForegroundColor Yellow
    }
    
    # 6. 恢复 .claspignore
    Set-Content ".claspignore" -Value $originalIgnoreContent -NoNewline
}

Write-Host "`n完成！" -ForegroundColor Green
