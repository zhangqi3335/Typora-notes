# Logic.ps1
# 设置输出编码为 UTF8，防止中文乱码
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 【核心修复】让 Git 正确显示中文文件名，不再显示 \345\277...
git config --local core.quotePath false

function Ask-User($question) {
    do {
        $input = Read-Host "$question (Y/N)"
        if ($input -match '^[Yy]') { return $true }
        if ($input -match '^[Nn]') { return $false }
    } while ($true)
}

# 自定义的手动选择文件函数 (替代 git add -i)
# 自定义的手动选择文件函数 (修复对齐与颜色)
function Select-Files-Interactive {
    Write-Host "`n--- 进入手动选择模式 ---" -ForegroundColor Cyan
    Write-Host "状态说明: " -NoNewline
    Write-Host "绿色" -ForegroundColor Green -NoNewline
    Write-Host "=已暂存(Staged)  " -NoNewline
    Write-Host "红色" -ForegroundColor Red -NoNewline
    Write-Host "=未暂存(Unstaged/Untracked)" 
    
    while ($true) {
        # 获取变动列表
        $changes = git status --porcelain -u
        
        if ([string]::IsNullOrWhiteSpace($changes)) {
            Write-Host "✨ 没有更多待处理的变动。" -ForegroundColor Green
            break
        }

        # 预处理数据
        $fileList = @()
        $lines = $changes -split "`n"
        foreach ($line in $lines) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                # 严格提取：第0位是暂存状态，第1位是工作区状态
                $s1 = $line[0]
                $s2 = $line[1]
                # 路径从第3位开始 (跳过两个状态位和一个空格)
                $path = $line.Substring(3).Trim('"')
                $fileList += [PSCustomObject]@{ S1 = $s1; S2 = $s2; Path = $path }
            }
        }

        # --- 打印列表 (核心修复部分) ---
        Write-Host "`n当前变动文件列表：" -ForegroundColor Yellow
        for ($i = 0; $i -lt $fileList.Count; $i++) {
            $item = $fileList[$i]
            
            # 1. 打印序号 [1]
            Write-Host " [$($i+1)]" -NoNewline -ForegroundColor Gray
            # 补齐序号后的空格，保持对齐（防止 [10] 导致错位）
            if ($i -lt 9) { Write-Host " " -NoNewline } 

            # 2. 打印左列状态 (Staged) -> 绿色
            if ($item.S1 -eq ' ' -or $item.S1 -eq '?') {
                # 如果是 ? (Untracked)，通常显示在第一列或两列都是 ?
                # 为了美观，如果是 ??，我们将第一列显示为红色?
                if ($item.S1 -eq '?') { Write-Host "?" -NoNewline -ForegroundColor Red }
                else { Write-Host " " -NoNewline }
            } else {
                Write-Host "$($item.S1)" -NoNewline -ForegroundColor Green
            }

            # 3. 打印右列状态 (Unstaged) -> 红色
            if ($item.S2 -eq ' ') {
                Write-Host " " -NoNewline
            } else {
                Write-Host "$($item.S2)" -NoNewline -ForegroundColor Red
            }

            # 4. 打印文件名
            Write-Host "  $($item.Path)"
        }
        # --------------------------------

        Write-Host "`n操作指南：" -ForegroundColor Gray
        Write-Host " • 输入序号 (如 '1 3') 添加文件"
        Write-Host " • 输入 'a' 添加所有"
        Write-Host " • 回车 结束选择"
        
        $selection = Read-Host ">>> 请选择"
        
        if ($selection -match '^[Qq]') { break }
        if ([string]::IsNullOrWhiteSpace($selection)) { break }
        
        if ($selection -match '^[Aa]') {
            git add .
            Write-Host "✅ 已添加所有剩余文件。" -ForegroundColor Green
            break
        }

        $indices = $selection -split '\s+'
        foreach ($idx in $indices) {
            if ($idx -match '^\d+$' -and [int]$idx -ge 1 -and [int]$idx -le $fileList.Count) {
                $targetItem = $fileList[[int]$idx - 1]
                # 对文件名加引号以处理空格
                git add "$($targetItem.Path)"
                Write-Host "Checking: $($targetItem.Path)" -ForegroundColor DarkGray
            }
        }
    }
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      Typora 文档同步助手 (增强版)        " -ForegroundColor Cyan
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
    # 先展示一下大概有哪些变动
    git status -s
    
    if (Ask-User "`n是否将 [所有变动] 立即添加到暂存区？(选 N 进入手动勾选模式)") {
        git add .
        Write-Host "✅ 已添加所有文件。" -ForegroundColor Green
    } else {
        # 调用我们新写的函数，替代 git add -i
        Select-Files-Interactive
    }
} else {
    Write-Host "🍵 本地无文件变动。" -ForegroundColor Green
}

# 3. 提交
Write-Host "`n[3/4] 准备提交..." -ForegroundColor Yellow
# 再次检查暂存区，防止用户在手动模式选了 q 但没加任何文件
$staged = git diff --name-only --cached
if (-not [string]::IsNullOrWhiteSpace($staged)) {
    Write-Host "📝 暂存区包含以下文件：" -ForegroundColor Cyan
    Write-Host $staged -ForegroundColor Gray
    
    $defaultMsg = "自动备份 " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $userMsg = Read-Host "请输入备注 (回车用默认: $defaultMsg)"
    if ([string]::IsNullOrWhiteSpace($userMsg)) { $commitMsg = $defaultMsg }
    else { $commitMsg = "$defaultMsg - $userMsg" }
    
    git commit -m "$commitMsg"
    Write-Host "✅ 提交成功！" -ForegroundColor Green
} else {
    Write-Host "⚠️  暂存区为空，你没有添加任何文件，跳过提交。" -ForegroundColor Yellow
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

Write-Host "`n脚本运行结束，按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")