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
    - [CocoaPods](#cocoapods)
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
- 📦 Swift Package Manager and CocoaPods support

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
    .package(url: "https://github.com/anomaddev/BoardingPassKit.git", from: "2.1.1")
]
```

### CocoaPods

Add BoardingPassKit to your project using CocoaPods:

1. Add this line to your `Podfile`:
```ruby
pod 'BoardingPassKit'
```

2. Run `pod install` in your terminal
3. Use the `.xcworkspace` file that was created

Or add it directly to your `Podfile`:

```ruby
target 'YourAppTarget' do
  pod 'BoardingPassKit'
end
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

Version 2.x includes **critical parsing fixes** and significant improvements over v1.x. If you're upgrading from v1.x, please read this section carefully.

### ⚠️ Critical Changes from v1.x to v2.x

**Version 2.0 is a major release with critical bug fixes.** While we've maintained API compatibility where possible, the internal parsing logic has been significantly improved to fix critical issues with multi-leg boarding passes and conditional data parsing.

#### What Changed

**1. Critical Parsing Bug Fixes**
- **Multi-leg boarding passes**: v1.x incorrectly parsed subsequent flight segments using mandatory parsing instead of conditional parsing, causing failures on multi-leg itineraries
- **Check-in sequence numbers**: Fixed incorrect parsing logic that could cause data misalignment
- **Conditional data handling**: Improved parsing of optional fields to match IATA Resolution 792 specification

**2. IATA Resolution 792 Version 8 Compliance**
- Added support for new gender codes: "X" (Unspecified) and "U" (Undisclosed)
- Updated passenger description field to handle Version 8 specifications
- See `IATA_COMPLIANCE.md` for full compliance details

**3. New Configuration Options**
The `BoardingPassDecoder` now includes three configuration properties for better control over data processing:

```swift
// NEW in v2.x: These properties are now available (all default to true)
decoder.trimLeadingZeroes = true        // Remove leading zeros from numeric fields
decoder.trimWhitespace = true           // Remove whitespace from string fields  
decoder.emptyStringIsNil = true         // Convert empty strings to nil for optional fields
```

**4. Enhanced Error Handling**
- More descriptive error messages for parsing failures
- Better validation of conditional data boundaries
- Improved debugging output

### Breaking Changes

While the public API remains largely compatible, the **parsing behavior has changed**:

1. **Multi-leg boarding passes**: v2.x correctly parses multi-leg itineraries that may have failed or parsed incorrectly in v1.x
2. **Field values**: With default settings, fields are now trimmed and cleaned (leading zeros removed, whitespace trimmed, empty strings converted to nil)
3. **Data validation**: Stricter validation may cause some malformed boarding passes that parsed in v1.x to now throw errors (this is correct behavior)

### Migration Steps

#### For Users of Single-Leg Boarding Passes

If you only parse single-leg (M1 format) boarding passes, your code should work with minimal changes:

```swift
// v1.x code
let decoder = BoardingPassDecoder()
let boardingPass = try decoder.decode(code: barcodeString)

// v2.x code - same API, improved parsing
let decoder = BoardingPassDecoder()
let boardingPass = try decoder.decode(code: barcodeString)
```

**Expected differences:**
- Numeric fields will have leading zeros removed (`"00234"` → `"234"`)
- String fields will have whitespace trimmed
- Empty optional fields will be `nil` instead of `""`

#### For Users of Multi-Leg Boarding Passes

**IMPORTANT:** If you use multi-leg boarding passes, v2.x **fixes critical bugs** that likely caused parsing failures in v1.x.

```swift
// v2.x correctly parses multi-leg boarding passes
let decoder = BoardingPassDecoder()
let boardingPass = try decoder.decode(code: multiLegBarcodeString)

// Now you can reliably access all legs
for leg in boardingPass.boardingPassLegs {
    print("Leg \(leg.legIndex): \(leg.origin) → \(leg.destination)")
}
```

#### Preserving v1.x Behavior (Not Recommended)

If you need to preserve the exact field formatting from v1.x (not recommended for new code):

```swift
let decoder = BoardingPassDecoder()

// Disable data cleaning features (not recommended)
decoder.trimLeadingZeroes = false
decoder.trimWhitespace = false
decoder.emptyStringIsNil = false

// This will produce output closer to v1.x behavior
// WARNING: This does NOT restore v1.x parsing bugs
```

**Note:** Even with these settings disabled, v2.x uses the corrected parsing logic. You cannot restore v1.x's parsing bugs.

### What's Improved in v2.x

1. **Correct Multi-Leg Parsing**: Properly handles M2, M3, M4 format boarding passes
2. **IATA Compliance**: Full compliance with IATA Resolution 792 Version 8
3. **Better Data Quality**: Automatic cleaning of leading zeros and whitespace
4. **Cleaner Optional Fields**: Empty strings converted to `nil` for better Swift integration
5. **Enhanced Debugging**: Improved logging and error messages
6. **Configurable Processing**: Choose how data should be cleaned

### Version Comparison

| Feature | v1.0.x | v2.0.x | v2.1.x (Latest) |
|---------|--------|--------|-----------------|
| Single-leg parsing | ✅ | ✅ | ✅ |
| Multi-leg parsing | ⚠️ Broken | ✅ Fixed | ✅ |
| IATA Version 8 compliance | ❌ | ✅ | ✅ |
| Trim leading zeros | ❌ | ✅ (default) | ✅ (default) |
| Trim whitespace | ❌ | ✅ (default) | ✅ (default) |
| Empty string to nil | ❌ | ✅ (default) | ✅ (default) |
| Configurable options | ❌ | ✅ | ✅ |
| "0000" field parsing | ⚠️ | ⚠️ | ✅ Fixed in v2.1.1 |
| Conditional data parsing | ⚠️ Broken | ✅ Fixed | ✅ |

### Version History

#### v2.1.1 (Latest - Recommended)
- **Fixed "0000" integer parsing issue**: Resolved bug where fields containing "0000" failed to parse
- Full backward compatibility with v2.1.0

#### v2.1.0
- Enhanced configuration options
- Improved data processing and validation
- Better debugging capabilities

#### v2.0.2
- CocoaPods naming update (BoardingPassKit → BoardingPassParser for pods)
- No functional changes

#### v2.0.1
- Patch release with improved configuration options

#### v2.0.0 (Major Release)
- **Critical parsing fixes for multi-leg boarding passes**
- IATA Resolution 792 Version 8 compliance
- New configuration options (trimLeadingZeroes, trimWhitespace, emptyStringIsNil)
- Enhanced error handling and validation

#### v1.x
- Initial IATA BCBP implementation
- ⚠️ Known issues with multi-leg boarding passes
- ⚠️ Incorrect conditional data parsing

### Recommended Action

**We strongly recommend upgrading to v2.1.1** for all users:
- Critical bug fixes for multi-leg boarding passes
- Full IATA Resolution 792 Version 8 compliance
- Better data quality and error handling
- Minimal migration effort for most use cases

## Acknowledgments

- IATA Resolution 792 - BCBP Version 8 specification
- [SwiftDate](https://github.com/malcommac/SwiftDate) library for date handling
- [Flight Historian](https://www.flighthistorian.com) by Paul Bogard for boarding pass parsing inspiration