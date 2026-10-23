@echo off
title ForgeDesk Release Packaging Pipeline
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0package_release.ps1"
if %errorlevel% neq 0 (
    echo [ERROR] Release packaging failed!
    exit /b %errorlevel%
)
pause
