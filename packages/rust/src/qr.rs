use std::collections::HashSet;
use std::io::Cursor;

use image::io::Reader as ImageReader;
use image::{DynamicImage, GrayImage};
use rqrr::PreparedImage;
use rxing::{
    BarcodeFormat, BinaryBitmap, DecodeHints, Luma8LuminanceSource, MultiFormatReader, Reader,
};
use rxing::common::HybridBinarizer;

use crate::BoardingPassError;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum ImageKind {
    Png,
    Jpeg,
    Heic,
}

/// Extract the first QR, Aztec, or PDF417 payload from PNG, JPEG, or HEIC image bytes.
///
/// HEIC requires the `heic` Cargo feature (system `libheif`).
pub fn extract_qr_payload(bytes: &[u8]) -> Result<String, BoardingPassError> {
    let kind = detect_format(bytes)?;
    let luma = match kind {
        ImageKind::Png | ImageKind::Jpeg => decode_raster_luma(bytes)?,
        ImageKind::Heic => decode_heic_luma(bytes)?,
    };
    find_barcode_payload(luma)
}

fn detect_format(bytes: &[u8]) -> Result<ImageKind, BoardingPassError> {
    if bytes.len() >= 8 && bytes.starts_with(&[0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A]) {
        return Ok(ImageKind::Png);
    }
    if bytes.len() >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
        return Ok(ImageKind::Jpeg);
    }
    if is_heif(bytes) {
        return Ok(ImageKind::Heic);
    }
    Err(BoardingPassError::unsupported_image_format(
        "expected PNG, JPEG, or HEIC",
    ))
}

fn is_heif(bytes: &[u8]) -> bool {
    if bytes.len() < 12 || &bytes[4..8] != b"ftyp" {
        return false;
    }
    heif_brand(&bytes[8..12]) || compatible_heif_brand(bytes)
}

fn heif_brand(brand: &[u8]) -> bool {
    matches!(
        brand,
        b"heic" | b"heix" | b"heif" | b"hevc" | b"hevx" | b"mif1" | b"msf1"
    )
}

fn compatible_heif_brand(bytes: &[u8]) -> bool {
    // ISO-BMFF: size (4) + 'ftyp' (4) + major (4) + minor (4) + compatible brands
    if bytes.len() < 16 {
        return false;
    }
    let box_size = u32::from_be_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]) as usize;
    let end = box_size.min(bytes.len());
    let mut offset = 16;
    while offset + 4 <= end {
        if heif_brand(&bytes[offset..offset + 4]) {
            return true;
        }
        offset += 4;
    }
    false
}

fn decode_raster_luma(bytes: &[u8]) -> Result<GrayImage, BoardingPassError> {
    let reader = ImageReader::new(Cursor::new(bytes))
        .with_guessed_format()
        .map_err(|e| BoardingPassError::image_decode_failed(e.to_string()))?;
    let img: DynamicImage = reader
        .decode()
        .map_err(|e| BoardingPassError::image_decode_failed(e.to_string()))?;
    Ok(img.to_luma8())
}

#[cfg(feature = "heic")]
fn decode_heic_luma(bytes: &[u8]) -> Result<GrayImage, BoardingPassError> {
    use libheif_rs::{ColorSpace, HeifContext, LibHeif, RgbChroma};

    let lib_heif = LibHeif::new();
    let ctx = HeifContext::read_from_bytes(bytes)
        .map_err(|e| BoardingPassError::image_decode_failed(e.to_string()))?;
    let handle = ctx
        .primary_image_handle()
        .map_err(|e| BoardingPassError::image_decode_failed(e.to_string()))?;
    let image = lib_heif
        .decode(&handle, ColorSpace::Rgb(RgbChroma::Rgb), None)
        .map_err(|e| BoardingPassError::image_decode_failed(e.to_string()))?;

    let width = image.width();
    let height = image.height();
    let planes = image.planes();
    let plane = planes.interleaved.ok_or_else(|| {
        BoardingPassError::image_decode_failed("HEIC decode produced no interleaved RGB plane")
    })?;

    let mut luma = GrayImage::new(width, height);
    for y in 0..height {
        let row_start = (y as usize) * plane.stride;
        for x in 0..width {
            let i = row_start + (x as usize) * 3;
            let r = plane.data[i] as u32;
            let g = plane.data[i + 1] as u32;
            let b = plane.data[i + 2] as u32;
            let yv = ((r * 77 + g * 150 + b * 29) >> 8) as u8;
            luma.put_pixel(x, y, image::Luma([yv]));
        }
    }
    Ok(luma)
}

#[cfg(not(feature = "heic"))]
fn decode_heic_luma(_bytes: &[u8]) -> Result<GrayImage, BoardingPassError> {
    Err(BoardingPassError::unsupported_image_format(
        "HEIC support requires the `heic` Cargo feature (system libheif)",
    ))
}

fn find_barcode_payload(luma: GrayImage) -> Result<String, BoardingPassError> {
    let mut current = luma;
    for _ in 0..4 {
        if let Some(payload) = decode_qr_once(&current) {
            return Ok(payload);
        }
        if let Some(payload) = decode_zxing_once(&current) {
            return Ok(payload);
        }
        current = image::imageops::rotate90(&current);
    }
    Err(BoardingPassError::qr_code_not_found())
}

fn decode_qr_once(luma: &GrayImage) -> Option<String> {
    let width = luma.width() as usize;
    let height = luma.height() as usize;
    let mut prepared = PreparedImage::prepare_from_greyscale(width, height, |x, y| {
        luma.get_pixel(x as u32, y as u32)[0]
    });
    for grid in prepared.detect_grids() {
        if let Ok((_, content)) = grid.decode() {
            if !content.is_empty() {
                return Some(content);
            }
        }
    }
    None
}

fn decode_zxing_once(luma: &GrayImage) -> Option<String> {
    let width = luma.width();
    let height = luma.height();
    let source = Luma8LuminanceSource::new(luma.as_raw().clone(), width, height);
    let mut bitmap = BinaryBitmap::new(HybridBinarizer::new(source));
    let hints = DecodeHints {
        PossibleFormats: Some(HashSet::from([
            BarcodeFormat::AZTEC,
            BarcodeFormat::PDF_417,
        ])),
        TryHarder: Some(true),
        AlsoInverted: Some(true),
        CharacterSet: Some("ISO-8859-1".into()),
        ..DecodeHints::default()
    };
    let mut reader = MultiFormatReader::default();
    match reader.decode_with_hints(&mut bitmap, &hints) {
        Ok(result) => {
            let text = result.getText().to_string();
            if text.is_empty() {
                None
            } else {
                Some(text)
            }
        }
        Err(_) => None,
    }
}
