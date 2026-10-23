use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::net::TcpListener;
use tokio::sync::{mpsc, RwLock};
use tokio_tungstenite::accept_async;
use tokio_tungstenite::tungstenite::Message;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RelayJoinMessage {
    pub session_id: String,
    pub role: String, // "host" or "client"
    pub peer_id: String,
}

struct RelayPeer {
    tx: mpsc::Sender<Message>,
}

#[derive(Default)]
struct RelaySession {
    host: Option<RelayPeer>,
    client: Option<RelayPeer>,
}

#[derive(Clone, Default)]
pub struct RelayServer {
    sessions: Arc<RwLock<HashMap<String, RelaySession>>>,
}

impl RelayServer {
    pub fn new() -> Self {
        Self {
            sessions: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub async fn run(&self, bind_addr: SocketAddr) -> Result<(), std::io::Error> {
        let listener = TcpListener::bind(bind_addr).await?;
        tracing::info!("Relay service listening on: {}", bind_addr);

        loop {
            let (stream, remote_addr) = listener.accept().await?;
            let server = self.clone();

            tokio::spawn(async move {
                if let Ok(ws_stream) = accept_async(stream).await {
                    let (write, mut read) = ws_stream.split();
                    let (peer_tx, mut peer_rx) = mpsc::channel::<Message>(64);

                    // Wait for the first message which must be the RelayJoinMessage
                    let join_msg = match read.next().await {
                        Some(Ok(Message::Text(text))) => {
                            serde_json::from_str::<RelayJoinMessage>(&text).ok()
                        }
                        _ => None,
                    };

                    let join = match join_msg {
                        Some(j) => j,
                        None => {
                            tracing::warn!("Relay connection from {} sent invalid handshake", remote_addr);
                            return;
                        }
                    };

                    let session_id = join.session_id.clone();
                    let is_host = join.role == "host";

                    tracing::info!(
                        "Relay participant joined: session={}, role={}, peer={}, addr={}",
                        session_id,
                        join.role,
                        join.peer_id,
                        remote_addr
                    );

                    // Forward queued messages to this peer's websocket sink
                    let mut write_sink = write;
                    tokio::spawn(async move {
                        while let Some(msg) = peer_rx.recv().await {
                            if write_sink.send(msg).await.is_err() {
                                break;
                            }
                        }
                    });

                    // Register into session
                    {
                        let mut sessions = server.sessions.write().await;
                        let session = sessions.entry(session_id.clone()).or_default();
                        if is_host {
                            session.host = Some(RelayPeer { tx: peer_tx.clone() });
                        } else {
                            session.client = Some(RelayPeer { tx: peer_tx.clone() });
                        }
                    }

                    // Forward incoming messages to the other side
                    while let Some(Ok(msg)) = read.next().await {
                        let sessions = server.sessions.read().await;
                        if let Some(session) = sessions.get(&session_id) {
                            let target_peer = if is_host {
                                session.client.as_ref()
                            } else {
                                session.host.as_ref()
                            };

                            if let Some(target) = target_peer {
                                let _ = target.tx.send(msg).await;
                            }
                        }
                    }

                    // Cleanup on disconnect
                    {
                        let mut sessions = server.sessions.write().await;
                        if let Some(session) = sessions.get_mut(&session_id) {
                            if is_host {
                                session.host = None;
                            } else {
                                session.client = None;
                            }
                            if session.host.is_none() && session.client.is_none() {
                                sessions.remove(&session_id);
                            }
                        }
                    }
                    tracing::info!("Relay participant departed: session={}", session_id);
                }
            });
        }
    }
}
