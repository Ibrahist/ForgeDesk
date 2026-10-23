@echo off
title ForgeDesk Client Launcher
echo ============================================================
echo               Starting ForgeDesk Remote Client
echo ============================================================
echo.

cd /d "%~dp0.."

if not exist "target\debug\forgedesk-cli.exe" (
    echo Building ForgeDesk Core daemon...
    cargo build --bin forgedesk-cli
)

echo Starting ForgeDesk background bridge service on port 48123...
start "ForgeDesk Core Daemon" /min target\debug\forgedesk-cli.exe bridge --port 48123

echo Launching Flutter GUI...
cd frontend
flutter run -d chrome
