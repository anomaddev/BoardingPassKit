# BoardingPassKit

This Swift framework will allow you to parse the barcodes and QR codes of airline boarding passes and other documents that are encoded using the **IATA Bar Coded Boarding Pass (BCBP) standard**.

**Compliance:** IATA Resolution 792 - BCBP **Version 8** (Effective June 1, 2020) ✅

**This Framework is still in development. Please use with caution in your projects!**

## Installation
#### Swift Package Manager
Add the package to your Xcode project with the repository URL: 
https://github.com/anomaddev/BoardingPassKit.git

## Example
Here is a simple example using a boarding pass of my own to show how to use the framework.

```swift
let barcodeString = "M1ACKERMANN/JUSTIN DAVEJPYKJI SINNRTJL 0712 336Y025C0231 348>3180 O9335BJL 01315361700012900174601118720 JL AA 34DGH32             3"
// or you can use a Data representation of the string in .ascii format.
let barcodeData = barcodeString.data(using: .ascii)

do {
    let decoder = BoardingPassDecoder()
    // example of settings you can change on the decoder. This one prints out the data every step of the decoding.
    decoder.debug = true
    
    let boardingPass            = try decoder.decode(code: barcodeString)
    let boardingPassFromData    = try decoder.decode(data: barcodeData)
} catch {
    // Handle error
}
```

## Boarding Pass
A boarding pass object will contain a few sections. This allows the library to accurately differentiate between mandatory & conditional items in the data.

```swift
public struct BoardingPass: Codable {
    
    /// The IATA BCBP version number
    public let version: String
    
    /// The parent object contains the information that is shared between all segments of the boarding pass.
    public var info: BoardingPassParent

    /// The main segment of the boarding pass.
    public var main: BoardingPassMainSegment

    /// The segments of the boarding pass. This will be empty if there is only one segment.
    public var segments: [BoardingPassSegment]

    /// The Boarding Pass security data used by the airline
    public var security: BoardingPassSecurityData
    
    /// The original `String` that was used to create the boarding pass
    public var code: String
}
```

### Boarding Pass Parent
The parent object contains the information that is shared between all segments of the boarding pass. This includes the passenger name, the PNR code, first segments seat number, etc.

```swift
public struct BoardingPassParent: Codable {
    
    /// The format code of the boarding pass
    public let format: String
    
    /// The number of legs included in this boarding pass
    public let legs: Int
    
    /// The passenger's name information
    public let name: String
    
    /// The electronic ticket indicator
    public let ticketIndicator: String
    
    /// The record locator with the airline
    public let pnrCode: String
    
    /// The IATA code of the origin airport
    public let origin: String
    
    /// The IATA code of the destination airport
    public let destination: String
    
    /// The IATA code of the airline operating the flight
    public let operatingCarrier: String
    
    /// The flight number of the operating airline
    public let flightno: String
    
    /// The day of the year the flight takes place
    public let julianDate: Int
    
    /// The compartment code for the passenger on the main segment
    public let compartment: String
    
    /// The seat number for the passenger on the main segment
    public let seatno: String
    
    /// What number passenger you were to check in
    public let checkIn: Int
    
    /// Bag check, checked in, etc. This code needs to be parsed.
    public let passengerStatus: String
    
    /// The size of the conditional data in the boarding pass. Parsed decimal from hexidecimal.
    public let conditionalSize: Int
    
}
```

### Boarding Pass Main Segment
The main segment contains the information that is unique to the first segment of the boarding pass. This includes the airline code, ticket number, bag tags, etc. There are also fields that specify the size of the conditional items in the data.

```swift
public struct BoardingPassMainSegment: Codable {
    
    /// The size of the main segment in the boarding pass. Parsed decimal from hexidecimal.
    public let structSize: Int

    /// The passenger description code.
    public let passengerDesc: String

    /// The source of the passenger's check in
    public let checkInSource: String

    /// The source of the passenger's boarding pass
    public let passSource: String

    /// The date the boarding pass was issued
    public let dateIssued: String

    /// The type of document the passenger is using
    public let documentType: String

    /// The IATA airline code issuing the boarding pass
    public let passIssuer: String
    
    /// Your first bag tag
    public var bagtag1: String?

    /// Your second bag tag
    public var bagtag2: String?

    /// Your third bag tag
    public var bagtag3: String?
    
    /// The size of the variable data in the boarding pass. Parsed decimal from hexidecimal.
    public let nextSize: Int

    /// The numeric airline code of the airline issuing the boarding pass
    public let airlineCode: String

    /// The boarding pass ticket number
    public let ticketNumber: String

    /// Selectee indicator
    public let selectee: String

    /// International documentation verification indicator
    public let internationalDoc: String

    /// Marketing carrier
    public let carrier: String

    /// Frequent flyer carrier
    public var ffCarrier: String?

    /// Frequent flyer number
    public var ffNumber: String?
    
    /// ID/AD indicator
    public var IDADIndicator: String?

    /// Free baggage allowance
    public var freeBags: String?

    /// Fast track indicator
    public var fastTrack: String?

    /// For internal airline use
    public var airlineUse: String?
}
```

### Generating a Barcode or QR Code from Boarding Pass Data
The parser, that deciphers the Boarding Pass string, can also generate a QR Code from the data. This can be useful if you want to display the QR Code on a screen.

#### QR Code

```swift
do { 
    let decoder = BoardingPassDecoder()
    let pass = try decoder.decode(data: data)
    let qrCode = try pass.qrCode()
} catch {
    print(error.localizedDescription)
}
```

#### PDF417
```swift
// Coming Soon
``` 

### Print to Console
When debugging your functions, you can call the `printout()` function on your BoardPass object to print all the details to the console.

```swift
/// for this example we will print out the above boarding pass to the console
boardingPass.printout()

//
// SEGMENTS: 1
// ======================
// MAIN SEGMENT
// ===MANDATORY ITEMS [60 characters long]===
// FORMAT CODE:  M
// LEGS ENCODED: 1
// PASSENGER:    ACKERMANN/JUSTIN DAV
// INDICATOR:    E
// PNR CODE:     UXPVFK
// ORIGIN:       HKG
// DESTINATION:  SIN
// CARRIER:      CX
// FLIGHT NO:    0715
// JULIAN DATE:  326
// COMPARTMENT:  Y
// SEAT NO:      040G
// CHECK IN:     59
// STATUS:       3
// VAR SIZE:     75
// 
// ===CONDITIONAL ITEMS [75 characters long]===
// VERSION:       6
// PASS STRUCT:   24
// PASS DESC:     0
// SOURCE CHK IN:
// SOURCE PASS:   O
// DATE ISSUED:   9326
// DOC TYPE:      B
// AIRLINE DESIG: AA
// BAG TAG 1:
// BAG TAG 2:     none
// BAG TAG 3:     none
// FIELD SIZE:    42
// AIRLINE CODE:  001
// TICKET NO:     7459737133
// SELECTEE:      0
// INTERNATIONAL:
// CARRIER:       AA
// FREQ CARRIER:  AA
// FREQ NUMBER:   76UXK84
// 
// AD ID:
// FREE BAGS:
// FAST TRACK:    N
// AIRLINE USE:   3AA
// ======================
// 
// SECURITY DATA
// ========================
// TYPE:     nil
// LENGTH:   nil
// DATA:
// ========================
// 
```

## Author
Justin Ackermann
