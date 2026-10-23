use serde::{Deserialize, Serialize};

/// Identifiers in ForgeDesk are formatted as 9-digit numbers (e.g., "123 456 789")
pub type PeerId = String;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum ServerMode {
    Public,
    SelfHosted,
}

/// Messages exchanged between ForgeDesk client and ForgeDesk rendezvous/relay server
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "payload")]
pub enum SignalingMessage {
    /// Host registers with the rendezvous server
    RegisterHost {
        peer_id: PeerId,
        alias: String,
        server_key: Option<String>,
        version: String,
    },
    /// Server acknowledges host registration
    HostRegistered {
        success: bool,
        message: String,
        assigned_id: PeerId,
    },
    /// Client initiates connection to target host
    ConnectRequest {
        session_id: String,
        client_id: PeerId,
        target_id: PeerId,
        auth_challenge: String,
    },
    /// Host receives connection request from client
    IncomingConnection {
        session_id: String,
        client_id: PeerId,
        auth_challenge: String,
    },
    /// Host responds to connection request (accept or reject)
    ConnectResponse {
        session_id: String,
        accepted: bool,
        reason: Option<String>,
    },
    /// Client receives connection response
    ConnectResult {
        session_id: String,
        accepted: bool,
        relay_endpoint: Option<String>,
        reason: Option<String>,
    },
    /// Heartbeat keepalive
    Ping { timestamp: u64 },
    Pong { timestamp: u64 },
    /// Session termination notification
    CloseSession {
        session_id: String,
        reason: String,
    },
}

/// Control and media packets streamed inside an active peer session (P2P or through relay)
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "kind", content = "data")]
pub enum SessionPacket {
    /// Authentication handshake with password hash
    Auth {
        client_id: PeerId,
        password_hash: String,
    },
    AuthResult {
        success: bool,
        message: String,
    },
    /// Screen metadata (dimensions, scale)
    ScreenInfo {
        width: u32,
        height: u32,
        monitors: u32,
    },
    /// Compressed frame data (JPEG/WebP/raw)
    Frame {
        timestamp: u64,
        sequence: u64,
        format: String, // "jpeg", "png", "raw"
        width: u32,
        height: u32,
        /// Frame bytes (Base64 encoded in JSON or raw binary if binary websocket)
        payload_base64: String,
    },
    /// Remote input events from client to host
    Input(InputEvent),
    /// Clipboard synchronization
    ClipboardSync {
        text: String,
    },
    /// In-session text chat
    ChatMessage {
        sender: String,
        text: String,
        timestamp: u64,
    },
    /// Quality and streaming performance adjustment
    QualityControl {
        target_fps: u32,
        jpeg_quality: u8, // 10..100
        view_only: bool,
    },
    /// Diagnostic telemetry (host to client)
    Telemetry {
        fps: f32,
        latency_ms: u32,
        bitrate_kbps: u32,
    },
    /// Disconnect request
    Disconnect {
        reason: String,
    },
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum MouseButton {
    Left,
    Right,
    Middle,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "event", content = "params")]
pub enum InputEvent {
    /// Normalized coordinates: x: 0.0..1.0, y: 0.0..1.0
    MouseMove { x: f32, y: f32 },
    MouseDown { button: MouseButton, x: f32, y: f32 },
    MouseUp { button: MouseButton, x: f32, y: f32 },
    MouseScroll { delta_x: f32, delta_y: f32 },
    KeyDown { key_code: u32, key: String },
    KeyUp { key_code: u32, key: String },
    /// Quick action commands
    Action { action_type: ActionType },
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum ActionType {
    CtrlAltDel,
    LockWorkstation,
    TaskbarToggle,
}

/// Commands and events between Flutter UI and local ForgeDesk Core daemon
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "cmd", content = "data")]
pub enum BridgeCommand {
    GetStatus,
    StartHost,
    StopHost,
    RegeneratePassword,
    SetPermanentPassword { password: Option<String> },
    ConnectRemote {
        remote_id: PeerId,
        password: String,
        quality: String, // "low", "balanced", "high", "view_only"
    },
    DisconnectRemote,
    SendInput(InputEvent),
    SendChat { message: String },
    SendClipboard { text: String },
    UpdateSettings(ClientSettings),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "event", content = "data")]
pub enum BridgeEvent {
    StatusUpdate(HostStatus),
    RemoteFrame {
        timestamp: u64,
        sequence: u64,
        width: u32,
        height: u32,
        payload_base64: String,
    },
    RemoteConnected {
        peer_id: PeerId,
        remote_screen: (u32, u32),
    },
    RemoteDisconnected {
        reason: String,
    },
    ChatReceived {
        sender: String,
        text: String,
        timestamp: u64,
    },
    ClipboardUpdated {
        text: String,
    },
    TelemetryUpdated {
        fps: f32,
        latency_ms: u32,
        bitrate_kbps: u32,
    },
    Error {
        message: String,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HostStatus {
    pub my_id: PeerId,
    pub temporary_password: String,
    pub has_permanent_password: bool,
    pub is_hosting: bool,
    pub server_connected: bool,
    pub server_url: String,
    pub is_self_hosted: bool,
    pub active_client_count: usize,
    pub remote_connected: bool,
    pub remote_peer_id: Option<PeerId>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClientSettings {
    pub rendezvous_server: String,
    pub relay_server: String,
    pub server_key: String,
    pub is_self_hosted: bool,
    pub alias: String,
    pub default_quality: String,
    pub allow_remote_input: bool,
    pub sync_clipboard: bool,
}

impl Default for ClientSettings {
    fn default() -> Self {
        Self {
            rendezvous_server: "127.0.0.1:21115".to_string(),
            relay_server: "127.0.0.1:21117".to_string(),
            server_key: "".to_string(),
            is_self_hosted: false,
            alias: "ForgeDesk Desktop".to_string(),
            default_quality: "balanced".to_string(),
            allow_remote_input: true,
            sync_clipboard: true,
        }
    }
}
