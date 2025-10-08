# BoardingPassKit

A Swift framework for parsing airline boarding pass barcodes and QR codes that conform to the **IATA Bar Coded Boarding Pass (BCBP) standard**.

**Compliance:** IATA Resolution 792 - BCBP **Version 8** (Effective June 1, 2020) ✅

## Table of Contents

- [BoardingPassKit](#boardingpasskit)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [Swift Package Manager](#swift-package-manager)
  - [Quick Start](#quick-start)
  - [API Reference](#api-reference)
    - [BoardingPassDecoder](#boardingpassdecoder)
    - [Configuration Options](#configuration-options)
      - [Best Practices](#best-practices)
    - [BoardingPass](#boardingpass)
    - [BoardingPassLeg](#boardingpassleg)
    - [BoardingPassInfo](#boardingpassinfo)
    - [BoardingPassLegData](#boardingpasslegdata)
  - [QR Code Generation (iOS Only)](#qr-code-generation-ios-only)
  - [Demo Data](#demo-data)
  - [Debugging](#debugging)
  - [Error Handling](#error-handling)
  - [Multi-Leg Support](#multi-leg-support)
  - [Contributing](#contributing)
  - [License](#license)
  - [Author](#author)
  - [Migration Guide](#migration-guide)
    - [New Configuration Options](#new-configuration-options)
    - [Breaking Changes](#breaking-changes)
    - [Migration Steps](#migration-steps)
    - [What's Improved](#whats-improved)
    - [Version Comparison](#version-comparison)
  - [Acknowledgments](#acknowledgments)

## Features

- 🛫 Parse IATA BCBP compliant boarding pass barcodes and QR codes
- 📱 Generate QR codes from boarding pass data (iOS only)
- 🔍 Comprehensive debugging and logging capabilities
- 📊 Support for single and multi-leg itineraries
- 🏷️ Extract bag tags, frequent flyer information, and security data
- ⚙️ Configurable data processing options (trim whitespace, remove leading zeros, convert empty strings to nil)
- 🎯 Built-in demo data for testing and development
- 📦 Swift Package Manager support

## Requirements

- iOS 15.0+ / macOS 10.15+
- Swift 5.7+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add BoardingPassKit to your project using Swift Package Manager:

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/anomaddev/BoardingPassKit.git`
3. Select the version and add to your target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/anomaddev/BoardingPassKit.git", from: "1.0.0")
]
```

## Quick Start

```swift
import BoardingPassKit

// Using a barcode string
let barcodeString = "M1ACKERMANN/JUSTIN DAVEJKLEAJ MSYPHXAA 2819 014S008F0059 14A>318   0014BAA 00000000000002900174844256573 AA AA 76UXK84             223"

do {
    let decoder = BoardingPassDecoder()
    let boardingPass = try decoder.decode(code: barcodeString)
    
    print("Passenger: \(boardingPass.passengerName)")
    print("Flight: \(boardingPass.boardingPassLegs.first?.flightno ?? "N/A")")
    print("From: \(boardingPass.boardingPassLegs.first?.origin ?? "N/A")")
    print("To: \(boardingPass.boardingPassLegs.first?.destination ?? "N/A")")
    
} catch {
    print("Error decoding boarding pass: \(error)")
}
```

## API Reference

### BoardingPassDecoder

The main class for decoding boarding pass barcodes.

```swift
let decoder = BoardingPassDecoder()

// Decode from string
let boardingPass = try decoder.decode(code: barcodeString)

// Decode from Data
let boardingPass = try decoder.decode(barcodeData)
```

### Configuration Options

The `BoardingPassDecoder` provides several configuration options to customize parsing behavior:

```swift
let decoder = BoardingPassDecoder()

// Configuration options (all default to true)
decoder.debug = true                    // Enable detailed console logging during parsing
decoder.trimLeadingZeroes = true        // Remove leading zeros from numeric fields
decoder.trimWhitespace = true          // Remove whitespace from string fields
decoder.emptyStringIsNil = true        // Convert empty strings to nil for optional fields
```

**Default behavior examples:**

```swift
// trimLeadingZeroes = true (default)
// Flight number "00234" becomes "234"
// Seat number "005A" becomes "5A"

// trimWhitespace = true (default)
// Field "  ABC  " becomes "ABC"

// emptyStringIsNil = true (default)
// Optional field with "" becomes nil
// Bag tags with empty strings are filtered out
```

**Comparison with disabled settings:**

```swift
let decoder = BoardingPassDecoder()
decoder.trimLeadingZeroes = false
decoder.trimWhitespace = false
decoder.emptyStringIsNil = false

// Results in:
// Flight number "00234" remains "00234"
// Field "  ABC  " remains "  ABC  "
// Optional field with "" remains ""
// All bag tags preserved: ["ABC123", "", "DEF456"]
```

#### Best Practices

**For most use cases, keep the default settings:**
```swift
let decoder = BoardingPassDecoder()
// All defaults are optimal for typical boarding pass parsing
```

**For data analysis or debugging, you might want to preserve original formatting:**
```swift
let decoder = BoardingPassDecoder()
decoder.trimWhitespace = false
decoder.trimLeadingZeroes = false
decoder.emptyStringIsNil = false
// Preserves original field formatting for analysis
```

**For user-facing applications, use defaults to ensure clean data:**
```swift
let decoder = BoardingPassDecoder()
// Default settings ensure clean, user-friendly data
// Empty strings become nil (easier to handle in UI)
// Whitespace is trimmed (cleaner display)
// Leading zeros are removed (more readable numbers)
```

### BoardingPass

The main structure representing a decoded boarding pass.

```swift
public struct BoardingPass: Codable {
    /// The IATA BCBP format (M or S)
    public var format: String
    
    /// Number of legs in the boarding pass
    public var numberOfLegs: Int
    
    /// Passenger name (20 characters)
    public var passengerName: String
    
    /// Electronic ticket indicator (E or blank)
    public var ticketIndicator: String
    
    /// Array of flight legs
    public var boardingPassLegs: [BoardingPassLeg]
    
    /// Boarding pass information
    public var passInfo: BoardingPassInfo
    
    /// Security data (if present)
    public var securityData: BoardingPassSecurityData?
    
    /// Airline-specific blob data
    public var airlineBlob: String?
    
    /// Original barcode string
    public let code: String
}
```

### BoardingPassLeg

Represents a single flight segment.

```swift
public struct BoardingPassLeg: Codable {
    /// Leg index (0 for first leg)
    public let legIndex: Int
    
    /// Record locator (PNR code)
    public let pnrCode: String
    
    /// Origin airport (IATA code)
    public let origin: String
    
    /// Destination airport (IATA code)
    public let destination: String
    
    /// Operating carrier (IATA code)
    public let operatingCarrier: String
    
    /// Flight number
    public let flightno: String
    
    /// Julian date of flight
    public let julianDate: Int
    
    /// Compartment code (Y, C, F, etc.)
    public let compartment: String
    
    /// Seat number
    public let seatno: String
    
    /// Check-in sequence number
    public let checkIn: Int
    
    /// Passenger status
    public let passengerStatus: String
    
    /// Size of conditional data
    public let conditionalSize: Int
    
    /// Conditional data for this leg
    public var conditionalData: BoardingPassLegData?
}
```

### BoardingPassInfo

Contains boarding pass metadata and bag tags.

```swift
public struct BoardingPassInfo: Codable {
    /// IATA BCBP version
    let version: String
    
    /// Passenger description/gender code
    var passengerDescription: String?
    
    /// Check-in source
    var checkInSource: String?
    
    /// Pass issuance source
    var passSource: String?
    
    /// Issue date
    var issueDate: String?
    
    /// Document type
    var documentType: String?
    
    /// Issuing airline (IATA code)
    let issuingAirline: String
    
    /// Bag tags
    var bagTags: [String]
}
```

### BoardingPassLegData

Contains conditional data for a specific leg.

```swift
public struct BoardingPassLegData: Codable {
    /// Segment size
    public let segmentSize: Int
    
    /// Airline code
    public var airlineCode: String
    
    /// Ticket number
    public var ticketNumber: String
    
    /// Security selectee flag
    public var selectee: String
    
    /// International documentation indicator
    public var internationalDoc: String
    
    /// Ticketing carrier
    public var ticketingCarrier: String
    
    /// Frequent flyer airline
    public var ffAirline: String
    
    /// Frequent flyer number
    public var ffNumber: String
    
    /// ID/AD indicator
    public var idAdIndicator: String?
    
    /// Free baggage allowance
    public var freeBags: String?
    
    /// Fast track indicator
    public var fastTrack: String?
    
    /// Airline-specific data
    public var airlineUse: String?
}
```

## QR Code Generation (iOS Only)

Generate QR codes from boarding pass data:

```swift
#if os(iOS)
do {
    let qrCodeImage = try boardingPass.qrCode()
    // Display the QR code image
} catch {
    print("Failed to generate QR code: \(error)")
}
#endif
```

## Demo Data

The framework includes built-in demo data for testing:

```swift
// Simple single-leg boarding pass
let simplePass = try decoder.decode(code: BoardingPass.DemoData.Simple.string)

// Historical boarding pass example
let historicalPass = try decoder.decode(code: BoardingPass.DemoData.Historical.string)

// Multi-leg boarding pass
let multiLegPass = try decoder.decode(code: BoardingPass.DemoData.MultiLeg.string)
```

## Debugging

Enable detailed logging to see the parsing process:

```swift
let decoder = BoardingPassDecoder()
decoder.debug = true

let boardingPass = try decoder.decode(code: barcodeString)
boardingPass.printout() // Prints detailed information to console
```

## Error Handling

The framework provides comprehensive error handling:

```swift
do {
    let boardingPass = try decoder.decode(code: barcodeString)
} catch BoardingPassError.InvalidPassFormat(let format) {
    print("Invalid format: \(format)")
} catch BoardingPassError.DataIsNotBoardingPass(let error) {
    print("Not a valid boarding pass: \(error)")
} catch BoardingPassError.MandatoryItemNotFound(let index) {
    print("Missing mandatory field at index: \(index)")
} catch {
    print("Other error: \(error)")
}
```

## Multi-Leg Support

The framework fully supports multi-leg itineraries:

```swift
let boardingPass = try decoder.decode(code: multiLegBarcodeString)

print("Number of legs: \(boardingPass.numberOfLegs)")

for leg in boardingPass.boardingPassLegs {
    print("Leg \(leg.legIndex): \(leg.origin) → \(leg.destination)")
    print("Flight: \(leg.operatingCarrier)\(leg.flightno)")
    print("Seat: \(leg.seatno)")
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

Justin Ackermann

## Migration Guide

This version includes significant improvements over v1.0. Here's what's changed:

### New Configuration Options

The `BoardingPassDecoder` now includes three new configuration properties that provide better control over data processing:

```swift
// NEW: These properties are now available (all default to true)
decoder.trimLeadingZeroes = true        // Remove leading zeros from fields
decoder.trimWhitespace = true          // Remove whitespace from fields  
decoder.emptyStringIsNil = true        // Convert empty strings to nil
```

### Breaking Changes

**None** - This update is fully backward compatible. Existing code will continue to work without changes.

### Migration Steps

**For most users: No action required**
- Your existing code will work exactly as before
- The new features are enabled by default and improve data quality
- No code changes needed

**For users who want to preserve original formatting:**

If you need to maintain the exact original field formatting from v1.0, you can disable the new features:

```swift
let decoder = BoardingPassDecoder()

// Disable new data processing features to match v1.0 behavior
decoder.trimLeadingZeroes = false
decoder.trimWhitespace = false
decoder.emptyStringIsNil = false
```

### What's Improved

1. **Better Data Quality**: Leading zeros and whitespace are automatically cleaned
2. **Cleaner Optional Fields**: Empty strings are converted to `nil` for better Swift integration
3. **More Consistent Parsing**: All string fields now use consistent processing logic
4. **Enhanced Debugging**: Improved logging and error handling

### Version Comparison

| Feature | v1.0 (Main) | v2.0 (Beta) |
|---------|-------------|-------------|
| Basic parsing | ✅ | ✅ |
| Trim leading zeros | ❌ | ✅ (default) |
| Trim whitespace | ❌ | ✅ (default) |
| Empty string to nil | ❌ | ✅ (default) |
| Configurable options | ❌ | ✅ |
| Backward compatibility | N/A | ✅ |

## Acknowledgments

- IATA Resolution 792 - BCBP Version 8 specification
- [SwiftDate](https://github.com/malcommac/SwiftDate) library for date handling
- [Flight Historian](https://www.flighthistorian.com) by Paul Bogard for boarding pass parsing inspiration