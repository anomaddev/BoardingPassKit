# BoardingPassKit (Swift)

IATA BCBP (Resolution 792, Version 8) boarding pass decoder for iOS 15+ and macOS 10.15+.

## Install

**Swift Package Manager**

```swift
dependencies: [
    .package(url: "https://github.com/anomaddev/BoardingPassKit.git", from: "2.3.3")
]
```

**CocoaPods**

```ruby
pod 'BoardingPassParser'
```

## Quick start

```swift
import BoardingPassKit

let decoder = BoardingPassDecoder()
decoder.debug = false

let pass = try decoder.decode(code: barcodeString)
print(pass.passengerName)
print(pass.boardingPassLegs.first?.origin ?? "")
```

## Image barcode extraction

Read a boarding-pass QR, Aztec, or PDF417 barcode from PNG, JPEG, or HEIC bytes, then decode it:

```swift
let barcodeString = try BoardingPassQRExtractor.payload(from: imageData)
let pass = try decoder.decode(code: barcodeString)

// or in one step
let passFromImage = try decoder.decode(imageData: imageData)
```

On iOS, `BoardingPassQRExtractor.payload(from:)` also accepts `UIImage`. Scanning uses Vision and reads QR, Aztec, and PDF417 (not Data Matrix).

## Demo data

```swift
let pass = try decoder.decode(code: BoardingPass.DemoData.Simple.string)
```

## Test

From the repository root (macOS):

```bash
swift test
```
