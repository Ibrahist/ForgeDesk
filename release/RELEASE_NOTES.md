# Release Notes - ForgeDesk v1.0.0

**Initial Release for Android & Windows**  
*Release Date: October 23, 2026*  
*License: MIT*  

ForgeDesk is an open-source, high-performance, private remote desktop system designed as a secure self-hosted alternative to TeamViewer and AnyDesk.

---

## 📦 Release Artifacts

| Platform | File | Size | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| **Android** | `ForgeDesk-v1.0.0-android.apk` | ~49.0 MB | `6c575ea865d37752efcd861e9adf0b9ddd4eaaa52e8d81902e5d194b9c54316a` |
| **Windows x64** | `ForgeDesk-v1.0.0-windows-x64.zip` | ~9.9 MB | `fdb3643a3a4ee08cbf76c745ea466c0e3dc189fdc3002da63eb017cb1cd5edcb` |
| **Checksums** | `SHA256SUMS.txt` | < 1 KB | Text manifest of all package hashes |

---

## ✨ Features Included in v1.0.0

### 1. Android Mobile Client
- **Direct Remote Control**: Connect to any host machine using standard 9-digit peer IDs and one-time temporary passwords.
- **Responsive Touch & Canvas Navigation**: Low-latency screen streaming with interactive touch-to-mouse translation and adaptive aspect ratio modes.
- **Infinite Random One-Time Passwords**: Cryptographically secure alphanumeric generator without repetitive limits.
- **Server & Relay Selection**: Out-of-the-box zero-config public network connection with full support for self-hosted rendezvous/relay servers.
- **Status Indicators**: Hardware-grade jewel LED status indicators with live network health monitoring.
- **Light & Dark Theme Engine**: Full support with instant toggle and high contrast accessibility.

### 2. Windows x64 Core Suite
- **`forgedesk-cli.exe`**: High-performance core daemon with Windows GDI desktop capture, low-overhead tile compression, SendInput mouse/keyboard injection, and WebSocket IPC bridge (`ws://127.0.0.1:48123`).
- **`forgedesk-server.exe`**: Standalone, lightweight rendezvous signaling daemon (port `21115`) and zero-knowledge streaming relay (port `21117`).
- **`forgedesk_ffi.dll`**: C-ABI dynamic library for native integration and host streaming.
- **One-Click Launchers**:
  - `start-bridge.bat`: Launches the local IPC bridge for GUI clients.
  - `start-host.bat`: Starts headless hosting service on this computer.
  - `start-server.bat`: Starts private rendezvous and relay services.

---

## 🔒 Security & Privacy

- **End-to-End Encryption**: Secure stream transport between host and remote client.
- **No Telemetry or Tracking**: No commercial telemetry, analytics, or third-party tracking.
- **Self-Hosted Privacy**: Rendezvous and relay nodes can be run on isolated internal networks or private VPS nodes.

---

## 🚀 Quick Verification

To verify the integrity of your downloaded files on Windows PowerShell:

```powershell
Get-FileHash -Algorithm SHA256 ForgeDesk-v1.0.0-android.apk
Get-FileHash -Algorithm SHA256 ForgeDesk-v1.0.0-windows-x64.zip
```
