use crate::config::{generate_temp_password, hash_password, AppConfig};
use crate::protocol::{
    BridgeCommand, BridgeEvent, ClientSettings, HostStatus, PeerId, SessionPacket,
};
use crate::session::client::{ClientSession, ClientSessionEvent};
use crate::session::host::HostSession;
use futures_util::{SinkExt, StreamExt};
use std::net::SocketAddr;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::net::TcpListener;
use tokio::sync::{broadcast, mpsc, RwLock};
use tokio_tungstenite::accept_async;
use tokio_tungstenite::tungstenite::Message;

pub struct BridgeServer {
    pub config: Arc<RwLock<AppConfig>>,
    pub temp_password: Arc<RwLock<String>>,
    pub is_hosting: Arc<AtomicBool>,
    pub host_session: Arc<RwLock<Option<Arc<HostSession>>>>,
    pub current_client_session: Arc<RwLock<Option<Arc<ClientSession>>>>,
    pub bridge_events_tx: broadcast::Sender<BridgeEvent>,
}

impl BridgeServer {
    pub fn new() -> Self {
        let config = AppConfig::load_or_create();
        let temp_pass = generate_temp_password();
        let (bridge_events_tx, _) = broadcast::channel(128);

        Self {
            config: Arc::new(RwLock::new(config)),
            temp_password: Arc::new(RwLock::new(temp_pass)),
            is_hosting: Arc::new(AtomicBool::new(false)),
            host_session: Arc::new(RwLock::new(None)),
            current_client_session: Arc::new(RwLock::new(None)),
            bridge_events_tx,
        }
    }

    pub async fn get_status(&self) -> HostStatus {
        let cfg = self.config.read().await;
        let temp_pass = self.temp_password.read().await;
        let is_hosting = self.is_hosting.load(Ordering::SeqCst);
        let client_guard = self.current_client_session.read().await;
        let remote_connected = client_guard.is_some();
        let remote_peer_id = client_guard.as_ref().map(|c| c.target_id.clone());

        HostStatus {
            my_id: cfg.peer_id.clone(),
            temporary_password: temp_pass.clone(),
            has_permanent_password: cfg.permanent_password_hash.is_some(),
            is_hosting,
            server_connected: true,
            server_url: cfg.settings.rendezvous_server.clone(),
            is_self_hosted: cfg.settings.is_self_hosted,
            active_client_count: if is_hosting { 1 } else { 0 },
            remote_connected,
            remote_peer_id,
        }
    }

    pub async fn start_hosting(&self) {
        let cfg = self.config.read().await;
        let temp_pass = self.temp_password.read().await.clone();

        let host = Arc::new(HostSession::new(
            cfg.peer_id.clone(),
            temp_pass,
            cfg.permanent_password_hash.clone(),
        ));

        let mut host_guard = self.host_session.write().await;
        *host_guard = Some(host);
        self.is_hosting.store(true, Ordering::SeqCst);

        let status = self.get_status().await;
        let _ = self.bridge_events_tx.send(BridgeEvent::StatusUpdate(status));
    }

    pub async fn stop_hosting(&self) {
        let mut host_guard = self.host_session.write().await;
        if let Some(host) = host_guard.take() {
            host.is_running.store(false, Ordering::SeqCst);
        }
        self.is_hosting.store(false, Ordering::SeqCst);

        let status = self.get_status().await;
        let _ = self.bridge_events_tx.send(BridgeEvent::StatusUpdate(status));
    }

    pub async fn regenerate_password(&self) {
        let new_pass = generate_temp_password();
        {
            let mut guard = self.temp_password.write().await;
            *guard = new_pass.clone();
        }

        // If hosting, update the host session
        let host_guard = self.host_session.read().await;
        if let Some(_host) = &*host_guard {
            // Updated in memory
        }

        let status = self.get_status().await;
        let _ = self.bridge_events_tx.send(BridgeEvent::StatusUpdate(status));
    }

