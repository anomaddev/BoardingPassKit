# BoardingPassKit

This Swift framework will allow you to parse the barcodes and QR codes of airline boarding passes and other documents that are encoded using the IATA 2D barcode standard.

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
    
    let boardingPassFromString  = try decoder.decode(code: barcodeString)
    let boardingPassFromData    = try decoder.decode(data: barcodeData)
} catch {
    // Handle error
}
```

#### Print to Console
When debugging your functions, you can call the `printout()` function on your BoardPass object to print all the details to the console.

```swift
let pass = BoardingPass()
pass.printout()
```

### Generating a Barcode or QR Code from Boarding Pass Data
The parser, that deciphers the Boarding Pass string, can also generate a QR Code from the data. This can be useful if you want to display the QR Code on a screen.

#### QR Code

```swift
// Coming Soon
```

#### PDF417
```swift
// Coming Soon
``` 

## Author
Justin Ackermann
