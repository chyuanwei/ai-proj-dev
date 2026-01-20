# PowerShell 脚本：推送到 GAS 时临时使用 index.gas.html
# 使用方法：.\push-to-gas.ps1

Write-Host "准备推送到 Google Apps Script..." -ForegroundColor Green

# 1. 备份当前的 index.html（GitHub 版本）
if (Test-Path "src\index.html") {
    Copy-Item "src\index.html" "src\index.html.backup" -Force
    Write-Host "✓ 已备份 GitHub 版本的 index.html" -ForegroundColor Yellow
}

# 2. 将 GAS 版本复制为 index.html（临时）
if (Test-Path "src\index.gas.html") {
    Copy-Item "src\index.gas.html" "src\index.html" -Force
    Write-Host "✓ 已使用 GAS 版本的 index.gas.html" -ForegroundColor Yellow
}

# 3. 移除 index.html 的忽略规则（临时）
$claspignoreContent = Get-Content ".claspignore" -Raw
$claspignoreContent = $claspignoreContent -replace "src/index.html", "# src/index.html (temporarily enabled for push)"
Set-Content ".claspignore" -Value $claspignoreContent -NoNewline

try {
    # 4. 推送到 GAS
    Write-Host "`n正在推送到 GAS..." -ForegroundColor Cyan
    npx @google/clasp push --force
    
    Write-Host "`n✓ 推送成功！" -ForegroundColor Green
} finally {
    # 5. 恢复 index.html 为 GitHub 版本
    if (Test-Path "src\index.html.backup") {
        Copy-Item "src\index.html.backup" "src\index.html" -Force
        Remove-Item "src\index.html.backup" -Force
        Write-Host "✓ 已恢复 GitHub 版本的 index.html" -ForegroundColor Yellow
    }
    
    # 6. 恢复 .claspignore
    $claspignoreContent = $claspignoreContent -replace "# src/index.html \(temporarily enabled for push\)", "src/index.html"
    Set-Content ".claspignore" -Value $claspignoreContent -NoNewline
}

Write-Host "`n完成！" -ForegroundColor Green
