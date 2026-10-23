use crate::protocol::{InputEvent, PeerId, SessionPacket};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::sync::{broadcast, mpsc};

pub struct ClientSession {
    pub target_id: PeerId,
    pub is_connected: Arc<AtomicBool>,
    pub to_remote_tx: mpsc::Sender<SessionPacket>,
    pub event_tx: broadcast::Sender<ClientSessionEvent>,
}

#[derive(Debug, Clone)]
pub enum ClientSessionEvent {
    ScreenInfo {
        width: u32,
        height: u32,
    },
    Frame {
        timestamp: u64,
        sequence: u64,
        width: u32,
        height: u32,
        payload_base64: String,
    },
    Telemetry {
        fps: f32,
        latency_ms: u32,
        bitrate_kbps: u32,
    },
    Chat {
        sender: String,
        text: String,
        timestamp: u64,
    },
    Clipboard {
        text: String,
    },
    Disconnected {
        reason: String,
    },
}

impl ClientSession {
    pub fn new(
        target_id: PeerId,
        to_remote_tx: mpsc::Sender<SessionPacket>,
        event_tx: broadcast::Sender<ClientSessionEvent>,
    ) -> Self {
        Self {
            target_id,
            is_connected: Arc::new(AtomicBool::new(true)),
            to_remote_tx,
            event_tx,
        }
    }

    pub async fn send_input(&self, event: InputEvent) -> Result<(), mpsc::error::SendError<SessionPacket>> {
        self.to_remote_tx.send(SessionPacket::Input(event)).await
    }

    pub async fn send_chat(&self, sender: &str, text: &str) -> Result<(), mpsc::error::SendError<SessionPacket>> {
        self.to_remote_tx
            .send(SessionPacket::ChatMessage {
                sender: sender.to_string(),
                text: text.to_string(),
                timestamp: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as u64,
            })
            .await
    }

    pub async fn update_quality(
        &self,
        fps: u32,
        quality: u8,
        view_only: bool,
    ) -> Result<(), mpsc::error::SendError<SessionPacket>> {
        self.to_remote_tx
            .send(SessionPacket::QualityControl {
                target_fps: fps,
                jpeg_quality: quality,
                view_only,
            })
            .await
    }

    pub async fn disconnect(&self, reason: &str) {
        self.is_connected.store(false, Ordering::SeqCst);
        let _ = self
            .to_remote_tx
            .send(SessionPacket::Disconnect {
                reason: reason.to_string(),
            })
            .await;
    }
}
