use crate::capture::create_default_capturer;
use crate::config::hash_password;
use crate::input::create_default_injector;
use crate::protocol::{PeerId, SessionPacket};
use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::{mpsc, RwLock};

pub struct HostSession {
    pub my_id: PeerId,
    pub temp_password: String,
    pub permanent_password_hash: Option<String>,
    pub is_running: Arc<AtomicBool>,
    pub active_client: Arc<RwLock<Option<ConnectedClientInfo>>>,
}

pub struct ConnectedClientInfo {
    pub client_id: PeerId,
    pub connected_at: Instant,
    pub to_client_tx: mpsc::Sender<SessionPacket>,
}

impl HostSession {
    pub fn new(
        my_id: PeerId,
        temp_password: String,
        permanent_password_hash: Option<String>,
    ) -> Self {
        Self {
            my_id,
            temp_password,
            permanent_password_hash,
            is_running: Arc::new(AtomicBool::new(false)),
            active_client: Arc::new(RwLock::new(None)),
        }
    }

    pub fn verify_credentials(&self, password_attempt: &str) -> bool {
        if password_attempt == self.temp_password {
            return true;
        }
        if let Some(permanent_hash) = &self.permanent_password_hash {
            let attempt_hash = hash_password(password_attempt);
            if &attempt_hash == permanent_hash {
                return true;
            }
        }
        false
    }

    /// Spawns the capture and streaming loop for an active client connection
    pub fn start_client_streaming(
        &self,
        client_id: PeerId,
        mut from_client_rx: mpsc::Receiver<SessionPacket>,
        to_client_tx: mpsc::Sender<SessionPacket>,
    ) -> tokio::task::JoinHandle<()> {
        let is_running = self.is_running.clone();
        is_running.store(true, Ordering::SeqCst);

        let active_client = self.active_client.clone();
        let client_id_clone = client_id.clone();
        let to_client_clone = to_client_tx.clone();

        tokio::spawn(async move {
            {
                let mut guard = active_client.write().await;
                *guard = Some(ConnectedClientInfo {
                    client_id: client_id_clone,
                    connected_at: Instant::now(),
                    to_client_tx: to_client_clone,
                });
            }

            let mut capturer = create_default_capturer();
            let mut injector = create_default_injector();
            let (w, h) = capturer.dimensions();

            // Send initial screen info
            let _ = to_client_tx
                .send(SessionPacket::ScreenInfo {
                    width: w,
                    height: h,
                    monitors: 1,
                })
                .await;

            let mut target_fps = 30u32;
            let mut jpeg_quality = 65u8;
            let mut view_only = false;
            let mut sequence = 0u64;

            let mut last_telemetry = Instant::now();
            let mut frames_this_second = 0u32;
            let mut bytes_this_second = 0u64;

            while is_running.load(Ordering::SeqCst) {
                let frame_start = Instant::now();

                // Process any incoming packets from client
                while let Ok(packet) = from_client_rx.try_recv() {
                    match packet {
                        SessionPacket::Input(input_event) => {
                            if !view_only {
                                if let Err(e) = injector.inject(&input_event) {
                                    tracing::warn!("Input injection failed: {:?}", e);
                                }
                            }
                        }
                        SessionPacket::QualityControl {
                            target_fps: fps,
                            jpeg_quality: q,
                            view_only: vo,
                        } => {
                            target_fps = fps.clamp(10, 60);
                            jpeg_quality = q.clamp(20, 95);
                            view_only = vo;
                        }
                        SessionPacket::Disconnect { reason } => {
                            tracing::info!("Client disconnected: {}", reason);
                            is_running.store(false, Ordering::SeqCst);
                            break;
                        }
                        _ => {}
                    }
                }

                if !is_running.load(Ordering::SeqCst) {
                    break;
                }

                // Capture and send desktop frame
                match capturer.capture(jpeg_quality) {
                    Ok(frame) => {
                        sequence = sequence.wrapping_add(1);
                        frames_this_second += 1;
                        bytes_this_second += frame.data.len() as u64;

                        let payload_b64 = BASE64.encode(&frame.data);
                        let packet = SessionPacket::Frame {
                            timestamp: std::time::SystemTime::now()
                                .duration_since(std::time::UNIX_EPOCH)
                                .unwrap_or_default()
                                .as_millis() as u64,
                            sequence,
                            format: frame.format,
                            width: frame.width,
                            height: frame.height,
                            payload_base64: payload_b64,
                        };

                        if to_client_tx.send(packet).await.is_err() {
                            tracing::info!("Client channel dropped, ending streaming");
                            break;
                        }
                    }
                    Err(e) => {
                        tracing::error!("Capture error: {:?}", e);
                        tokio::time::sleep(Duration::from_millis(100)).await;
                    }
                }

                // Periodic telemetry update (once per second)
                if last_telemetry.elapsed() >= Duration::from_secs(1) {
                    let elapsed = last_telemetry.elapsed().as_secs_f32();
                    let fps = frames_this_second as f32 / elapsed;
                    let bitrate_kbps = ((bytes_this_second * 8) as f32 / elapsed / 1000.0) as u32;

                    let _ = to_client_tx
                        .send(SessionPacket::Telemetry {
                            fps,
                            latency_ms: 15,
                            bitrate_kbps,
                        })
                        .await;

                    frames_this_second = 0;
                    bytes_this_second = 0;
                    last_telemetry = Instant::now();
                }

                // Frame rate pacing
                let frame_time = Duration::from_millis(1000 / target_fps as u64);
                let elapsed = frame_start.elapsed();
                if elapsed < frame_time {
                    tokio::time::sleep(frame_time - elapsed).await;
                }
            }

            let mut guard = active_client.write().await;
            *guard = None;
            tracing::info!("Host session streaming stopped for client {}", client_id);
        })
    }
}
