pub mod fallback;
#[cfg(windows)]
pub mod windows;

use crate::protocol::InputEvent;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum InputError {
    #[error("Failed to inject input event: {0}")]
    InjectionFailed(String),
}

pub trait InputInjector: Send + Sync {
    fn inject(&mut self, event: &InputEvent) -> Result<(), InputError>;
}

pub fn create_default_injector() -> Box<dyn InputInjector> {
    #[cfg(windows)]
    {
        Box::new(windows::WindowsInputInjector::new())
    }
    #[cfg(not(windows))]
    {
        Box::new(fallback::FallbackInputInjector::new())
    }
}
