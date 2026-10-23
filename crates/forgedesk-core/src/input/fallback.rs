use super::{InputError, InputInjector};
use crate::protocol::InputEvent;

pub struct FallbackInputInjector;

impl FallbackInputInjector {
    pub fn new() -> Self {
        Self
    }
}

impl InputInjector for FallbackInputInjector {
    fn inject(&mut self, event: &InputEvent) -> Result<(), InputError> {
        tracing::debug!("Mock input injector received: {:?}", event);
        Ok(())
    }
}
