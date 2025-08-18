# BoardingPassKit

A comprehensive Swift framework for parsing IATA 2D barcode boarding passes and generating QR codes. This library provides robust parsing, validation, and QR code generation capabilities for airline boarding pass data encoded using the IATA BCBP (Boarding Pass Bar Code) standard.

## ✨ Features

- **IATA BCBP Standard Support**: Full compliance with IATA boarding pass barcode specifications
- **Robust Parsing**: Handles both single and multi-segment boarding passes
- **Data Validation**: Built-in validation for data integrity and format compliance
- **QR Code Generation**: Generate QR codes with custom styling, colors, and logo overlays
- **Comprehensive Error Handling**: Detailed error reporting with recovery suggestions
- **Cross-Platform Support**: iOS-focused with graceful degradation for other platforms
- **Professional Documentation**: Complete API documentation with usage examples
- **Modular Architecture**: Clean separation of concerns with dedicated modules

## 🚀 Installation

### Swift Package Manager

Add the package to your Xcode project with the repository URL:

```
https://github.com/anomaddev/BoardingPassKit.git
```

#### Requirements
- iOS 16.0+ / macOS 13.0+
- Swift 5.7+
- Xcode 14.0+

## 📖 Quick Start

Here's a simple example using a boarding pass to show how to use the framework:

```swift
import BoardingPassKit

let barcodeString = "M1ACKERMANN/JUSTIN DAVEJPYKJI SINNRTJL 0712 336Y025C0231 348>3180 O9335BJL 01315361700012900174601118720 JL AA 34DGH32             3"

do {
    let decoder = BoardingPassDecoder()
    
    // Configure decoder settings
    decoder.debug = true                    // Enable debug output
    decoder.validationEnabled = true        // Enable data validation (recommended)
    decoder.trimLeadingZeroes = true       // Remove unnecessary leading zeros
    decoder.trimWhitespace = true          // Clean up whitespace
    
    // Decode the boarding pass
    let boardingPass = try decoder.decode(code: barcodeString)
    
    // Access passenger information
    print("Passenger: \(boardingPass.info.name)")
    print("Flight: \(boardingPass.info.operatingCarrier) \(boardingPass.info.flightno)")
    print("Route: \(boardingPass.info.origin) → \(boardingPass.info.destination)")
    print("Date: \(boardingPass.info.julianDate)")
    print("Seat: \(boardingPass.info.seatno)")
    
    // Check if multi-segment
    if boardingPass.segments.count > 0 {
        print("Multi-leg journey with \(boardingPass.segments.count) additional segments")
    }
    
    // Validate the boarding pass
    if boardingPass.isValid {
        print("Boarding pass is valid")
    } else {
        let errors = boardingPass.validate()
        print("Validation errors: \(errors)")
    }
    
} catch BoardingPassError.InvalidPassFormat(let format) {
    print("Invalid format: \(format). Expected 'M' or 'S'")
} catch BoardingPassError.InvalidSegments(let legs) {
    print("Invalid segment count: \(legs)")
} catch {
    print("Decoding failed: \(error)")
}
```

## 🏗️ Architecture

The library is organized into several key components:

### Core Structures

#### `BoardingPass`
The main struct representing a decoded boarding pass:

```swift
public struct BoardingPass: Codable {
    /// The IATA BCBP version number
    public let version: String
    
    /// Core information shared across all segments
    public var info: BoardingPassParent
    
    /// Primary flight segment details
    public var main: BoardingPassMainSegment
    
    /// Additional flight segments (empty for single-segment)
    public var segments: [BoardingPassSegment]
    
    /// Airline security and validation data
    public var security: BoardingPassSecurityData
    
    /// Original boarding pass code string
    public var code: String
}
```

#### `BoardingPassParent`
Contains essential flight information shared across all segments:

