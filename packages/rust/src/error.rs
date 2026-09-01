use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BoardingPassErrorCode {
    InvalidPassFormat,
    InvalidSegments,
    DataFailedValidation,
    DataIsNotBoardingPass,
    MandatoryItemNotFound,
    DataFailedStringDecoding,
    FieldValueNotRequiredInteger,
    HexStringFailedDecoding,
    ConditionalIndexInvalid,
    BoardingPassLegConditionalMismatch,
    InvalidJulianDay,
    QRCodeNotFound,
    UnsupportedImageFormat,
    ImageDecodeFailed,
    Unexpected,
}

#[derive(Debug, Error)]
#[error("{message}")]
pub struct BoardingPassError {
    pub code: BoardingPassErrorCode,
    pub message: String,
}

impl BoardingPassError {
    pub fn new(code: BoardingPassErrorCode, message: impl Into<String>) -> Self {
        Self {
            code,
            message: message.into(),
        }
    }

    pub fn invalid_pass_format(format: &str) -> Self {
        Self::new(
            BoardingPassErrorCode::InvalidPassFormat,
            format!("Invalid boarding pass format: {format}"),
        )
    }

    pub fn invalid_segments(legs: i32) -> Self {
        Self::new(
            BoardingPassErrorCode::InvalidSegments,
            format!("Invalid number of boarding pass segments {legs}"),
        )
    }

    pub fn data_failed_validation(code: &str) -> Self {
        Self::new(
            BoardingPassErrorCode::DataFailedValidation,
            format!("Data provided failed boarding pass validation: {code}"),
        )
    }

    pub fn data_is_not_boarding_pass(message: impl Into<String>) -> Self {
        Self::new(
            BoardingPassErrorCode::DataIsNotBoardingPass,
            format!("Data provided is not a boarding pass: {}", message.into()),
        )
    }

    pub fn mandatory_item_not_found(index: usize) -> Self {
        Self::new(
            BoardingPassErrorCode::MandatoryItemNotFound,
            format!("Mandatory field value is not found at index {index}"),
        )
    }

    pub fn data_failed_string_decoding() -> Self {
        Self::new(
            BoardingPassErrorCode::DataFailedStringDecoding,
            "Data fail .ascii String decoding",
        )
    }

    pub fn field_value_not_required_integer(value: &str) -> Self {
        Self::new(
            BoardingPassErrorCode::FieldValueNotRequiredInteger,
            format!("Field value {value} is supposed to be an integer and is not"),
        )
    }

    pub fn hex_string_failed_decoding(string: &str) -> Self {
        Self::new(
            BoardingPassErrorCode::HexStringFailedDecoding,
            format!("String {string} failed to decode as hexidecimal"),
        )
    }

    pub fn conditional_index_invalid(end_conditional: i32, sub_conditional: i32) -> Self {
        Self::new(
            BoardingPassErrorCode::ConditionalIndexInvalid,
            format!(
                "Conditional parsing failed due to endConditional {end_conditional} or subConditional {sub_conditional}"
            ),
        )
    }

    pub fn boarding_pass_leg_conditional_mismatch() -> Self {
        Self::new(
            BoardingPassErrorCode::BoardingPassLegConditionalMismatch,
            "Boarding pass leg conditional mismatches parsing index",
        )
    }

    pub fn invalid_julian_day(day_of_year: i32) -> Self {
        Self::new(
            BoardingPassErrorCode::InvalidJulianDay,
            format!("Invalid Julian day of year: {day_of_year}"),
        )
    }

    pub fn unexpected(code: i32) -> Self {
        Self::new(
            BoardingPassErrorCode::Unexpected,
            format!("Error code {code} occured."),
        )
    }

    pub fn qr_code_not_found() -> Self {
        Self::new(
            BoardingPassErrorCode::QRCodeNotFound,
            "No QR code was found in the image",
        )
    }

    pub fn unsupported_image_format(detail: impl Into<String>) -> Self {
        Self::new(
            BoardingPassErrorCode::UnsupportedImageFormat,
            format!("Unsupported image format: {}", detail.into()),
        )
    }

    pub fn image_decode_failed(detail: impl Into<String>) -> Self {
        Self::new(
            BoardingPassErrorCode::ImageDecodeFailed,
            format!("Failed to decode image: {}", detail.into()),
        )
    }
}
