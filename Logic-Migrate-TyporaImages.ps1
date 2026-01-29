<#
.SYNOPSIS
    Typora 图片本地化迁移脚本 
#>

# ================= 配置区域 =================

# Markdown 库的根目录
$RootDir = "D:\资料\Typora学习库"

# Typora 默认图片存放目录 (源目录)
$SourceImageDirBase = "C:\Users\17820\AppData\Roaming\Typora\typora-user-images"

# 目标图片存放根目录名
$TargetImageFolderName = "Image"

# 是否为演示模式 (DryRun)
# $true: 仅打印日志，不移动文件，不修改 MD
# $false: 实际执行
$DryRun = $true

# --- 日志配置修改 ---
# 定义日志文件夹路径
$LogDir = Join-Path $RootDir "Log"

# 如果日志目录不存在，则创建
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# 日志文件路径 (现在位于 Log 文件夹内)
$LogFile = Join-Path $LogDir ("Migration_Log_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

# ================= 辅助函数 =================

function Write-Log {
    param([string]$Message, [string]$Level="INFO", [ConsoleColor]$Color="White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp][$Level] $Message"
    Write-Host $logLine -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $logLine -Encoding UTF8
}

function Get-RelativePath {
    param([string]$FromPath, [string]$ToPath)
    
    $fromUri = New-Object System.Uri $FromPath
    $toUri   = New-Object System.Uri $ToPath
    
    if ($fromUri.Scheme -ne $toUri.Scheme) { return $ToPath }

    $relativePathUri = $fromUri.MakeRelativeUri($toUri)
    $relativePath = [System.Uri]::UnescapeDataString($relativePathUri.ToString())
    
    return $relativePath
}

# [已删除] Backup-File 函数

# ================= 主逻辑 =================

try {
    # 开启控制台转录，记录屏幕上所有的输出到文件
    Start-Transcript -Path "$LogFile.console.txt" -Append -Force | Out-Null
    
    Write-Log "=== 开始 Typora 图片迁移任务 ===" -Color Cyan
    Write-Log "根目录: $RootDir"
    Write-Log "日志目录: $LogDir"
    Write-Log "源图片目录: $SourceImageDirBase"
    Write-Log "模式: $(if($DryRun){'演示 (DryRun)'} else {'实际执行 (Apply)'})" -Color Yellow

    if (-not (Test-Path $RootDir)) {
        throw "根目录不存在: $RootDir"
    }

    $mdFiles = Get-ChildItem -Path $RootDir -Filter "*.md" -Recurse

    foreach ($file in $mdFiles) {
        Write-Log "正在扫描: $($file.FullName)" -Level "INFO" -Color Gray

        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        $newContent = $content
        $hasChange = $false

        $patterns = @(
            '(?i)!\[.*?\]\((.*?)\)',       
            '(?i)<img\s+[^>]*src=["''](.*?)["'']' 
        )

        foreach ($pattern in $patterns) {
            $matches = [regex]::Matches($content, $pattern)
            
            foreach ($match in $matches) {
                $originalPath = $match.Groups[1].Value
                
                # 使用 System.Uri 解码路径
                $decodedPath = [System.Uri]::UnescapeDataString($originalPath)
                
                $isTarget = $false
                $fullSourcePath = ""

                # 匹配路径中是否包含 typora-user-images
                if ($decodedPath -match "typora-user-images") {
                    if (Test-Path $decodedPath) {
                        $fullSourcePath = $decodedPath
                        $isTarget = $true
                    } elseif (Test-Path (Join-Path $SourceImageDirBase (Split-Path $decodedPath -Leaf))) {
                         $fullSourcePath = Join-Path $SourceImageDirBase (Split-Path $decodedPath -Leaf)
                         $isTarget = $true
                    }
                }

                if ($isTarget -and (Test-Path $fullSourcePath)) {
                    $mdBaseName = $file.BaseName
                    $targetDir = Join-Path $RootDir "$TargetImageFolderName\$mdBaseName"
                    
                    $fileName = Split-Path $fullSourcePath -Leaf
                    $targetFilePath = Join-Path $targetDir $fileName

                    $relativePath = Get-RelativePath -FromPath $file.FullName -ToPath $targetFilePath

                    Write-Log "  [发现目标] $fileName" -Color Green
                    Write-Log "    源: $fullSourcePath"
                    Write-Log "    靶: $targetFilePath"
                    Write-Log "    链: $relativePath"

                    if (-not $DryRun) {
                        if (-not (Test-Path $targetDir)) {
                            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                        }

                        if (-not (Test-Path $targetFilePath)) {
                            Copy-Item -LiteralPath $fullSourcePath -Destination $targetFilePath -Force
                            Write-Log "    -> 图片已复制" -Color Cyan
                        } else {
                            Write-Log "    -> 目标图片已存在，跳过复制" -Color DarkYellow
                        }

                        # 替换路径
                        $replacement = $relativePath.Replace('\', '/')
                        $newContent = $newContent.Replace($originalPath, $replacement)
                        $hasChange = $true
                    }
                }
            }
        }

        if ($hasChange -and (-not $DryRun)) {
            # [已修改] 直接覆盖写入原文件，不再生成 .bak 备份
            [System.IO.File]::WriteAllText($file.FullName, $newContent, [System.Text.Encoding]::UTF8)
            Write-Log "  -> MD 文件已更新并保存" -Color Magenta
        }
    }

    Write-Log "=== 任务完成 ===" -Color Cyan

} catch {
    Write-Log "发生严重错误: $_" -Level "ERROR" -Color Red
} finally {
    Stop-Transcript | Out-Null
    Write-Host "按任意键退出..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}