```swift
public struct BoardingPassParent: Codable {
    /// Boarding pass format (M = multi-segment, S = single-segment)
    public let format: String
    
    /// Number of flight segments
    public let legs: Int
    
    /// Passenger name (LASTNAME/FIRSTNAME format)
    public let name: String
    
    /// Electronic ticket indicator
    public let ticketIndicator: String
    
    /// Passenger Name Record (PNR) code
    public let pnrCode: String
    
    /// Origin airport (IATA 3-letter code)
    public let origin: String
    
    /// Destination airport (IATA 3-letter code)
    public let destination: String
    
    /// Operating airline (IATA 3-letter code)
    public let operatingCarrier: String
    
    /// Flight number
    public let flightno: String
    
    /// Julian date of departure
    public let julianDate: Int
    
    /// Cabin class compartment code
    public let compartment: String
    
    /// Assigned seat number
    public let seatno: String
    
    /// Check-in sequence number
    public let checkIn: Int
    
    /// Passenger status and special indicators
    public let passengerStatus: String
    
    /// Size of conditional data section
    public let conditionalSize: Int
}
```

#### `BoardingPassMainSegment`
Contains detailed information about the primary flight segment:

```swift
public struct BoardingPassMainSegment: Codable {
    /// Passenger description and check-in source
    public let passengerDesc: String
    public let checkInSource: String
    public let passSource: String
    
    /// Date and document information
    public let dateIssued: String
    public let documentType: String
    public let passIssuer: String
    
    /// Bag tag information (up to 3 tags)
    public var bagtag1: String?
    public var bagtag2: String?
    public var bagtag3: String?
    
    /// Airline and ticket details
    public let airlineCode: String
    public let ticketNumber: String
    public let selectee: String
    public let internationalDoc: String
    
    /// Frequent flyer information
    public var ffCarrier: String?
    public var ffNumber: String?
    
    /// Additional airline-specific data
    public var IDADIndicator: String?
    public var freeBags: String?
    public var fastTrack: String?
    public var airlineUse: String?
}
```

#### `BoardingPassSegment`
Represents additional flight segments in multi-leg journeys:

```swift
public struct BoardingPassSegment: Codable {
    /// Flight routing information
    public let pnrCode: String
    public let origin: String
    public let destination: String
    public let carrier: String
    public let flightno: String
    public let julianDate: Int
    
    /// Passenger details for this segment
    public let compartment: String
    public var seatno: String?
    public var checkedin: Int
    public var passengerStatus: String
    
    /// Airline and ticket information
    public let airlineCode: String
    public let ticketNumber: String
    public let selectee: String
    public let internationalDoc: String
    
    /// Frequent flyer and additional data
    public var ffAirline: String
    public var ffNumber: String
    public var idAdIndicator: String?
    public var freeBags: String?
    public var fastTrack: String?
    public var airlineUse: String?
}
```

#### `BoardingPassSecurityData`
Contains airline-specific security and validation information:

```swift
public struct BoardingPassSecurityData: Codable {
    /// Security data section indicator (usually ">")
    public var beginSecurity: String?
    
    /// Type of security validation used
    public var securityType: String?
    
    /// Length of security data in characters
    public var securitylength: Int?
    
    /// Raw security codes and validation data
    public var securityData: String?
}
```

## 🔍 Data Validation

The library includes comprehensive validation capabilities:

```swift
// Validate before decoding
let errors = BoardingPass.validate(barcodeString)
if errors.isEmpty {
    let boardingPass = try decoder.decode(code: barcodeString)
} else {
    print("Validation errors: \(errors)")
}

// Validate existing boarding pass
if boardingPass.isValid {
    print("Boarding pass is valid")
} else {
    let errors = boardingPass.validate()
    for error in errors {
        print("Error: \(error.localizedDescription)")
        print("Suggestion: \(error.recoverySuggestion ?? "None")")
    }
}
```

### Validation Features
- **Format Validation**: Ensures proper boarding pass format (M/S)
- **Segment Count Validation**: Validates number of flight segments
- **Field Length Validation**: Checks mandatory field requirements
- **Character Encoding Validation**: Verifies ASCII encoding
- **Data Structure Validation**: Ensures proper field boundaries
- **Airport Code Validation**: Validates IATA airport codes
- **Flight Number Validation**: Checks flight number format
- **PNR Code Validation**: Validates Passenger Name Record codes

## 📱 QR Code Generation

Generate QR codes with extensive customization options:

### Basic QR Code Generation

```swift
do {
    // Basic QR code
    let qrCode = try boardingPass.qrCode()
    
    // Custom size
    let largeQR = try boardingPass.qrCode(size: CGSize(width: 300, height: 300))
    
    // Custom error correction
    let highQualityQR = try boardingPass.qrCode(correctionLevel: "H")
    
} catch {
    print("QR code generation failed: \(error)")
}
```

