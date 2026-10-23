@echo off
title ForgeDesk Build Pipeline
echo ============================================================
echo               ForgeDesk Multi-Target Build Pipeline
echo ============================================================
echo.

cd /d "%~dp0.."

echo [1/3] Building Rust Core, Server, and C-FFI binaries (Release)...
cargo build --release
if %errorlevel% neq 0 (
    echo [ERROR] Rust release build failed!
    exit /b %errorlevel%
)

echo.
echo [2/3] Fetching Flutter dependencies...
cd frontend
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Flutter pub get failed!
    exit /b %errorlevel%
)

echo.
echo [3/3] Running Flutter test suite...
call flutter test
if %errorlevel% neq 0 (
    echo [ERROR] Flutter tests failed!
    exit /b %errorlevel%
)

echo.
echo ============================================================
echo   BUILD SUCCESSFUL!
echo   * Server Binary : target\release\forgedesk-server.exe
echo   * Core Daemon   : target\release\forgedesk-cli.exe
echo   * C-FFI Library : target\release\forgedesk_ffi.dll
echo   * Flutter GUI   : ready in frontend\
echo ============================================================
pause
