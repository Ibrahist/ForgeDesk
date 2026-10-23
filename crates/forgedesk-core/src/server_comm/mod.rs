use crate::protocol::{PeerId, SignalingMessage};
use futures_util::{SinkExt, StreamExt};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::mpsc;
use tokio_tungstenite::connect_async;
use tokio_tungstenite::tungstenite::Message;

pub struct SignalingClient {
    pub server_url: String,
    pub peer_id: PeerId,
    pub is_connected: Arc<AtomicBool>,
}

impl SignalingClient {
    pub fn new(server_url: String, peer_id: PeerId) -> Self {
        Self {
            server_url,
            peer_id,
            is_connected: Arc::new(AtomicBool::new(false)),
        }
    }

    /// Connects to the rendezvous server, registers our host ID, and enters heartbeat loop
    pub async fn start_signaling_loop(
        &self,
        alias: String,
        server_key: Option<String>,
        incoming_conn_tx: mpsc::Sender<(String, PeerId, String)>, // session_id, client_id, challenge
    ) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let ws_url = if self.server_url.starts_with("ws://") || self.server_url.starts_with("wss://") {
            self.server_url.clone()
        } else {
            format!("ws://{}", self.server_url)
        };

        tracing::info!("Connecting to rendezvous server: {}", ws_url);
        let (ws_stream, _) = connect_async(&ws_url).await?;
        let (mut write, mut read) = ws_stream.split();

        self.is_connected.store(true, Ordering::SeqCst);
        let is_connected = self.is_connected.clone();

        // Send Host Registration
        let register_msg = SignalingMessage::RegisterHost {
            peer_id: self.peer_id.clone(),
            alias,
            server_key,
            version: env!("CARGO_PKG_VERSION").to_string(),
        };
        let json = serde_json::to_string(&register_msg)?;
        write.send(Message::Text(json)).await?;

        // Background ping task
        let ping_connected = is_connected.clone();
        let (ping_tx, mut ping_rx) = mpsc::channel::<()>(4);
        tokio::spawn(async move {
            while ping_connected.load(Ordering::SeqCst) {
                tokio::time::sleep(Duration::from_secs(15)).await;
                if ping_tx.send(()).await.is_err() {
                    break;
                }
            }
        });

        // Loop handling incoming messages and pings
        loop {
            tokio::select! {
                Some(_) = ping_rx.recv() => {
                    let ping = SignalingMessage::Ping {
                        timestamp: std::time::SystemTime::now()
                            .duration_since(std::time::UNIX_EPOCH)
                            .unwrap_or_default()
                            .as_secs(),
                    };
                    if let Ok(json) = serde_json::to_string(&ping) {
                        if write.send(Message::Text(json)).await.is_err() {
                            break;
                        }
                    }
                }
                msg = read.next() => {
                    match msg {
                        Some(Ok(Message::Text(text))) => {
                            if let Ok(parsed) = serde_json::from_str::<SignalingMessage>(&text) {
                                match parsed {
                                    SignalingMessage::HostRegistered { success, message, assigned_id } => {
                                        tracing::info!("Registration status: {} ({}) for ID: {}", success, message, assigned_id);
                                    }
                                    SignalingMessage::IncomingConnection { session_id, client_id, auth_challenge } => {
                                        tracing::info!("Incoming connection from {} (session: {})", client_id, session_id);
                                        let _ = incoming_conn_tx.send((session_id, client_id, auth_challenge)).await;
                                    }
                                    SignalingMessage::Pong { .. } => {
                                        // Heartbeat acknowledged
                                    }
                                    _ => {}
                                }
                            }
                        }
                        Some(Ok(Message::Close(_))) | None => {
                            tracing::warn!("Signaling connection closed by server");
                            break;
                        }
                        _ => {}
                    }
                }
            }
        }

        is_connected.store(false, Ordering::SeqCst);
        Ok(())
    }
}
