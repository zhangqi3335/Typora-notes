@echo off
REM 切换控制台代码页为 UTF-8，防止中文乱码
chcp 65001 >nul
cd /d "%~dp0"

echo ==========================================
echo      Typora 图片整理工具 (工程版)
echo ==========================================
echo.
echo 正在准备运行 PowerShell 脚本...
echo 默认模式为: DryRun (仅演示，不修改)
echo 如需实际执行，请编辑 .ps1 文件将 $DryRun 改为 $false
echo.

REM 使用 Bypass 策略运行脚本
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Migrate-TyporaImages.ps1"

echo.
pause