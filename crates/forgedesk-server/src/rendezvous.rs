use forgedesk_core::protocol::{PeerId, SignalingMessage};
use futures_util::{SinkExt, StreamExt};
use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::net::TcpListener;
use tokio::sync::{mpsc, RwLock};
use tokio_tungstenite::accept_async;
use tokio_tungstenite::tungstenite::Message;

#[allow(dead_code)]
pub struct RegisteredHost {
    pub peer_id: PeerId,
    pub alias: String,
    pub remote_addr: SocketAddr,
    pub to_host_tx: mpsc::Sender<SignalingMessage>,
}

#[derive(Clone)]
pub struct RendezvousServer {
    pub hosts: Arc<RwLock<HashMap<PeerId, RegisteredHost>>>,
    pub server_key: Option<String>,
}

impl RendezvousServer {
    pub fn new(server_key: Option<String>) -> Self {
        Self {
            hosts: Arc::new(RwLock::new(HashMap::new())),
            server_key,
        }
    }

    pub async fn run(&self, bind_addr: SocketAddr) -> Result<(), std::io::Error> {
        let listener = TcpListener::bind(bind_addr).await?;
        tracing::info!("Rendezvous service listening on: {}", bind_addr);

        loop {
            let (stream, remote_addr) = listener.accept().await?;
            let server = self.clone();

            tokio::spawn(async move {
                if let Ok(ws_stream) = accept_async(stream).await {
                    let (write, mut read) = ws_stream.split();
                    let (to_host_tx, mut to_host_rx) = mpsc::channel::<SignalingMessage>(32);
                    let mut registered_id: Option<PeerId> = None;

                    // Forward outbound messages from server queue to websocket
                    let mut write_sink = write;
                    tokio::spawn(async move {
                        while let Some(msg) = to_host_rx.recv().await {
                            if let Ok(json) = serde_json::to_string(&msg) {
                                if write_sink.send(Message::Text(json)).await.is_err() {
                                    break;
                                }
                            }
                        }
                    });

                    // Read incoming messages
                    while let Some(Ok(Message::Text(text))) = read.next().await {
                        if let Ok(msg) = serde_json::from_str::<SignalingMessage>(&text) {
                            match msg {
                                SignalingMessage::RegisterHost {
                                    peer_id,
                                    alias,
                                    server_key,
                                    version: _,
                                } => {
                                    // Verify server key if configured
                                    if let Some(expected_key) = &server.server_key {
                                        if server_key.as_deref() != Some(expected_key.as_str()) {
                                            let resp = SignalingMessage::HostRegistered {
                                                success: false,
                                                message: "Invalid server security key".to_string(),
                                                assigned_id: peer_id,
                                            };
                                            let _ = to_host_tx.send(resp).await;
                                            continue;
                                        }
                                    }

                                    tracing::info!(
                                        "Host registered: {} ('{}') from {}",
                                        peer_id,
                                        alias,
                                        remote_addr
                                    );

                                    registered_id = Some(peer_id.clone());
                                    {
                                        let mut hosts = server.hosts.write().await;
                                        hosts.insert(
                                            peer_id.clone(),
                                            RegisteredHost {
                                                peer_id: peer_id.clone(),
                                                alias,
                                                remote_addr,
                                                to_host_tx: to_host_tx.clone(),
                                            },
                                        );
                                    }

                                    let resp = SignalingMessage::HostRegistered {
                                        success: true,
                                        message: "Registered successfully with self-hosted server"
                                            .to_string(),
                                        assigned_id: peer_id,
                                    };
                                    let _ = to_host_tx.send(resp).await;
                                }
                                SignalingMessage::ConnectRequest {
                                    session_id,
                                    client_id,
                                    target_id,
                                    auth_challenge,
                                } => {
                                    tracing::info!(
                                        "Connect request: {} -> {} (session: {})",
                                        client_id,
                                        target_id,
                                        session_id
                                    );

                                    let hosts = server.hosts.read().await;
                                    if let Some(target_host) = hosts.get(&target_id) {
                                        let forward_req = SignalingMessage::IncomingConnection {
                                            session_id: session_id.clone(),
                                            client_id: client_id.clone(),
                                            auth_challenge,
                                        };
                                        let _ = target_host.to_host_tx.send(forward_req).await;
                                    } else {
                                        let resp = SignalingMessage::ConnectResult {
                                            session_id,
                                            accepted: false,
                                            relay_endpoint: None,
                                            reason: Some("Target host is offline or not found".to_string()),
                                        };
                                        let _ = to_host_tx.send(resp).await;
                                    }
                                }
                                SignalingMessage::ConnectResponse {
                                    session_id,
                                    accepted,
                                    reason: _,
                                } => {
                                    tracing::info!(
                                        "Host answered session {}: accepted={}",
                                        session_id,
                                        accepted
                                    );
                                }
                                SignalingMessage::Ping { timestamp } => {
                                    let pong = SignalingMessage::Pong { timestamp };
                                    let _ = to_host_tx.send(pong).await;
                                }
                                _ => {}
                            }
                        }
                    }

                    // On disconnect, remove from hosts registry
                    if let Some(id) = registered_id {
                        let mut hosts = server.hosts.write().await;
                        hosts.remove(&id);
                        tracing::info!("Host disconnected: {}", id);
                    }
                }
            });
        }
    }
}
