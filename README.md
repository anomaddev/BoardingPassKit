# BoardingPassKit

Monorepo for parsing airline boarding pass barcodes and QR codes that conform to the **IATA Bar Coded Boarding Pass (BCBP) standard** (Resolution 792, Version 8).

| Package | Path | Install |
|---------|------|---------|
| **Swift** | [`packages/swift`](packages/swift) | Swift Package Manager / CocoaPods |
| **Node.js** | [`packages/node`](packages/node) | `npm install boarding-pass-kit` |

## Features

- Parse IATA BCBP v8 ASCII payloads (single and multi-leg)
- Extract bag tags, frequent flyer info, and security data
- Convert Julian day-of-year to calendar dates (with year inference)
- Configurable trimming and empty-string handling
- Built-in demo data for testing

## Repository Layout

```
BoardingPassKit/
├── packages/
│   ├── swift/          # BoardingPassKit Swift library
│   └── node/           # boarding-pass-kit npm package
├── apps/
│   └── BoardingPassKitDemo/
├── Package.swift       # Root SPM manifest (backward compatible)
└── IATA_COMPLIANCE.md
```

## Swift

### Requirements

- iOS 15.0+ / macOS 10.15+
- Swift 5.7+

### Installation

**Swift Package Manager** — add the repository URL in Xcode or `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/anomaddev/BoardingPassKit.git", from: "2.1.2")
]
```

**CocoaPods:**

```ruby
pod 'BoardingPassParser'
```

### Quick Start

```swift
import BoardingPassKit

let decoder = BoardingPassDecoder()
decoder.debug = false

let pass = try decoder.decode(code: barcodeString)
print(pass.passengerName)
print(pass.boardingPassLegs.first?.origin ?? "")

// Julian day-of-year → calendar date
if let flightDate = pass.boardingPassLegs.first?.flightDate() {
    print(flightDate)
}
```

### Julian Date Conversion

BCBP stores flight date as a 3-digit **day-of-year** (001–366). Use `JulianDateConverter` or `BoardingPassLeg.flightDate()`:

```swift
// Explicit year
let date = try JulianDateConverter.toCalendarDate(dayOfYear: 14, year: 2025)

// Infer year from scan date (handles year-boundary flights)
let date = try JulianDateConverter.toCalendarDate(dayOfYear: 14, relativeTo: Date())
```

## Node.js

See [`packages/node/README.md`](packages/node/README.md) for full documentation.

```typescript
import { BoardingPassDecoder, DemoData, julianToCalendarDate } from 'boarding-pass-kit';

const decoder = new BoardingPassDecoder();
decoder.debug = false;

const pass = decoder.decode(DemoData.Simple);
console.log(pass.passengerName);

const flightDate = pass.boardingPassLegs[0]!.flightDate();
// or: julianToCalendarDate(14, 2025)
```

## Development

```bash
# Node.js
npm install
npm run build
npm test

# Swift
swift build
swift test
# or
npm run test:swift
```

## Demo Data

Both packages include the same test fixtures: `Simple`, `Historical`, `MultiLeg`, and `International`.

## License

MIT — see [LICENSE](LICENSE).

## Author

Justin Ackermann
