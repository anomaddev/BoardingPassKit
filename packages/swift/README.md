# BoardingPassKit (Swift)

IATA BCBP (Resolution 792, Version 8) boarding pass decoder for iOS 15+ and macOS 10.15+.

## Install

**Swift Package Manager**

```swift
dependencies: [
    .package(url: "https://github.com/anomaddev/BoardingPassKit.git", from: "2.3.0")
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

## Image QR extraction

Read a boarding-pass QR from PNG, JPEG, or HEIC bytes, then decode it:

```swift
let qrString = try BoardingPassQRExtractor.payload(from: imageData)
let pass = try decoder.decode(code: qrString)

// or in one step
let passFromImage = try decoder.decode(imageData: imageData)
```

On iOS, `BoardingPassQRExtractor.payload(from:)` also accepts `UIImage`. Scanning uses Vision and is limited to QR codes (not PDF417 / Aztec / Data Matrix).

## Demo data

```swift
let pass = try decoder.decode(code: BoardingPass.DemoData.Simple.string)
```

## Test

From the repository root (macOS):

```bash
swift test
```
