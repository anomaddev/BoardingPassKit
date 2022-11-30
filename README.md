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

## Author
Justin Ackermann