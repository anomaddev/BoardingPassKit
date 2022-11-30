# BoardingPassKit

This Swift framework will allow you to read the barcodes and QR codes from boarding passes and other documents that are encoded using the IATA 2D barcode standard.

## Installation
#### Swift Package Manager
Add the package to your Xcode project with the repository URL: 
https://github.com/anomaddev/BoardingPassKit.git

## Example
Here is a simple example using a boarding pass of my own to show how to use the framework.

```swift

let barcodeString = "M1ACKERMANN/JUSTIN    ETDPUPK TPADFWAA 1189 091R003A0033 14A>318   0091BAA 00000000000002900121232782703 AA AA 76UXK84             2IN"

do {
    let boardingPass = try BoardingPass(data: barcodeString.data(using: .ascii))
} catch {
    // Handle error
}
```

#### Get Flight Information
Your boarding pass can contain multiple segments. The first segment listed will typically be the flight for this boarding pass. You can get the flight information for the first segment like this:

```swift
let boardingPass = try? BoardingPass(data: barcodeString.data(using: .ascii))
let segments = boardingPass.segments
let flight = segments.first
```

After that you can access the flight information contained in the boarding pass:

```swift
var airlineData: String?
var ticketAirline: String?      // airline that issued the ticket
var ticketNumber: String?       // ticket num
let origin: String              // origin airport code
let destination: String         // destination airport code     
let carrier: String             // airline operating the fli
let pnrCode: String             // record locator
let flightno: String            // flight number
let dayOfYear: Int              // day of the year of the flight
let compartment: String         // compartment code
var seatno: String?             // seat number
var checkedin: Int?             // check-in sequence number      
let passengerStatus: String    

var selectee: String?
var documentVerification: String?
var bookedAirline: String?      // airline that booked the ticket
var ffAirline: String?          // frequent flyer airline
var ffNumber: String?           // frequent flyer number
var idAdIndicator: String?          
var freeBags: String?           // number of free bags
var fastTrack: Bool?            // is fast tracked for security
```

## Author
Justin Ackermann