# Logic.ps1
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Ask-User($question) {
    do {
        $input = Read-Host "$question (Y/N)"
        if ($input -match '^[Yy]') { return $true }
        if ($input -match '^[Nn]') { return $false }
    } while ($true)
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      Typora 文档同步助手 (交互版)        " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. 检查远程更新
Write-Host "`n[1/4] 检查远程仓库更新..." -ForegroundColor Yellow
git fetch origin
$statusOutput = git status -sb
if ($statusOutput -match "behind") {
    Write-Host "⚠️  发现远程有新内容！" -ForegroundColor Magenta
    if (Ask-User "是否拉取远程更新？") {
        git pull origin main
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 更新文件如下：" -ForegroundColor Green
            git diff --name-only ORIG_HEAD HEAD
        } else {
            Write-Host "❌ 拉取失败，存在冲突，脚本停止。" -ForegroundColor Red
            exit 1
        }
    }
} else {
    Write-Host "✅ 远程无新内容。" -ForegroundColor Green
}

# 2. 检查本地修改
Write-Host "`n[2/4] 检查本地变动..." -ForegroundColor Yellow
$localChanges = git status --porcelain
if (-not [string]::IsNullOrWhiteSpace($localChanges)) {
    git status -s
    if (Ask-User "是否将 [所有变动] 添加到暂存区？(N=手动选择)") {
        git add .
        Write-Host "✅ 已添加所有文件。" -ForegroundColor Green
    } else {
        Write-Host "🔧 启动交互模式，请按提示操作..." -ForegroundColor Cyan
        git add -i
    }
} else {
    Write-Host "🍵 本地无文件变动。" -ForegroundColor Green
}

# 3. 提交
Write-Host "`n[3/4] 准备提交..." -ForegroundColor Yellow
$staged = git diff --name-only --cached
if (-not [string]::IsNullOrWhiteSpace($staged)) {
    $defaultMsg = "自动备份 " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $userMsg = Read-Host "请输入备注 (回车用默认: $defaultMsg)"
    if ([string]::IsNullOrWhiteSpace($userMsg)) { $commitMsg = $defaultMsg }
    else { $commitMsg = "$defaultMsg - $userMsg" }
    
    git commit -m "$commitMsg"
    Write-Host "✅ 提交成功！" -ForegroundColor Green
} else {
    Write-Host "⚠️  暂存区为空，无需提交。" -ForegroundColor Yellow
}

# 4. 推送
Write-Host "`n[4/4] 准备推送..." -ForegroundColor Yellow
$unpushed = git log origin/main..HEAD --oneline
if (-not [string]::IsNullOrWhiteSpace($unpushed)) {
    Write-Host "📦 待推送的提交：" -ForegroundColor Cyan
    Write-Host $unpushed -ForegroundColor Gray
    if (Ask-User "是否推送到 GitHub？") {
        git push origin main
        if ($LASTEXITCODE -eq 0) { Write-Host "🎉 推送成功！" -ForegroundColor Green }
        else { Write-Host "❌ 推送失败。" -ForegroundColor Red }
    }
} else {
    Write-Host "☁️  所有内容已同步。" -ForegroundColor Green
}