### Styled QR Codes

```swift
do {
    // Custom colors
    let blueQR = try boardingPass.qrCode(
        size: CGSize(width: 250, height: 250),
        correctionLevel: "H",
        foregroundColor: .blue,
        backgroundColor: .white
    )
    
    // Predefined styles
    let printStyle = QRCodeStyle.printing()
    let displayStyle = QRCodeStyle.display()
    let darkStyle = QRCodeStyle.darkMode()
    
    let styledQR = try boardingPass.qrCode(style: printStyle)
    
} catch {
    print("Styled QR code generation failed: \(error)")
}
```

### Logo Overlay

```swift
do {
    let airlineLogo = UIImage(named: "airline_logo")!
    
    let brandedQR = try boardingPass.qrCodeWithLogo(
        size: CGSize(width: 300, height: 300),
        logo: airlineLogo,
        logoSize: CGSize(width: 60, height: 60)
    )
    
} catch {
    print("Logo overlay failed: \(error)")
}
```

### Convenience Methods

```swift
// Optimized for different use cases
let printQR = try boardingPass.printableQRCode()
let displayQR = try boardingPass.mobileDisplayQRCode()
let brandedQR = try boardingPass.brandedQRCode(airlineColor: .blue)

// Automatic optimization
let optimalQR = try boardingPass.optimizedQRCode()
```

## 🎨 QR Code Styling

The `QRCodeStyle` struct provides extensive customization options:

```swift
// Create custom styles
let customStyle = QRCodeStyle(
    foregroundColor: UIColor.blue,
    backgroundColor: UIColor.white,
    correctionLevel: .high,
    cornerRadius: 10,
    addShadow: true
)

// Use builder pattern
let style = QRCodeStyle()
    .withForegroundColor(.red)
    .withRoundedCorners(15)
    .withShadow()
    .withCorrectionLevel(.high)

// Predefined styles
let printStyle = QRCodeStyle.printing()      // High error correction, black/white
let displayStyle = QRCodeStyle.display()     // Medium error correction, black/white
let darkStyle = QRCodeStyle.darkMode()       // White foreground, dark background
let airlineStyle = QRCodeStyle.airlineBranded(airlineColor: .blue)
```

## 🛠️ Configuration Options

### Decoder Configuration

```swift
let decoder = BoardingPassDecoder()

// Debug and development
decoder.debug = true                    // Enable detailed console output

// Data processing
decoder.trimLeadingZeroes = true        // Remove leading zeros from numeric fields
decoder.trimWhitespace = true           // Remove whitespace from field values

// Validation
decoder.validationEnabled = true        // Enable pre-parsing validation (recommended)
```

### QR Code Configuration

```swift
// Error correction levels
// L: Low (7% recovery) - Smallest size, least reliable
// M: Medium (15% recovery) - Balanced size and reliability (default)
// Q: Quartile (25% recovery) - Larger size, more reliable
// H: High (30% recovery) - Largest size, most reliable

// Size recommendations
// Mobile display: 150x150 points
// Standard display: 200x200 points
// Print quality: 300x300 points
// High resolution: 400x400+ points
```

## 🚨 Error Handling

The library provides comprehensive error handling with detailed information:

```swift
do {
    let boardingPass = try decoder.decode(code: barcodeString)
} catch BoardingPassError.InvalidPassFormat(let format) {
    print("Invalid format: \(format). Expected 'M' or 'S'")
} catch BoardingPassError.InvalidSegments(let legs) {
    print("Invalid segment count: \(legs). Must be greater than 0.")
} catch BoardingPassError.invalidAirportCode(let code) {
    print("Invalid airport code: \(code). Must be 3 uppercase letters.")
} catch BoardingPassError.invalidFlightNumber(let number) {
    print("Invalid flight number: \(number). Must be 1-5 alphanumeric characters.")
} catch BoardingPassError.qrCodeGenerationFailed(let reason) {
    print("QR code generation failed: \(reason)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Error Categories
- **Format & Structure Errors**: Invalid boarding pass format or segment count
- **Data Validation Errors**: Failed validation of boarding pass data
- **Parsing Errors**: Issues during the parsing process
- **QR Code Errors**: Problems with QR code generation
- **System Errors**: Core system or framework failures

## 📊 Sample Data

The library includes sample boarding pass codes for testing and development:

```swift
// Single-segment domestic flight
let sample1 = BoardingPass.scan1

