@echo off
:: 切换显示模式为 UTF-8，防止第一行中文乱码
chcp 65001 >nul

cd /d "%~dp0"

echo 正在启动同步脚本...
echo ------------------------------

:: 调用 PowerShell 运行 Logic.ps1
PowerShell -NoProfile -ExecutionPolicy Bypass -File "Logic.ps1"

echo.
echo ------------------------------
echo 脚本运行结束
pause