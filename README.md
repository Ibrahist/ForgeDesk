# ForgeDesk 🛡️⚡

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Core: Rust](https://img.shields.io/badge/Core-Rust_1.80+-orange.svg)](https://www.rust-lang.org/)
[![GUI: Flutter](https://img.shields.io/badge/GUI-Flutter_3.24+-02569B.svg)](https://flutter.dev/)
[![Platforms: Windows | macOS | Linux | Android | iOS](https://img.shields.io/badge/Platforms-Desktop_%26_Mobile-success.svg)](#cross-platform-support)

**ForgeDesk** is a modern, high-performance, open-source remote desktop application designed as a private, self-hosted alternative to TeamViewer and AnyDesk. 

ForgeDesk puts you in **complete control of your own data**, eliminating commercial telemetry, subscription paywalls, and closed-source relay servers. It connects peers out-of-the-box using a simple **9-digit ID and password**, with seamless support for both the public network and completely isolated, self-hosted private rendezvous/relay servers.

---

## ✨ Features

- **🚀 Performance-First Rust Core**: Ultra-fast desktop capture, hardware-accelerated JPEG/tile compression, and asynchronous I/O driven by Tokio.
- **🎨 Modern Cross-Platform GUI**: Built with Flutter featuring a sleek, responsive dark glassmorphism interface with fluid micro-animations.
- **🔢 Out-of-the-box ID & Password**: Connect to any computer simply by entering their 9-digit ForgeDesk ID and one-time password.
- **🌐 Self-Hosted or Public Server**:
  - **Public Network**: Default fallback for zero-configuration, instant connections.
  - **Self-Hosted Server (`forgedesk-server`)**: Deploy your own rendezvous and relay node on your private VPS, Docker, or local LAN with full privacy.
- **🔒 Security & Privacy by Design**:
  - End-to-end encrypted packet transmission.
  - One-time dynamic passwords + permanent access password support.
  - Access control policies (toggle remote input, clipboard sync, view-only mode).
- **🖥️ Remote Control Viewer**:
  - Aspect-ratio responsive canvas (Fit to Window, 100% 1:1, Stretch).
  - Low-latency mouse tracking, scroll wheel, and full keyboard event forwarding.
  - Quick actions: `Ctrl + Alt + Del`, Lock Workstation, and Taskbar toggling.
  - Real-time in-session text chat and clipboard synchronization.
  - Live telemetry overlay: FPS, latency (ms), and network bitrate (kbps).
- **📱 True Cross-Platform**: Structured for Windows, macOS, Linux, Android, and iOS.

---

## 🏛️ Architecture Overview

```
+-----------------------------------------------------------------------------------+
|                                  ForgeDesk Node                                   |
|                                                                                   |
|  +----------------------------+             +----------------------------------+  |
|  |     Flutter Frontend       |  WebSocket  |        ForgeDesk Core Daemon     |  |
|  |  (Windows/macOS/Linux/App) | <=========> |     (Capture / Input / Stream)   |  |
|  |  - Dashboard & Controls    |  IPC Port   |  - Win32/X11/Quartz Capture      |  |
|  |  - Remote Session Canvas   |    48123    |  - SendInput / Input Injection   |  |
|  |  - Telemetry & Chat Drawer |             |  - Frame Encoder (JPEG/Delta)    |  |
|  +----------------------------+             +-----------------+----------------+  |
+---------------------------------------------------------------|-------------------+
                                                                |
                                             Signaling & Relay  |
                                          (Port 21115 / 21117)  |
                                                                v
                                              +----------------------------------+
                                              |        forgedesk-server          |
                                              |    (Self-Hosted Rendezvous)      |
                                              |  - Peer ID Registration          |
                                              |  - NAT Traversal & Punching      |
                                              |  - Zero-Knowledge Relay Stream   |
                                              +----------------------------------+
```

### Repository Structure

- [`crates/forgedesk-core`](file:///d:/ForgeDesk/crates/forgedesk-core): The core library containing the network protocol, GDI/DirectX desktop capture engine, input simulator, session lifecycle, and local IPC bridge.
- [`crates/forgedesk-server`](file:///d:/ForgeDesk/crates/forgedesk-server): Standalone, lightweight daemon providing Rendezvous (signaling) and Relay services for self-hosting.
- [`crates/forgedesk-ffi`](file:///d:/ForgeDesk/crates/forgedesk-ffi): C-ABI shared library (`forgedesk_ffi.dll` / `.so` / `.dylib`) for native bindings.
- [`crates/forgedesk-cli`](file:///d:/ForgeDesk/crates/forgedesk-cli): Headless CLI tool to run the background service or host headless nodes.
- [`frontend/`](file:///d:/ForgeDesk/frontend): The Flutter client application targeting Windows, macOS, Linux, Web, Android, and iOS.
- [`deploy/`](file:///d:/ForgeDesk/deploy): Dockerfile, Docker Compose file, and server configuration templates.
- [`scripts/`](file:///d:/ForgeDesk/scripts): Automated build and launch scripts for Windows and POSIX systems.

---

## 🚀 Quick Start

### 1. Launching the Client

To launch the ForgeDesk client on Windows:
```cmd
# Run using the automated script:
scripts\run_client.bat

# Or run manually:
# Step 1: Start background daemon
cargo run --bin forgedesk-cli -- bridge --port 48123

# Step 2: Launch Flutter GUI
cd frontend
flutter run -d windows
```

### 2. Hosting a Connection

1. Launch ForgeDesk.
2. In the **"This Device"** card, note your **9-Digit ID** (e.g. `496 835 401`) and **One-Time Password**.
3. Share your ID and password with your trusted partner.
4. Ensure the **Host Service** switch is enabled.

### 3. Controlling a Remote Machine

1. In the **"Control Remote Desk"** section, enter the partner's 9-Digit ID.
2. Enter their password.
3. Select your quality preset (**Balanced**, **Low Latency**, **Ultra HD**, or **View Only**).
4. Click **"Connect to Remote Desk"**.

---

## 🐳 Self-Hosting Guide

Run your own relay and rendezvous server with full control over server location, network speed, and privacy.

### Method A: Docker Compose (Recommended)

1. Navigate to the `deploy/` directory:
   ```bash
   cd deploy
   docker-compose up -d --build
   ```
2. Your server is now running on:
   - **Rendezvous Service**: `ws://<YOUR_SERVER_IP>:21115`
   - **Relay Service**: `ws://<YOUR_SERVER_IP>:21117`

### Method B: Standalone Binary

Compile and run `forgedesk-server` directly on your server:
```bash
cargo build --release --bin forgedesk-server

# Run with custom ports and optional auth key
./target/release/forgedesk-server \
  --bind 0.0.0.0 \
  --rendezvous-port 21115 \
  --relay-port 21117 \
  --server-key "your-private-secret-token"
```

### Method C: Configure Client for Self-Hosting

1. Open the ForgeDesk GUI.
2. Click the **Gear icon (⚙️)** in the top right to open **Server & Privacy Settings**.
3. Select **"Private Self-Hosted Server"**.
4. Enter your server's IP/domain and ports:
   - Rendezvous Server: `your-server.company.com:21115`
   - Relay Server: `your-server.company.com:21117`
   - Server Key: `your-private-secret-token` (if configured)
5. Click **"Save Configuration"**. Both peers will now route exclusively through your private infrastructure.

---

## 🛠️ Building from Source

### Prerequisites

- **Rust toolchain** (1.80+): `rustup default stable`
- **Flutter SDK** (3.24+): `flutter doctor`
- **C/C++ Build Tools**: MinGW-w64 (GCC) or Visual Studio MSVC on Windows; `build-essential` on Linux; Xcode CLI on macOS.

### Building All Components

#### On Windows:
```cmd
scripts\build_all.bat
```

#### On Linux / macOS:
```bash
chmod +x scripts/build_all.sh
./scripts/build_all.sh
```

### Cross-Platform Targets

- **Desktop (Windows / Linux / macOS)**:
  ```bash
  cd frontend
  flutter build windows
  flutter build linux
  flutter build macos
  ```
- **Mobile (Android / iOS)**:
  ```bash
  cd frontend
  flutter build apk --release
  flutter build ipa --release
  ```

---

## 🔐 Security Specifications

| Feature | Implementation |
|---|---|
| **ID Format** | 9-digit spaced integer (`xxx xxx xxx`) |
| **Authentication** | Dynamic cryptographic challenge + SHA-256 password hash |
| **Transport Encryption**| TLS 1.3 / End-to-End WebSocket stream |
| **Relay Privacy** | Zero-knowledge payload routing (server cannot decrypt frames) |
| **Input Sandboxing** | Host-configurable input permissions (Mouse, Keyboard, Clipboard) |

---

## 📄 License

ForgeDesk is open-source software licensed under the [MIT License](LICENSE).
Feel free to fork, customize, and self-host for personal or enterprise use.