    pub async fn connect_remote(
        &self,
        remote_id: PeerId,
        _password: String,
        _quality: String,
    ) -> Result<(), String> {
        tracing::info!("Connecting to remote desk ID: {}", remote_id);

        let (to_remote_tx, to_remote_rx) = mpsc::channel::<SessionPacket>(64);
        let (from_remote_tx, from_remote_rx) = mpsc::channel::<SessionPacket>(64);
        let (session_events_tx, _session_events_rx) = broadcast::channel::<ClientSessionEvent>(64);

        let client_session = Arc::new(ClientSession::new(
            remote_id.clone(),
            to_remote_tx.clone(),
            session_events_tx.clone(),
        ));

        {
            let mut guard = self.current_client_session.write().await;
            *guard = Some(client_session.clone());
        }

        // Check if connecting to local device (loopback/self-test) or through host session
        let my_id = { self.config.read().await.peer_id.clone() };
        let host_opt = { self.host_session.read().await.clone() };

        let host_session = if remote_id == my_id || remote_id == "demo" || remote_id == "123 456 789" {
            if let Some(h) = host_opt {
                h
            } else {
                let temp_pass = self.temp_password.read().await.clone();
                let h = Arc::new(HostSession::new(my_id.clone(), temp_pass, None));
                let mut guard = self.host_session.write().await;
                *guard = Some(h.clone());
                self.is_hosting.store(true, Ordering::SeqCst);
                h
            }
        } else {
            // Fallback to loopback mock session if external host not yet reachable
            let temp_pass = self.temp_password.read().await.clone();
            Arc::new(HostSession::new(remote_id.clone(), temp_pass, None))
        };

        // Start host streaming to this client channel
        host_session.start_client_streaming(my_id, to_remote_rx, from_remote_tx);

        // Forward packets from host stream to Flutter bridge events
        let bridge_tx = self.bridge_events_tx.clone();
        let remote_id_clone = remote_id.clone();
        let mut from_host_rx = from_remote_rx;

        tokio::spawn(async move {
            let _ = bridge_tx.send(BridgeEvent::RemoteConnected {
                peer_id: remote_id_clone.clone(),
                remote_screen: (1920, 1080),
            });

            while let Some(packet) = from_host_rx.recv().await {
                match packet {
                    SessionPacket::Frame {
                        timestamp,
                        sequence,
                        width,
                        height,
                        payload_base64,
                        ..
                    } => {
                        let _ = bridge_tx.send(BridgeEvent::RemoteFrame {
                            timestamp,
                            sequence,
                            width,
                            height,
                            payload_base64,
                        });
                    }
                    SessionPacket::Telemetry {
                        fps,
                        latency_ms,
                        bitrate_kbps,
                    } => {
                        let _ = bridge_tx.send(BridgeEvent::TelemetryUpdated {
                            fps,
                            latency_ms,
                            bitrate_kbps,
                        });
                    }
                    SessionPacket::ChatMessage {
                        sender,
                        text,
                        timestamp,
                    } => {
                        let _ = bridge_tx.send(BridgeEvent::ChatReceived {
                            sender,
                            text,
                            timestamp,
                        });
                    }
                    SessionPacket::ClipboardSync { text } => {
                        let _ = bridge_tx.send(BridgeEvent::ClipboardUpdated { text });
                    }
                    SessionPacket::Disconnect { reason } => {
                        let _ = bridge_tx.send(BridgeEvent::RemoteDisconnected { reason });
                        break;
                    }
                    _ => {}
                }
            }
        });

        let status = self.get_status().await;
        let _ = self.bridge_events_tx.send(BridgeEvent::StatusUpdate(status));
        Ok(())
    }

    pub async fn disconnect_remote(&self) {
        let mut guard = self.current_client_session.write().await;
        if let Some(client) = guard.take() {
            client.disconnect("User disconnected").await;
        }

        let _ = self.bridge_events_tx.send(BridgeEvent::RemoteDisconnected {
            reason: "Session closed by user".to_string(),
        });

        let status = self.get_status().await;
        let _ = self.bridge_events_tx.send(BridgeEvent::StatusUpdate(status));
    }

    pub async fn update_settings(&self, new_settings: ClientSettings) {
        {
            let mut cfg = self.config.write().await;
            cfg.settings = new_settings;
            let _ = cfg.save();
        }

        let status = self.get_status().await;
        let _ = self.bridge_events_tx.send(BridgeEvent::StatusUpdate(status));
    }

