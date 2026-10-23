use super::{CaptureError, CapturedFrame, ScreenCapturer};
use std::io::Cursor;
use windows_sys::Win32::Graphics::Gdi::{
    BitBlt, CreateCompatibleBitmap, CreateCompatibleDC, DeleteDC, DeleteObject, GetDIBits,
    GetDC, ReleaseDC, SelectObject, BITMAPINFO, BITMAPINFOHEADER, BI_RGB, DIB_RGB_COLORS,
    SRCCOPY,
};
use windows_sys::Win32::UI::WindowsAndMessaging::{
    GetSystemMetrics, SM_CXSCREEN, SM_CYSCREEN,
};

pub struct WindowsGdiCapturer {
    width: u32,
    height: u32,
    raw_buffer: Vec<u8>,
    rgb_buffer: Vec<u8>,
}

impl WindowsGdiCapturer {
    pub fn new() -> Result<Self, CaptureError> {
        unsafe {
            let width = GetSystemMetrics(SM_CXSCREEN) as u32;
            let height = GetSystemMetrics(SM_CYSCREEN) as u32;

            if width == 0 || height == 0 {
                return Err(CaptureError::InitFailed("Screen dimension is 0".to_string()));
            }

            let pixel_count = (width * height) as usize;
            Ok(Self {
                width,
                height,
                raw_buffer: vec![0u8; pixel_count * 4],
                rgb_buffer: vec![0u8; pixel_count * 3],
            })
        }
    }
}

impl ScreenCapturer for WindowsGdiCapturer {
    fn capture(&mut self, quality: u8) -> Result<CapturedFrame, CaptureError> {
        unsafe {
            let hdc_screen = GetDC(std::ptr::null_mut());
            if hdc_screen.is_null() {
                return Err(CaptureError::FrameAcquisitionFailed("GetDC(null) failed".to_string()));
            }

            let hdc_mem = CreateCompatibleDC(hdc_screen);
            if hdc_mem.is_null() {
                ReleaseDC(std::ptr::null_mut(), hdc_screen);
                return Err(CaptureError::FrameAcquisitionFailed("CreateCompatibleDC failed".to_string()));
            }

            let hbm = CreateCompatibleBitmap(hdc_screen, self.width as i32, self.height as i32);
            if hbm.is_null() {
                DeleteDC(hdc_mem);
                ReleaseDC(std::ptr::null_mut(), hdc_screen);
                return Err(CaptureError::FrameAcquisitionFailed("CreateCompatibleBitmap failed".to_string()));
            }

            let old_bm = SelectObject(hdc_mem, hbm);

            // Copy screen contents to memory DC
            let blt_res = BitBlt(
                hdc_mem,
                0,
                0,
                self.width as i32,
                self.height as i32,
                hdc_screen,
                0,
                0,
                SRCCOPY,
            );

            if blt_res == 0 {
                SelectObject(hdc_mem, old_bm);
                DeleteObject(hbm);
                DeleteDC(hdc_mem);
                ReleaseDC(std::ptr::null_mut(), hdc_screen);
                return Err(CaptureError::FrameAcquisitionFailed("BitBlt failed".to_string()));
            }

            let mut bmi = BITMAPINFO {
                bmiHeader: BITMAPINFOHEADER {
                    biSize: std::mem::size_of::<BITMAPINFOHEADER>() as u32,
                    biWidth: self.width as i32,
                    biHeight: -(self.height as i32), // Top-down DIB
                    biPlanes: 1,
                    biBitCount: 32,
                    biCompression: BI_RGB,
                    biSizeImage: 0,
                    biXPelsPerMeter: 0,
                    biYPelsPerMeter: 0,
                    biClrUsed: 0,
                    biClrImportant: 0,
                },
                bmiColors: [windows_sys::Win32::Graphics::Gdi::RGBQUAD {
                    rgbBlue: 0,
                    rgbGreen: 0,
                    rgbRed: 0,
                    rgbReserved: 0,
                }; 1],
            };

            let dib_res = GetDIBits(
                hdc_mem,
                hbm,
                0,
                self.height,
                self.raw_buffer.as_mut_ptr() as *mut _,
                &mut bmi,
                DIB_RGB_COLORS,
            );

            // Cleanup GDI objects
            SelectObject(hdc_mem, old_bm);
            DeleteObject(hbm);
            DeleteDC(hdc_mem);
            ReleaseDC(std::ptr::null_mut(), hdc_screen);

            if dib_res == 0 {
                return Err(CaptureError::FrameAcquisitionFailed("GetDIBits failed".to_string()));
            }

            // Convert BGRA to RGB for JPEG encoding
            let total_pixels = (self.width * self.height) as usize;
            for i in 0..total_pixels {
                let src_idx = i * 4;
                let dst_idx = i * 3;
                let b = self.raw_buffer[src_idx];
                let g = self.raw_buffer[src_idx + 1];
                let r = self.raw_buffer[src_idx + 2];
                self.rgb_buffer[dst_idx] = r;
                self.rgb_buffer[dst_idx + 1] = g;
                self.rgb_buffer[dst_idx + 2] = b;
            }

            // Encode to JPEG using image crate
            let mut jpeg_bytes = Vec::new();
            let mut cursor = Cursor::new(&mut jpeg_bytes);
            let mut encoder = image::codecs::jpeg::JpegEncoder::new_with_quality(&mut cursor, quality);
            encoder
                .encode(
                    &self.rgb_buffer,
                    self.width,
                    self.height,
                    image::ExtendedColorType::Rgb8,
                )
                .map_err(|e| CaptureError::EncodingFailed(e.to_string()))?;

            Ok(CapturedFrame {
                width: self.width,
                height: self.height,
                format: "jpeg".to_string(),
                data: jpeg_bytes,
            })
        }
    }

    fn dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
}
