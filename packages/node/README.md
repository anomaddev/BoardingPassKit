# boarding-pass-kit

TypeScript/Node.js library for parsing **IATA BCBP v8** boarding pass barcodes and QR codes.

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
git tag v2.1.3
git push origin v2.1.3
```

GitHub Actions runs tests, builds, and publishes via the `Publish` workflow.

**One-time setup:** add an npm [access token](https://www.npmjs.com/settings/~yourusername/tokens) as the `NPM_TOKEN` repository secret (Settings → Secrets and variables → Actions). Use an **Automation** or **Publish** token if you have 2FA enabled.

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
