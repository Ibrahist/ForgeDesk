pub mod client;
pub mod host;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SessionState {
    Disconnected,
    Connecting,
    Authenticating,
    Connected,
    Terminated(String),
}
