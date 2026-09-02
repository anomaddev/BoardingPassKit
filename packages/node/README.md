# boarding-pass-kit

TypeScript/Node.js library for parsing **IATA BCBP v8** boarding pass barcodes, including QR, Aztec, and PDF417 codes in PNG, JPEG, and HEIC images.

**Compliance:** IATA Resolution 792 - BCBP Version 8 (Effective June 1, 2020)

## Installation

```bash
npm install boarding-pass-kit
```

Requires Node.js 18+.

## Publishing (maintainers)

Releases are published to npm automatically when a version tag is pushed.

1. Bump `version` in `packages/node/package.json`
2. Commit and push to `main`
3. Create and push a matching tag:

```bash
git tag v2.3.4
git push origin v2.3.4
```

GitHub Actions runs tests, builds, and publishes via the `Publish` workflow using [npm trusted publishing](https://docs.npmjs.com/trusted-publishers) (OIDC). Do not set `NODE_AUTH_TOKEN` / `NPM_TOKEN` on that job — a stale token produces a misleading `404` on publish.

**One-time setup** on [npmjs.com](https://www.npmjs.com/package/boarding-pass-kit) → package Settings → Trusted Publisher:

- Organization or user: `anomaddev`
- Repository: `BoardingPassKit`
- Workflow filename: `publish.yml` (no path)
- Environment: `build-env`

## Quick Start

```typescript
import { BoardingPassDecoder, DemoData } from 'boarding-pass-kit';

const decoder = new BoardingPassDecoder();
decoder.debug = false;

const pass = decoder.decode(DemoData.Simple);

console.log(pass.passengerName);
console.log(pass.boardingPassLegs[0]!.origin);
console.log(pass.boardingPassLegs[0]!.destination);
console.log(pass.boardingPassLegs[0]!.flightno);
```

Decode from a `Buffer`:

```typescript
const pass = decoder.decode(Buffer.from(barcodeString, 'ascii'));
```

## Image barcode extraction

Read a boarding-pass QR, Aztec, or PDF417 barcode from a PNG, JPEG, or HEIC image and get the BCBP string. Pass that string to `decode()`, or use `decodeFromImage()` to do both steps.

```typescript
import { BoardingPassDecoder, extractQrPayload } from 'boarding-pass-kit';

const payload = await extractQrPayload('./pass.png'); // Buffer | Uint8Array | file path
const decoder = new BoardingPassDecoder();
decoder.debug = false;
const pass = decoder.decode(payload);

// or in one step
const passFromImage = await decoder.decodeFromImage('./pass.heic');
```

`extractQrPayload` looks for the first QR, Aztec, or PDF417 barcode. If none is found it retries 90/180/270° rotations (common with camera EXIF). Data Matrix is not scanned.

Difficult photos and wallet screenshots — low-contrast or washed-out modules, or a barcode sitting on a strong colored background — are retried internally (bright-range stretch and extra binarizers). Callers do not preprocess the image.

## Configuration

```typescript
const decoder = new BoardingPassDecoder();

decoder.debug = false;              // Verbose console logging (default: true)
decoder.trimLeadingZeroes = true;   // Strip leading zeros from numeric fields
decoder.trimWhitespace = true;    // Trim whitespace from parsed fields
decoder.emptyStringIsNil = true;  // Convert empty strings to null
```

## Julian Date Conversion

BCBP encodes flight date as a 3-digit **day-of-year** (001–366). The year is not stored in the barcode.

```typescript
import { julianToCalendarDate } from 'boarding-pass-kit';

// Explicit year
const date = julianToCalendarDate(14, 2025); // January 14, 2025

// Infer year from reference date (default: today)
const date = julianToCalendarDate(14, new Date('2024-08-01'));

// On a decoded leg
const flightDate = pass.boardingPassLegs[0]!.flightDate();
const flightDate2025 = pass.boardingPassLegs[0]!.flightDate({ year: 2025 });
const flightDateAtScan = pass.boardingPassLegs[0]!.flightDate({ relativeTo: scanDate });
```

Year inference uses a ±183-day heuristic for flights near year boundaries.

## Demo Data

```typescript
import { DemoData, randomDemoData } from 'boarding-pass-kit';

DemoData.Simple;
DemoData.Historical;
DemoData.MultiLeg;
DemoData.International;

const key = randomDemoData();
const pass = decoder.decode(DemoData[key]);
```

## API Reference

### `BoardingPassDecoder`

| Method | Description |
|--------|-------------|
| `decode(code: string)` | Parse an ASCII barcode string |
| `decode(data: Buffer \| Uint8Array)` | Parse raw bytes |
| `decodeFromImage(image)` | Extract a QR, Aztec, or PDF417 payload from PNG/JPEG/HEIC, then decode |

`extractQrPayload(image)` is a standalone export that returns only the barcode string.

### Types

- `BoardingPass` — Full decoded pass
- `BoardingPassLeg` — One flight segment (includes `flightDate()`)
- `BoardingPassLegData` — Leg conditional data
- `BoardingPassInfo` — Unique conditional block (bag tags, etc.)
- `BoardingPassSecurityData` — Optional security trailer

### Errors

Throws `BoardingPassError` with a `code` from `BoardingPassErrorCode`:

- `MandatoryItemNotFound` — Truncated or incomplete data
- `DataFailedValidation` — Missing required values
- `HexStringFailedDecoding` — Invalid hex field
- `BoardingPassLegConditionalMismatch` — Conditional section size mismatch
- `InvalidJulianDay` — Day-of-year out of range
- `DataIsNotBoardingPass` — Wrapper for inner parse errors
- `QRCodeNotFound` — Image decoded but no QR, Aztec, or PDF417 barcode was found
- `UnsupportedImageFormat` — Not PNG, JPEG, or HEIC
- `ImageDecodeFailed` — Image bytes were a supported type but could not be rasterized

## Multi-Leg Support

```typescript
const pass = decoder.decode(DemoData.MultiLeg);
console.log(pass.numberOfLegs); // 2

for (const leg of pass.boardingPassLegs) {
  console.log(`${leg.origin} → ${leg.destination}`);
}
```

## License

MIT
