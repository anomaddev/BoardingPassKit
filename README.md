# BoardingPassKit

A Swift framework for parsing airline boarding pass barcodes and QR codes that conform to the **IATA Bar Coded Boarding Pass (BCBP) standard**.

**Compliance:** IATA Resolution 792 - BCBP **Version 8** (Effective June 1, 2020) ✅

## Features

- 🛫 Parse IATA BCBP compliant boarding pass barcodes and QR codes
- 📱 Generate QR codes from boarding pass data (iOS only)
- 🔍 Comprehensive debugging and logging capabilities
- 📊 Support for single and multi-leg itineraries
- 🏷️ Extract bag tags, frequent flyer information, and security data
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

// Configuration options
decoder.debug = true                    // Enable detailed logging
decoder.trimLeadingZeroes = true        // Remove leading zeros from fields
decoder.trimWhitespace = true          // Remove whitespace from fields
decoder.emptyStringIsNil = true        // Convert empty strings to nil

// Decode from string
let boardingPass = try decoder.decode(code: barcodeString)

// Decode from Data
let boardingPass = try decoder.decode(barcodeData)
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

## Acknowledgments

- IATA Resolution 792 - BCBP Version 8 specification
- SwiftDate library for date handling