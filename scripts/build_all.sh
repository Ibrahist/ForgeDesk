#!/usr/bin/env bash
set -e

echo "============================================================"
echo "          ForgeDesk Linux/macOS Multi-Target Build"
echo "============================================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

echo "[1/3] Building Rust Core, Server, and FFI (Release)..."
cargo build --release

echo "[2/3] Fetching Flutter dependencies..."
cd frontend
flutter pub get

echo "[3/3] Running Flutter test suite..."
flutter test

echo "============================================================"
echo "  BUILD COMPLETE!"
echo "  * Server Binary : target/release/forgedesk-server"
echo "  * Core Daemon   : target/release/forgedesk-cli"
echo "  * FFI Shared Lib: target/release/libforgedesk_ffi.*"
echo "============================================================"
