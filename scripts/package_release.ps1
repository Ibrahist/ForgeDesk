<#
.SYNOPSIS
    ForgeDesk Multi-Target Release Packaging Script (Android & Windows)
.DESCRIPTION
    Packages the release distribution for ForgeDesk v1.0.0 targeting Android and Windows.
#>
param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
$ReleaseDir = Join-Path $RootDir "release"
$StagingWin = Join-Path $ReleaseDir "windows-staging"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "         ForgeDesk Initial Release Pipeline ($Version)       " -ForegroundColor Cyan
Write-Host "         Targets: Android (.apk) & Windows (.zip)           " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Ensure release directory exists
if (-not (Test-Path $ReleaseDir)) {
    New-Item -ItemType Directory -Path $ReleaseDir -Force | Out-Null
}

# 1. Package Android Release
Write-Host "[1/3] Packaging Android Release APK..." -ForegroundColor Green
$SourceApk = Join-Path $RootDir "frontend\build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $SourceApk)) {
    Write-Host "Building Android APK..." -ForegroundColor Yellow
    Push-Location (Join-Path $RootDir "frontend")
    flutter build apk --release
    Pop-Location
}

$DestApk = Join-Path $ReleaseDir "ForgeDesk-v$Version-android.apk"
Copy-Item $SourceApk $DestApk -Force
Write-Host "  -> Created: $DestApk ($( [math]::Round((Get-Item $DestApk).Length / 1MB, 2) ) MB)" -ForegroundColor Gray

# 2. Package Windows Release
Write-Host "[2/3] Packaging Windows x64 Release Bundle..." -ForegroundColor Green
if (Test-Path $StagingWin) {
    Remove-Item $StagingWin -Recurse -Force
}
New-Item -ItemType Directory -Path $StagingWin -Force | Out-Null

# Copy Rust Binaries
$TargetRelease = Join-Path $RootDir "target\release"
Copy-Item (Join-Path $TargetRelease "forgedesk-cli.exe") $StagingWin -Force
Copy-Item (Join-Path $TargetRelease "forgedesk-server.exe") $StagingWin -Force
Copy-Item (Join-Path $TargetRelease "forgedesk_ffi.dll") $StagingWin -Force

# Create Convenience Launchers
@"
@echo off
title ForgeDesk Core Bridge Daemon
echo Starting ForgeDesk IPC Bridge Daemon on port 48123...
forgedesk-cli.exe bridge --port 48123
pause
"@ | Set-Content (Join-Path $StagingWin "start-bridge.bat") -Encoding ASCII

@"
@echo off
title ForgeDesk Host Service (Headless)
echo Starting ForgeDesk Headless Host Service...
forgedesk-cli.exe host
pause
"@ | Set-Content (Join-Path $StagingWin "start-host.bat") -Encoding ASCII

@"
@echo off
title ForgeDesk Self-Hosted Server
echo Starting ForgeDesk Self-Hosted Rendezvous and Relay Server...
forgedesk-server.exe --bind 0.0.0.0 --rendezvous-port 21115 --relay-port 21117
pause
"@ | Set-Content (Join-Path $StagingWin "start-server.bat") -Encoding ASCII

# Create Windows README
@"
========================================================================
                      ForgeDesk v$Version - Windows x64
                 Private, High-Performance Remote Desktop
========================================================================

Contents:
  - forgedesk-cli.exe     : Core background daemon & CLI tool
  - forgedesk-server.exe  : Standalone Rendezvous (21115) & Relay (21117)
  - forgedesk_ffi.dll     : Native C-FFI runtime library
  - start-bridge.bat      : Launches local IPC bridge for GUI / Flutter
  - start-host.bat        : Launches headless remote desktop host
  - start-server.bat      : Launches self-hosted signaling and relay server

Quick Start:
  1. To run a private relay server:
     Double-click 'start-server.bat'.
     Ensure TCP ports 21115 and 21117 are accessible through your firewall.

  2. To host this computer for incoming connections:
     Double-click 'start-host.bat'. Your 9-digit peer ID and one-time
     password will be generated and displayed in the console.

  3. To connect GUI frontend:
     Double-click 'start-bridge.bat' to initialize the IPC service on
     ws://127.0.0.1:48123.

Security:
  - All stream traffic is end-to-end encrypted.
  - One-time passwords regenerate dynamically on every session.

License: MIT
Repository: https://github.com/Ibrahist/ForgeDesk
========================================================================
"@ | Set-Content (Join-Path $StagingWin "README.txt") -Encoding UTF8

$DestWinZip = Join-Path $ReleaseDir "ForgeDesk-v$Version-windows-x64.zip"
if (Test-Path $DestWinZip) {
    Remove-Item $DestWinZip -Force
}
Compress-Archive -Path "$StagingWin\*" -DestinationPath $DestWinZip -Force
Remove-Item $StagingWin -Recurse -Force
Write-Host "  -> Created: $DestWinZip ($( [math]::Round((Get-Item $DestWinZip).Length / 1MB, 2) ) MB)" -ForegroundColor Gray

# 3. Generate SHA-256 Checksums
Write-Host "[3/3] Generating SHA256 Checksums..." -ForegroundColor Green
$ChecksumFile = Join-Path $ReleaseDir "SHA256SUMS.txt"
$Hashes = @()
$Hashes += Get-FileHash -Path $DestApk -Algorithm SHA256 | ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path $_.Path -Leaf)" }
$Hashes += Get-FileHash -Path $DestWinZip -Algorithm SHA256 | ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path $_.Path -Leaf)" }
$Hashes | Set-Content $ChecksumFile -Encoding ASCII

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                   RELEASE ARTIFACTS READY                   " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Get-ChildItem $ReleaseDir | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
Write-Host ""
Get-Content $ChecksumFile
Write-Host "============================================================" -ForegroundColor Cyan
