# IATA BCBP Standard Compliance

## Standard Information

**Implementation Guide:** IATA Resolution 792 - Bar Coded Boarding Pass (BCBP)  
**Version:** 8 (Effective: June 1, 2020) ✅  
**Previous Version:** [Version 7 Implementation Guide](https://www.iata.org/contentassets/1dccc9ed041b4f3bbdcf8ee8682e75c4/2021_03_02-bcbp-implementation-guide-version-7-.pdf)  
**Official Reference:** [IATA Common Use Standards](https://www.iata.org/en/programs/passenger/common-use/)

## Compliance Status

### ✅ Fully Implemented

#### Mandatory Items (60 characters)
- [x] Format Code (1 char) - 'M' or 'S'
- [x] Number of Legs (1 char)
- [x] Passenger Name (20 chars)
- [x] Electronic Ticket Indicator (1 char)
- [x] PNR Code (7 chars)
- [x] From City Airport Code (3 chars)
- [x] To City Airport Code (3 chars)
- [x] Operating Carrier Designator (3 chars)
- [x] Flight Number (5 chars)
- [x] Date of Flight - Julian Date (3 chars)
- [x] Compartment Code (1 char)
- [x] Seat Number (4 chars)
- [x] Check-In Sequence Number (5 chars)
- [x] Passenger Status (1 char)
- [x] Field Size of Variable Size Field (2 chars - hex)

#### Conditional Items
- [x] Beginning of Version Number (1 char)
- [x] Version Number (1 char)
- [x] Unique Conditional Items Size (2 chars - hex)
- [x] Passenger Description / Gender Code (1 char) - **Version 8 compliant** with "X" and "U" support
- [x] Source of Check-In (1 char)
- [x] Source of Boarding Pass Issuance (1 char)
- [x] Date of Issue of Boarding Pass (4 chars)
- [x] Document Type (1 char)
- [x] Airline Designator of Boarding Pass Issuer (3 chars)
- [x] Baggage Tag License Plate Numbers (13 chars each, up to 3 tags)
- [x] Airline Numeric Code (3 chars)
- [x] Document Serial Number (10 chars)
- [x] Selectee Indicator (1 char)
- [x] International Document Verification (1 char)
- [x] Marketing Carrier (3 chars)
- [x] Frequent Flyer Airline Designator (3 chars)
- [x] Frequent Flyer Number (16 chars)
- [x] ID/AD Indicator (1 char)
- [x] Free Baggage Allowance (3 chars)
- [x] Fast Track (1 char)
- [x] Airline Individual Use (variable)

#### Repeated Conditional Items (for additional legs)
- [x] All segment fields properly parsed from conditional section

#### Security Data
- [x] Beginning of Security Data indicator '>' (1 char)
- [x] Type of Security Data (1 char)
- [x] Length of Security Data (2 chars - hex)
- [x] Security Data (variable length)

### ✅ Supported Barcode Formats

According to IATA Resolution 792, BCBP can be encoded in:
- [x] PDF417 (most common)
- [x] Aztec
- [x] QR Code
- [x] Data Matrix

**Note:** The BCBP parser decodes the ASCII data structure regardless of the barcode symbology used. Node, Swift, Rust, and the Python/Go/PHP bindings can also read that ASCII payload from a **QR, Aztec, or PDF417** barcode in PNG, JPEG, or HEIC images (`extractQrPayload` / `extract_qr_payload` / `BoardingPassQRExtractor`). Data Matrix image scanning is not implemented — that still requires an external scanner.

### 📋 Version Information

**Important:** There are two different "versions" related to BCBP:

1. **IATA Implementation Guide Version** (Document)
   - Current: **Version 8** (June 1, 2020) ✅
   - Previous: Version 7 (June 1, 2018)
   - This is the specification document version

2. **Boarding Pass Format Version** (Data Field)
   - Single character field in the boarding pass data
   - Located at the start of conditional items
   - Values: "5", "6", "7", etc.
   - Indicates conditional items structure version
   - Parsed and stored in `BoardingPass.version`

### 🆕 Version 8 Changes (Effective June 1, 2020)

**Field 15 - Passenger Description / Gender Code:**
- Added **"X"** = Unspecified gender
- Added **"U"** = Undisclosed gender
- Existing codes (M, F, 0-9) remain valid

**Status:** ✅ Fully supported - the library already parses this field correctly

### ⚠️ Known Limitations

1. **Field Validation:** The parser does not validate field values against IATA code tables (e.g., airport codes, carrier codes)
2. **Date Conversion:** Julian day-of-year is converted to calendar dates via `JulianDateConverter` (Swift) or `julianToCalendarDate` (Node). Year must be supplied or inferred — BCBP does not encode the year.
3. **Year Rollover:** Year inference uses a ±183-day heuristic; edge cases near year boundaries may need an explicit year from your application context.
4. **Non-Standard Formats:** Some airlines may use proprietary variations that don't strictly follow IATA standard

### 🔧 Recent Updates

- **Version 8 Compliance:** Updated to IATA Resolution 792 Version 8 (June 2020) - supports new gender codes X and U
- **Segment Parsing:** Fixed critical bug where subsequent flight segments incorrectly used mandatory parsing instead of conditional
- **Loop Bounds:** Fixed off-by-one errors in bag tag and segment loops
- **Error Handling:** Improved error messages for conditional parsing failures
- **Documentation:** Added comprehensive field documentation and IATA standard references

### 📚 References

- [IATA Resolution 792](https://www.iata.org/en/publications/store/resolution-792/)
- [BCBP Implementation Guide Version 7 (PDF)](https://www.iata.org/contentassets/1dccc9ed041b4f3bbdcf8ee8682e75c4/2021_03_02-bcbp-implementation-guide-version-7-.pdf)
- [IATA Standards](https://www.iata.org/en/programs/passenger/common-use/)

## Testing

The library includes test cases for:
- Single-leg boarding passes (M1)
- Multi-leg boarding passes (M2, M3)
- Various airlines and formats
- Security data variations
- Conditional items edge cases
- QR, Aztec, and PDF417 extraction from PNG, JPEG, and HEIC fixtures under `testdata/images/`

To run tests:
```bash
npm test
cargo test -p boarding-pass-kit
swift test   # macOS
```

## Version History

- **2.3.1 / Rust 0.2.1** - Image barcode extraction for QR, Aztec, and PDF417
  - Same `extractQrPayload` / `extract_qr_payload` / `BoardingPassQRExtractor` APIs now scan QR, Aztec, and PDF417
  - Shared fixtures: `testdata/images/simple_aztec.png`, `testdata/images/simple_pdf417.png`
  - Data Matrix image scanning is still not implemented
- **2.3.0 / Rust 0.2.0** - Image QR extraction
  - Extract a QR payload from PNG, JPEG, or HEIC and feed it to the existing BCBP decoder
  - Node (`extractQrPayload` / `decodeFromImage`), Swift (`BoardingPassQRExtractor`), Rust (`extract_qr_payload`), FFI (`bpk_extract_qr`), Python / Go / PHP wrappers
  - Rust HEIC support is gated on the `heic` Cargo feature (system libheif)
- **2.0.2** - CocoaPods naming update
  - Renamed CocoaPods pod from BoardingPassKit to BoardingPassParser to avoid conflicts
  - Swift Package Manager remains as BoardingPassKit
  - No functional changes, packaging update only
- **2.0.1** - Patch release with improved configuration options
  - Enhanced data processing with configurable trim options
  - Better handling of empty strings and whitespace
  - Improved debugging capabilities
- **2.0.0** - Major release with new configuration options
  - Added trimLeadingZeroes, trimWhitespace, and emptyStringIsNil configuration options
  - Backward compatible with v1.x
  - Enhanced data quality and consistency
- **1.2.0** - IATA Resolution 792 Version 8 compliance (June 2020 standard)
  - Supports new gender codes "X" (Unspecified) and "U" (Undisclosed)
  - Updated documentation and field descriptions
- **1.1.0** - Critical parsing bug fixes, IATA Version 7 compliance verified
- **1.0.0** - Initial IATA BCBP implementation
