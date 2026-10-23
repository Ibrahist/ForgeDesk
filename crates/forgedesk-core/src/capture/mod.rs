pub mod fallback;
#[cfg(windows)]
pub mod windows;

use thiserror::Error;

#[derive(Error, Debug)]
pub enum CaptureError {
    #[error("Failed to initialize capture backend: {0}")]
    InitFailed(String),
    #[error("Failed to acquire display frame: {0}")]
    FrameAcquisitionFailed(String),
    #[error("Failed to encode frame: {0}")]
    EncodingFailed(String),
}

pub struct CapturedFrame {
    pub width: u32,
    pub height: u32,
    pub format: String,
    pub data: Vec<u8>,
}

pub trait ScreenCapturer: Send + Sync {
    fn capture(&mut self, quality: u8) -> Result<CapturedFrame, CaptureError>;
    fn dimensions(&self) -> (u32, u32);
}

pub fn create_default_capturer() -> Box<dyn ScreenCapturer> {
    #[cfg(windows)]
    {
        match windows::WindowsGdiCapturer::new() {
            Ok(cap) => Box::new(cap),
            Err(e) => {
                tracing::warn!("Failed to init Windows GDI capturer ({:?}), using fallback", e);
                Box::new(fallback::FallbackCapturer::new(1920, 1080))
            }
        }
    }
    #[cfg(not(windows))]
    {
        Box::new(fallback::FallbackCapturer::new(1920, 1080))
    }
}
