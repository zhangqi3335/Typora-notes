# backup.ps1 - Typora 文档自动提交并推送到 GitHub
# 完全兼容中文显示，UTF-8 BOM，双击即可运行
# 支持执行状态提示 + 自定义提交备注

$OutputEncoding = [System.Text.Encoding]::UTF8

# 获取参数作为自定义描述（可能为空）
$customMsg = $args[0]

# 当前时间
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 生成最终提交消息
if ([string]::IsNullOrWhiteSpace($customMsg)) {
    $commitMsg = "自动备份 $date"
} else {
    $commitMsg = "自动备份 $date - $customMsg"
}

# 添加所有修改
git add .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 添加文件失败" -ForegroundColor Red
    exit 1
}

# 提交
git commit -m "$commitMsg"
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ 没有文件需要提交，跳过提交" -ForegroundColor Yellow
} else
{
    Write-Host "✅ 本地提交成功" -ForegroundColor Green
    Write-Host "提交信息: $commitMsg" -ForegroundColor Cyan
}

# 推送
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 推送失败" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ 推送成功" -ForegroundColor Green
}

Write-Host "全部备份完成 ✅" -ForegroundColor Cyan
