# backup.ps1 - Typora 文档自动提交并推送到 GitHub
# 完全兼容中文显示，UTF-8 BOM，双击即可运行
# 支持执行状态提示

# 确保 PowerShell 输出中文正常
$OutputEncoding = [System.Text.Encoding]::UTF8

# 获取当前日期和时间，用于提交信息
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 添加所有修改
git add .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 添加文件失败" -ForegroundColor Red
    exit 1
}

# 提交到本地仓库，带时间戳
git commit -m "自动备份 $date"
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ 没有文件需要提交，跳过提交" -ForegroundColor Yellow
} else {
    Write-Host "✅ 本地提交成功" -ForegroundColor Green
}

# 推送到远程仓库
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 推送到远程仓库失败，请检查网络或权限" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ 推送到远程仓库成功" -ForegroundColor Green
}

# 最终提示
Write-Host "全部备份完成 ✅" -ForegroundColor Cyan
