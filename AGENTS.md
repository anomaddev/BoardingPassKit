# AGENTS.md

## Cursor Cloud specific instructions

This repo is a monorepo for **BoardingPassKit**, a client-side IATA BCBP (Resolution 792, v8) boarding-pass parsing library. It ships the same library in two ecosystems plus a demo app:

- `packages/node` — `boarding-pass-kit` npm/TypeScript package (built with `tsup`, tested with `vitest`).
- `packages/swift` — Swift Package Manager / CocoaPods library. The root `Package.swift` and `BoardingPassParser.podspec` are thin wrappers over it.
- `apps/BoardingPassKitDemo` — iOS demo app (Xcode).

### Scope on this Linux VM
- The **Node package** builds, tests, and runs here, including PNG/JPEG/HEIC barcode extraction (`extractQrPayload` / `decodeFromImage`) for QR, Aztec, and PDF417. HEIC uses the WASM `heic-decode` package — no system libheif is required for Node.
- Rust / Python / Go / PHP can be built here when those toolchains are present. Rust HEIC support needs the `heic` feature plus system `libheif` (`libheif-dev` and `libheif-plugin-libde265`).
- The Swift package and iOS demo require **macOS + Xcode** (no Swift toolchain is installed on this Linux VM), so `swift build` / `swift test` / `npm run test:swift` and the demo app are out of scope in Cloud.
- There are **no servers, databases, ports, or environment variables**. This is a pure library — "running" it means building it and executing a decode against the bundled `DemoData` fixtures (`Simple`, `Historical`, `MultiLeg`, `International`) or the QR images under `testdata/images/`.

### Commands (run from repo root, standard scripts — see `README.md` "Development")
- Build: `npm run build` (delegates to `tsup` in `packages/node`).
- Test: `npm test` (delegates to `vitest run`).

### Gotchas
- **No linter is configured** — there is no ESLint/Prettier/SwiftLint config and no `lint` script. CI (`.github/workflows/ci.yml`) only runs build + test. Do not expect a lint step to exist.
- The package is ESM (`"type": "module"`). When smoke-testing the built output directly, import from `packages/node/dist/index.js` after `npm run build`.
- Leg fields use short names: `flightno` and `seatno` (not `flightNumber`/`seatNumber`).
- Image barcode extraction reads QR, Aztec, and PDF417 (not Data Matrix). Shared fixtures: `testdata/images/simple.{png,jpg,heic}`, `simple_aztec.png`, `simple_pdf417.png`, `no_qr.png`, `not_an_image.bin`.
