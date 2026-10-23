@echo off
title ForgeDesk Server (Self-Hosted Rendezvous & Relay)
echo ============================================================
echo           Starting ForgeDesk Self-Hosted Server
echo ============================================================
echo.

cd /d "%~dp0.."

if not exist "target\debug\forgedesk-server.exe" (
    echo Building forgedesk-server binary...
    cargo build --bin forgedesk-server
)

target\debug\forgedesk-server.exe --bind 0.0.0.0 --rendezvous-port 21115 --relay-port 21117 %*
pause