// Multi-segment international flight
let sample2 = BoardingPass.scan10

// Flight with security data
let sample3 = BoardingPass.scan2

// International flight
let sample4 = BoardingPass.scan4
```

## 🔧 Advanced Usage

### Multi-Segment Processing

```swift
let boardingPass = try decoder.decode(code: barcodeString)

// Process main segment
print("Main flight: \(boardingPass.info.origin) → \(boardingPass.info.destination)")

// Process additional segments
for (index, segment) in boardingPass.segments.enumerated() {
    print("Segment \(index + 2): \(segment.origin) → \(segment.destination)")
    print("  Flight: \(segment.carrier) \(segment.flightno)")
    print("  Date: \(segment.julianDate)")
    
    if let seat = segment.seatno {
        print("  Seat: \(seat)")
    }
}
```

### Data Analysis

```swift
// Passenger name parsing
let nameParts = boardingPass.nameSegments
// Returns: ["ackermann", "justin", "dave"] for "ACKERMANN/JUSTIN DAVE"

// Check-in sequence analysis
let checkInOrder = boardingPass.info.checkIn
if checkInOrder < 100 {
    print("Early check-in passenger")
} else if checkInOrder > 500 {
    print("Late check-in passenger")
}

// Cabin class analysis
let cabinClass = boardingPass.info.compartment
switch cabinClass {
case "F": print("First Class")
case "C": print("Business Class")
case "Y": print("Economy Class")
default: print("Other cabin class: \(cabinClass)")
}
```

### Debug Output

```swift
// Enable debug mode
decoder.debug = true

// Print comprehensive boarding pass details
boardingPass.printout()

// This will output detailed information including:
// - Mandatory fields (60 characters)
// - Conditional fields (variable length)
// - Segment information (for multi-leg flights)
// - Security data
```

## 📚 API Reference

### Core Classes

- **`BoardingPassDecoder`**: Main parsing engine for boarding pass data
- **`BoardingPass`**: Complete boarding pass data structure
- **`BoardingPassParent`**: Core flight information shared across segments
- **`BoardingPassMainSegment`**: Primary flight segment details
- **`BoardingPassSegment`**: Additional flight segment information
- **`BoardingPassSecurityData`**: Security and validation data

### QR Code Classes

- **`QRCodeGenerator`**: Core QR code generation functionality
- **`QRCodeStyle`**: QR code styling and configuration
- **`QRCodeUtilities`**: Utility methods and helper functions

### Validation

- **`BoardingPassValidator`**: Comprehensive data validation
- **`BoardingPassError`**: Detailed error types and handling

### Extensions

- **`String.removeLeadingZeros()`**: Clean up numeric field formatting

## 🌟 Best Practices

### Performance
- Enable validation only when needed for production
- Use appropriate QR code sizes for your use case
- Consider caching generated QR codes for repeated use

### Error Handling
- Always wrap decoding in try-catch blocks
- Check validation results before processing
- Provide user-friendly error messages

### QR Code Generation
- Use high error correction (H) for printing
- Use medium error correction (M) for display
- Keep logo overlays under 25% of QR code size
- Ensure sufficient contrast for reliable scanning

### Data Processing
- Validate boarding pass data before parsing
- Handle optional fields gracefully
- Use computed properties for derived information

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

Justin Ackermann

## 📝 Version History

### Recent Updates
- **Comprehensive Documentation**: Complete API documentation with examples
- **Enhanced Error Handling**: Detailed error types with recovery suggestions
- **Data Validation**: Built-in validation for data integrity
- **QR Code Module**: Dedicated QR code generation with styling options
- **Modular Architecture**: Clean separation of concerns
- **Cross-Platform Support**: iOS-focused with graceful degradation
- **Performance Improvements**: Optimized parsing and validation
- **Professional Quality**: Production-ready library with comprehensive testing

---

**Note**: This framework is actively maintained and continuously improved. Please check for the latest updates and report any issues you encounter.
