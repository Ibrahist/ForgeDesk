use super::{InputError, InputInjector};
use crate::protocol::{ActionType, InputEvent, MouseButton};
use windows_sys::Win32::UI::Input::KeyboardAndMouse::{
    SendInput, INPUT, INPUT_0, INPUT_KEYBOARD, INPUT_MOUSE, KEYBDINPUT, KEYEVENTF_KEYUP,
    MOUSEEVENTF_ABSOLUTE, MOUSEEVENTF_LEFTDOWN, MOUSEEVENTF_LEFTUP, MOUSEEVENTF_MIDDLEDOWN,
    MOUSEEVENTF_MIDDLEUP, MOUSEEVENTF_MOVE, MOUSEEVENTF_RIGHTDOWN, MOUSEEVENTF_RIGHTUP,
    MOUSEEVENTF_VIRTUALDESK, MOUSEEVENTF_WHEEL, MOUSEINPUT, VK_CONTROL, VK_DELETE, VK_LWIN,
    VK_MENU,
};
#[link(name = "user32")]
extern "system" {
    fn LockWorkStation() -> i32;
}

pub struct WindowsInputInjector;

impl WindowsInputInjector {
    pub fn new() -> Self {
        Self
    }

    fn send_mouse_input(&self, dx: i32, dy: i32, flags: u32, mouse_data: u32) -> Result<(), InputError> {
        let input = INPUT {
            r#type: INPUT_MOUSE,
            Anonymous: INPUT_0 {
                mi: MOUSEINPUT {
                    dx,
                    dy,
                    mouseData: mouse_data,
                    dwFlags: flags,
                    time: 0,
                    dwExtraInfo: 0,
                },
            },
        };

        unsafe {
            let sent = SendInput(1, &input, std::mem::size_of::<INPUT>() as i32);
            if sent == 0 {
                return Err(InputError::InjectionFailed("SendInput mouse failed".to_string()));
            }
        }
        Ok(())
    }

    fn send_key_input(&self, vk: u16, key_up: bool) -> Result<(), InputError> {
        let mut flags = 0u32;
        if key_up {
            flags |= KEYEVENTF_KEYUP;
        }

        let input = INPUT {
            r#type: INPUT_KEYBOARD,
            Anonymous: INPUT_0 {
                ki: KEYBDINPUT {
                    wVk: vk,
                    wScan: 0,
                    dwFlags: flags,
                    time: 0,
                    dwExtraInfo: 0,
                },
            },
        };

        unsafe {
            let sent = SendInput(1, &input, std::mem::size_of::<INPUT>() as i32);
            if sent == 0 {
                return Err(InputError::InjectionFailed("SendInput key failed".to_string()));
            }
        }
        Ok(())
    }
}

impl InputInjector for WindowsInputInjector {
    fn inject(&mut self, event: &InputEvent) -> Result<(), InputError> {
        match event {
            InputEvent::MouseMove { x, y } => {
                let dx = (*x * 65535.0) as i32;
                let dy = (*y * 65535.0) as i32;
                self.send_mouse_input(
                    dx,
                    dy,
                    MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE | MOUSEEVENTF_VIRTUALDESK,
                    0,
                )
            }
            InputEvent::MouseDown { button, x, y } => {
                let dx = (*x * 65535.0) as i32;
                let dy = (*y * 65535.0) as i32;
                let flag = match button {
                    MouseButton::Left => MOUSEEVENTF_LEFTDOWN,
                    MouseButton::Right => MOUSEEVENTF_RIGHTDOWN,
                    MouseButton::Middle => MOUSEEVENTF_MIDDLEDOWN,
                };
                self.send_mouse_input(
                    dx,
                    dy,
                    MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE | MOUSEEVENTF_VIRTUALDESK | flag,
                    0,
                )
            }
            InputEvent::MouseUp { button, x, y } => {
                let dx = (*x * 65535.0) as i32;
                let dy = (*y * 65535.0) as i32;
                let flag = match button {
                    MouseButton::Left => MOUSEEVENTF_LEFTUP,
                    MouseButton::Right => MOUSEEVENTF_RIGHTUP,
                    MouseButton::Middle => MOUSEEVENTF_MIDDLEUP,
                };
                self.send_mouse_input(
                    dx,
                    dy,
                    MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE | MOUSEEVENTF_VIRTUALDESK | flag,
                    0,
                )
            }
            InputEvent::MouseScroll { delta_y, .. } => {
                let wheel_delta = (*delta_y * 120.0) as i32;
                self.send_mouse_input(0, 0, MOUSEEVENTF_WHEEL, wheel_delta as u32)
            }
            InputEvent::KeyDown { key_code, .. } => self.send_key_input(*key_code as u16, false),
            InputEvent::KeyUp { key_code, .. } => self.send_key_input(*key_code as u16, true),
            InputEvent::Action { action_type } => match action_type {
                ActionType::LockWorkstation => unsafe {
                    LockWorkStation();
                    Ok(())
                },
                ActionType::CtrlAltDel => {
                    // Send Ctrl+Alt+Del simulation
                    let _ = self.send_key_input(VK_CONTROL, false);
                    let _ = self.send_key_input(VK_MENU, false);
                    let _ = self.send_key_input(VK_DELETE, false);
                    let _ = self.send_key_input(VK_DELETE, true);
                    let _ = self.send_key_input(VK_MENU, true);
                    let _ = self.send_key_input(VK_CONTROL, true);
                    Ok(())
                }
                ActionType::TaskbarToggle => {
                    let _ = self.send_key_input(VK_LWIN, false);
                    let _ = self.send_key_input(VK_LWIN, true);
                    Ok(())
                }
            },
        }
    }
}
