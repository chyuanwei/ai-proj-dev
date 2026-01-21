# PowerShell 脚本：推送到 GAS 时临时使用 .gas.html 版本
# 使用方法：.\push-to-gas.ps1

Write-Host "准备推送到 Google Apps Script..." -ForegroundColor Green

# 1. 备份当前的 HTML 文件（GitHub 版本）
$filesToBackup = @("index.html", "order.html", "confirm.html")
foreach ($file in $filesToBackup) {
    $srcPath = "src\$file"
    $backupPath = "src\$file.backup"
    if (Test-Path $srcPath) {
        Copy-Item $srcPath $backupPath -Force
        Write-Host "✓ 已备份 GitHub 版本的 $file" -ForegroundColor Yellow
    }
}

# 2. 将 GAS 版本复制为 HTML 文件（临时）
$gasFiles = @("index.gas.html", "order.gas.html", "confirm.gas.html")
foreach ($gasFile in $gasFiles) {
    $gasPath = "src\$gasFile"
    $htmlFile = $gasFile -replace "\.gas\.html", ".html"
    $htmlPath = "src\$htmlFile"
    if (Test-Path $gasPath) {
        Copy-Item $gasPath $htmlPath -Force
        Write-Host "✓ 已使用 GAS 版本的 $gasFile" -ForegroundColor Yellow
    }
}

# 3. 移除 HTML 文件的忽略规则（临时）
$claspignoreContent = Get-Content ".claspignore" -Raw
$claspignoreContent = $claspignoreContent -replace "src/index\.html", "# src/index.html (temporarily enabled for push)"
$claspignoreContent = $claspignoreContent -replace "src/order\.html", "# src/order.html (temporarily enabled for push)"
$claspignoreContent = $claspignoreContent -replace "src/confirm\.html", "# src/confirm.html (temporarily enabled for push)"
Set-Content ".claspignore" -Value $claspignoreContent -NoNewline

try {
    # 4. 推送到 GAS
    Write-Host "`n正在推送到 GAS..." -ForegroundColor Cyan
    npx @google/clasp push --force
    
    Write-Host "`n✓ 推送成功！" -ForegroundColor Green
} finally {
    # 5. 恢复 HTML 文件为 GitHub 版本
    foreach ($file in $filesToBackup) {
        $htmlPath = "src\$file"
        $backupPath = "src\$file.backup"
        if (Test-Path $backupPath) {
            Copy-Item $backupPath $htmlPath -Force
            Remove-Item $backupPath -Force
            Write-Host "✓ 已恢复 GitHub 版本的 $file" -ForegroundColor Yellow
        }
    }

    # 6. 恢复 .claspignore
    $claspignoreContent = $claspignoreContent -replace "# src/index\.html \(temporarily enabled for push\)", "src/index.html"
    $claspignoreContent = $claspignoreContent -replace "# src/order\.html \(temporarily enabled for push\)", "src/order.html"
    $claspignoreContent = $claspignoreContent -replace "# src/confirm\.html \(temporarily enabled for push\)", "src/confirm.html"
    Set-Content ".claspignore" -Value $claspignoreContent -NoNewline
}

Write-Host "`n完成！" -ForegroundColor Green
