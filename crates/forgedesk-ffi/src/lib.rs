use forgedesk_core::bridge::BridgeServer;
use forgedesk_core::config::AppConfig;
use forgedesk_core::input::create_default_injector;
use forgedesk_core::protocol::{InputEvent, MouseButton};
use lazy_static::lazy_static;
use std::ffi::CString;
use std::os::raw::c_char;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

lazy_static! {
    static ref GLOBAL_RUNTIME: tokio::runtime::Runtime = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("Failed to initialize ForgeDesk Tokio runtime");
    static ref GLOBAL_BRIDGE: Mutex<Option<Arc<BridgeServer>>> = Mutex::new(None);
    static ref BRIDGE_RUNNING: AtomicBool = AtomicBool::new(false);
}

#[no_mangle]
pub extern "C" fn forgedesk_init() -> i32 {
    let mut bridge = GLOBAL_BRIDGE.lock().unwrap();
    if bridge.is_none() {
        *bridge = Some(Arc::new(BridgeServer::new()));
    }
    0
}

#[no_mangle]
pub extern "C" fn forgedesk_get_peer_id(buffer: *mut c_char, max_len: usize) -> i32 {
    let cfg = AppConfig::load_or_create();
    let id_cstr = match CString::new(cfg.peer_id) {
        Ok(s) => s,
        Err(_) => return -1,
    };
    let bytes = id_cstr.as_bytes_with_nul();
    if bytes.len() > max_len {
        return -2;
    }
    unsafe {
        std::ptr::copy_nonoverlapping(bytes.as_ptr() as *const c_char, buffer, bytes.len());
    }
    0
}

#[no_mangle]
pub extern "C" fn forgedesk_start_bridge(port: u16) -> i32 {
    if BRIDGE_RUNNING.load(Ordering::SeqCst) {
        return 0; // Already running
    }

    let bridge_opt = {
        let mut guard = GLOBAL_BRIDGE.lock().unwrap();
        if guard.is_none() {
            *guard = Some(Arc::new(BridgeServer::new()));
        }
        guard.clone()
    };

    if let Some(bridge) = bridge_opt {
        BRIDGE_RUNNING.store(true, Ordering::SeqCst);
        let addr = format!("127.0.0.1:{}", port).parse().unwrap_or(([127, 0, 0, 1], port).into());

        GLOBAL_RUNTIME.spawn(async move {
            if let Err(e) = bridge.run_server(addr).await {
                eprintln!("Bridge server encountered error: {:?}", e);
            }
            BRIDGE_RUNNING.store(false, Ordering::SeqCst);
        });
        0
    } else {
        -1
    }
}

#[no_mangle]
pub extern "C" fn forgedesk_inject_mouse(x: f32, y: f32, button: i32, is_down: i32) -> i32 {
    let mut injector = create_default_injector();
    let event = match button {
        0 => InputEvent::MouseMove { x, y },
        1 => {
            let btn = MouseButton::Left;
            if is_down != 0 {
                InputEvent::MouseDown { button: btn, x, y }
            } else {
                InputEvent::MouseUp { button: btn, x, y }
            }
        }
        2 => {
            let btn = MouseButton::Right;
            if is_down != 0 {
                InputEvent::MouseDown { button: btn, x, y }
            } else {
                InputEvent::MouseUp { button: btn, x, y }
            }
        }
        _ => return -1,
    };

    if injector.inject(&event).is_ok() {
        0
    } else {
        -2
    }
}

#[no_mangle]
pub extern "C" fn forgedesk_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}
