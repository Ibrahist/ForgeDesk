# Changelog

All notable changes to ForgeDesk will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-23

### Initial Release (Android & Windows)

#### Added
- **Android Client**: Full Flutter-based mobile client with screen viewer, session controls, and touch input forwarding.
- **Windows Core Suite**:
  - `forgedesk-cli`: Rust core daemon with desktop capture, input injection, and IPC WebSocket bridge.
  - `forgedesk-server`: Standalone rendezvous signaling (port 21115) and relay daemon (port 21117).
  - `forgedesk_ffi`: C-ABI shared library for native streaming integration.
- **Security**: Infinite cryptographically random password generation (`Random.secure`).
- **UI/UX**:
  - Orbitron typography and futuristic high-contrast design.
  - Non-clickable hardware-grade jewel LED status indicators for ForgeDesk Cloud Network and Machine Host readiness.
  - Seamless Light and Dark mode theme switching with zero delay.
  - Recent connections history management.
- **Packaging**: Automated release packaging pipeline for Android APK and Windows x64 ZIP distribution with SHA-256 verification.
