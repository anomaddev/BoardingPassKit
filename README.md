# BoardingPassKit

Monorepo for parsing airline boarding pass barcodes and QR codes that conform to the **IATA Bar Coded Boarding Pass (BCBP) standard** (Resolution 792, Version 8).

| Package | Path | Install / notes |
|---------|------|-----------------|
| **Swift** | [`packages/swift`](packages/swift) | Swift Package Manager / CocoaPods |
| **Node.js** | [`packages/node`](packages/node) | `npm install boarding-pass-kit` |
| **Rust** | [`packages/rust`](packages/rust) | Canonical core crate (`boarding-pass-kit`) |
| **Python** | [`packages/python`](packages/python) | PyO3 bindings via maturin |
| **Go** | [`packages/go`](packages/go) | cgo bindings over the C FFI |
| **PHP** | [`packages/php`](packages/php) | PHP FFI bindings (`ext-ffi`) |
| **C FFI** | [`packages/ffi`](packages/ffi) | Shared C ABI used by Go and PHP |

Python, Go, and PHP share the Rust core. Swift and Node remain independent ports with the same public field names and demo fixtures.

## Features

- Parse IATA BCBP v8 ASCII payloads (single and multi-leg)
- Extract a QR, Aztec, or PDF417 payload from PNG, JPEG, or HEIC images, then decode it as BCBP
- Extract bag tags, frequent flyer info, and security data
- Convert Julian day-of-year to calendar dates (with year inference)
- Configurable trimming and empty-string handling
- Built-in demo data for testing
- Shared golden fixtures under [`testdata/`](testdata) (including [`testdata/images/`](testdata/images))

## Repository Layout

```
BoardingPassKit/
├── packages/
│   ├── rust/           # Canonical Rust decoder
│   ├── ffi/            # C ABI (JSON decode results)
│   ├── python/         # PyO3 / maturin package
│   ├── go/             # Go cgo package
│   ├── php/            # PHP FFI package
│   ├── swift/          # BoardingPassKit Swift library
│   └── node/           # boarding-pass-kit npm package
├── testdata/           # Shared barcodes + expected JSON
├── apps/
│   └── BoardingPassKitDemo/
├── Cargo.toml          # Rust workspace
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
    .package(url: "https://github.com/anomaddev/BoardingPassKit.git", from: "2.3.3")
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

// PNG / JPEG / HEIC → QR / Aztec / PDF417 string → boarding pass
let barcodeString = try BoardingPassQRExtractor.payload(from: imageData)
let passFromImage = try decoder.decode(imageData: imageData)

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

import { extractQrPayload } from 'boarding-pass-kit';

const payload = await extractQrPayload('./pass.png'); // QR, Aztec, or PDF417 in PNG/JPEG/HEIC
const passFromImage = await decoder.decodeFromImage('./pass.heic');
```

## Rust / Python / Go / PHP

Build the Rust workspace and FFI library from the repo root:

```bash
cargo test -p boarding-pass-kit
cargo build -p boarding-pass-kit-ffi --release
```

Then follow each package README:

- [`packages/rust/README.md`](packages/rust/README.md)
- [`packages/python/README.md`](packages/python/README.md)
- [`packages/go/README.md`](packages/go/README.md)
- [`packages/php/README.md`](packages/php/README.md)

## Development

```bash
# Node.js
npm install
npm run build
npm test

# Rust core + FFI
cargo test -p boarding-pass-kit
cargo build -p boarding-pass-kit-ffi --release

# Python
python3 -m venv .venv && . .venv/bin/activate
pip install maturin pytest
cd packages/python && maturin develop && pytest

# Go
cd packages/go && go test ./...

# PHP
cd packages/php && composer install && composer test

# Swift (macOS)
swift build
swift test
```

## Demo Data

All language packages include the same fixtures: `Simple`, `Historical`, `MultiLeg`, and `International`. Canonical golden expectations live in [`testdata/`](testdata).

## License

MIT — see [LICENSE](LICENSE).

## Author

Justin Ackermann
