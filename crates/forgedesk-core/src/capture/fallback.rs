use super::{CaptureError, CapturedFrame, ScreenCapturer};
use std::io::Cursor;

pub struct FallbackCapturer {
    width: u32,
    height: u32,
    frame_count: u64,
    rgb_buffer: Vec<u8>,
}

impl FallbackCapturer {
    pub fn new(width: u32, height: u32) -> Self {
        let size = (width * height * 3) as usize;
        Self {
            width,
            height,
            frame_count: 0,
            rgb_buffer: vec![0u8; size],
        }
    }

    fn render_test_frame(&mut self) {
        self.frame_count = self.frame_count.wrapping_add(1);
        let t = (self.frame_count % 360) as f32;
        let cx = ((self.width as f32 / 2.0) + (t * 0.05).sin() * 200.0) as i32;
        let cy = ((self.height as f32 / 2.0) + (t * 0.05).cos() * 150.0) as i32;

        let w = self.width as i32;
        let h = self.height as i32;

        for y in 0..h {
            for x in 0..w {
                let idx = ((y * w + x) * 3) as usize;

                // Subtle dark futuristic gradient
                let mut r = ((x * 35) / w) as u8;
                let mut g = ((y * 45) / h) as u8 + 15;
                let mut b = 35u8;

                // Grid lines every 100 pixels
                if x % 100 == 0 || y % 100 == 0 {
                    r = r.saturating_add(30);
                    g = g.saturating_add(40);
                    b = b.saturating_add(60);
                }

                // Moving pointer indicator
                let dx = x - cx;
                let dy = y - cy;
                if dx * dx + dy * dy < 144 {
                    r = 0;
                    g = 240;
                    b = 255; // Electric cyan
                }

                self.rgb_buffer[idx] = r;
                self.rgb_buffer[idx + 1] = g;
                self.rgb_buffer[idx + 2] = b;
            }
        }
    }
}

impl ScreenCapturer for FallbackCapturer {
    fn capture(&mut self, quality: u8) -> Result<CapturedFrame, CaptureError> {
        self.render_test_frame();

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

    fn dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
}
