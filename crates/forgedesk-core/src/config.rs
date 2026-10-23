use crate::protocol::{ClientSettings, PeerId};
use rand::Rng;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub peer_id: PeerId,
    pub permanent_password_hash: Option<String>,
    pub settings: ClientSettings,
}

impl AppConfig {
    pub fn new() -> Self {
        let peer_id = generate_peer_id();
        Self {
            peer_id,
            permanent_password_hash: None,
            settings: ClientSettings::default(),
        }
    }

    pub fn load_or_create() -> Self {
        let path = config_file_path();
        if let Ok(content) = std::fs::read_to_string(&path) {
            if let Ok(config) = serde_json::from_str::<AppConfig>(&content) {
                return config;
            }
        }
        let config = Self::new();
        let _ = config.save();
        config
    }

    pub fn save(&self) -> Result<(), std::io::Error> {
        let path = config_file_path();
        if let Some(parent) = path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        let json = serde_json::to_string_pretty(self).map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        std::fs::write(path, json)
    }
}

pub fn generate_peer_id() -> PeerId {
    let mut rng = rand::thread_rng();
    let n1: u32 = rng.gen_range(100..999);
    let n2: u32 = rng.gen_range(100..999);
    let n3: u32 = rng.gen_range(100..999);
    format!("{} {} {}", n1, n2, n3)
}

pub fn generate_temp_password() -> String {
    const CHARSET: &[u8] = b"abcdefghijkmnpqrstuvwxyz23456789";
    let mut rng = rand::thread_rng();
    (0..6)
        .map(|_| {
            let idx = rng.gen_range(0..CHARSET.len());
            CHARSET[idx] as char
        })
        .collect()
}

pub fn hash_password(password: &str) -> String {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(password.as_bytes());
    hex::encode(hasher.finalize())
}

fn config_file_path() -> PathBuf {
    let mut dir = dirs_next_fallback();
    dir.push("ForgeDesk");
    dir.push("config.json");
    dir
}

fn dirs_next_fallback() -> PathBuf {
    if let Ok(app_data) = std::env::var("APPDATA") {
        PathBuf::from(app_data)
    } else if let Ok(home) = std::env::var("USERPROFILE") {
        PathBuf::from(home)
    } else if let Ok(home) = std::env::var("HOME") {
        PathBuf::from(home)
    } else {
        std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."))
    }
}