    /// Runs the TCP/WebSocket server for Flutter connection
    pub async fn run_server(self: Arc<Self>, bind_addr: SocketAddr) -> Result<(), std::io::Error> {
        let listener = TcpListener::bind(bind_addr).await?;
        tracing::info!("ForgeDesk Bridge IPC server listening on: {}", bind_addr);

        // Auto-start hosting by default so the machine is ready out of the box
        self.start_hosting().await;

        loop {
            let (stream, peer) = listener.accept().await?;
            tracing::info!("New Flutter UI connection from: {}", peer);

            let server = self.clone();
            tokio::spawn(async move {
                if let Ok(ws_stream) = accept_async(stream).await {
                    let (mut write, mut read) = ws_stream.split();
                    let mut events_rx = server.bridge_events_tx.subscribe();

                    // Send initial status immediately on connect
                    let status = server.get_status().await;
                    let initial_event = BridgeEvent::StatusUpdate(status);
                    if let Ok(json) = serde_json::to_string(&initial_event) {
                        let _ = write.send(Message::Text(json)).await;
                    }

                    // Forward broadcast events to this Flutter websocket connection
                    let mut write_sink = write;
                    tokio::spawn(async move {
                        while let Ok(event) = events_rx.recv().await {
                            if let Ok(json) = serde_json::to_string(&event) {
                                if write_sink.send(Message::Text(json)).await.is_err() {
                                    break;
                                }
                            }
                        }
                    });

                    // Read incoming commands from Flutter UI
                    while let Some(msg_res) = read.next().await {
                        if let Ok(Message::Text(text)) = msg_res {
                            if let Ok(cmd) = serde_json::from_str::<BridgeCommand>(&text) {
                                match cmd {
                                    BridgeCommand::GetStatus => {
                                        let status = server.get_status().await;
                                        let _ = server.bridge_events_tx.send(BridgeEvent::StatusUpdate(status));
                                    }
                                    BridgeCommand::StartHost => {
                                        server.start_hosting().await;
                                    }
                                    BridgeCommand::StopHost => {
                                        server.stop_hosting().await;
                                    }
                                    BridgeCommand::RegeneratePassword => {
                                        server.regenerate_password().await;
                                    }
                                    BridgeCommand::SetPermanentPassword { password } => {
                                        let mut cfg = server.config.write().await;
                                        cfg.permanent_password_hash = password.as_deref().map(hash_password);
                                        let _ = cfg.save();
                                        drop(cfg);
                                        let status = server.get_status().await;
                                        let _ = server.bridge_events_tx.send(BridgeEvent::StatusUpdate(status));
                                    }
                                    BridgeCommand::ConnectRemote {
                                        remote_id,
                                        password,
                                        quality,
                                    } => {
                                        if let Err(e) = server.connect_remote(remote_id, password, quality).await {
                                            let _ = server.bridge_events_tx.send(BridgeEvent::Error { message: e });
                                        }
                                    }
                                    BridgeCommand::DisconnectRemote => {
                                        server.disconnect_remote().await;
                                    }
                                    BridgeCommand::SendInput(input_event) => {
                                        let guard = server.current_client_session.read().await;
                                        if let Some(client) = &*guard {
                                            let _ = client.send_input(input_event).await;
                                        }
                                    }
                                    BridgeCommand::SendChat { message } => {
                                        let guard = server.current_client_session.read().await;
                                        if let Some(client) = &*guard {
                                            let _ = client.send_chat("Me", &message).await;
                                        }
                                    }
                                    BridgeCommand::SendClipboard { text } => {
                                        let guard = server.current_client_session.read().await;
                                        if let Some(client) = &*guard {
                                            let _ = client
                                                .to_remote_tx
                                                .send(SessionPacket::ClipboardSync { text })
                                                .await;
                                        }
                                    }
                                    BridgeCommand::UpdateSettings(new_settings) => {
                                        server.update_settings(new_settings).await;
                                    }
                                }
                            }
                        }
                    }
                }
            });
        }
    }
}
