# BoardingPassKit

This Swift framework will allow you to read the barcodes and QR codes from boarding passes and other documents that are encoded using the IATA 2D barcode standard.

**This Framework is still in development. Please use with caution in your projects!**

## Installation
#### Swift Package Manager
Add the package to your Xcode project with the repository URL: 
https://github.com/anomaddev/BoardingPassKit.git

## Example
Here is a simple example using a boarding pass of my own to show how to use the framework.

```swift
let barcodeString = "M1ACKERMANN/JUSTIN DAVEJPYKJI SINNRTJL 0712 336Y025C0231 348>3180 O9335BJL 01315361700012900174601118720 JL AA 34DGH32             3"

do {
    let boardingPass = try BoardingPass(data: barcodeString.data(using: .ascii))
} catch {
    // Handle error
}
```

### Reading the Boarding Pass Data

```swift 
print(boardingPass.passIssuer)  // JL
print(boardingPass.eTicket)     // true
print(boardingPass.name)        // ACKERMANN/JUSTIN DAVE
print(boardingPass.legs)        // 1
```

These are all the properties that are available on a `BoardingPass` object.
```swift
var owner: String!                      
let scan: String                        // raw scan data
let format: String                      // Formate of the boarding pass
let legs: Int                           // Number of legs
let name: String                        // Name of the passenger
var eTicket: Bool? = false              // is a mobile boarding pass
var segments: [BoardingPassLeg]         // Flights in an Array of BoardingPassLeg objects
var version: Int?                       // Version of the boarding pass
var uniqueLength: Int?                  // Length of the unique identifier used to parse the boarding pass
var passengerDesc: String?              // Airline Passenger description
var checkinSource: String?              // Checkin Source
var passSource: String?                 // Boarding Pass Source
var passDate: Date?                     // Date of the boarding pass
var passYear: Int?                      // Year of the boarding pass
var passDay: Int?                       // Day of the boarding pass
var documentType: String?               // Document Type
var passIssuer: String                  // 2 letter airline code who issued the pass
var bags: [BagTag] = []                 // Baggage tags
```

### Get Flight Information
Your boarding pass can contain multiple segments. The first segment listed will typically be the flight for this boarding pass. You can get the flight information for the first segment like this:

```swift
// Flight information for the boarding pass is contained in an array of type BoardingPassLeg
// It is possible to have multiple legs for a single boarding pass
let segments: [BoardingPassLeg] = boardingPass.segments

// Always validate that the array of segments is not empty before accessing the first element
let flight: BoardingPassLeg = segments.first! 
```

After that you can access the flight information contained in the boarding pass leg:
```swift 
print(flight.bookedAirline) // JL
print(flight.origin)        // SIN
print(flight.destination)   // NRT
print(flight.flightno)      // 712
print(flight.seatno)        // 25C
print(flight.ffNumber)      // 34DGH32
```

These are all the properties that are available on a `BoardingPassLeg` object.
```swift
var airlineData: String?
var ticketAirline: String?      // id of airline that issued the ticket
var ticketNumber: String?       // ticket number
let origin: String              // origin airport code
let destination: String         // destination airport code     
let carrier: String             // airline operating the flight
let pnrCode: String             // record locator
let flightno: String            // flight number
let dayOfYear: Int              // day of the year of the flight
let compartment: String         // compartment code
var seatno: String?             // seat number
var checkedin: Int?             // check-in sequence number      
let passengerStatus: String    
var selectee: String?
var documentVerification: String?
var bookedAirline: String?      // airline that operates the flight
var ffAirline: String?          // frequent flyer airline
var ffNumber: String?           // frequent flyer number
var idAdIndicator: String?          
var freeBags: String?           // number of free bags
var fastTrack: Bool?            // is fast tracked for security
```

### Generating a Barcode or QR Code from Boarding Pass Data
The parser, that deciphers the Boarding Pass string, can also generate a QR Code from the data. This can be useful if you want to display the QR Code on a screen.

#### QR Code

```swift
let barcodeString = "M1ACKERMANN/JUSTIN DAVEJPYKJI SINNRTJL 0712 336Y025C0231 348>3180 O9335BJL 01315361700012900174601118720 JL AA 34DGH32             3"

// Generate QR code with a UIImage as the output
let qrCode: UIImage? = BoardingPassParser.generateQRCode(from: barcodeString)
```

#### PDF417
```swift
// Coming Soon
``` 

## Author
Justin Ackermann