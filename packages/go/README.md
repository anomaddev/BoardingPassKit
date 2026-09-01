# boarding-pass-kit (Go)

Go bindings for the Rust `boarding-pass-kit` core via the C FFI library.

## Prerequisites

Build the FFI library from the repository root (release **or** debug):

```bash
cargo build -p boarding-pass-kit-ffi --release
# HEIC: cargo build -p boarding-pass-kit-ffi --release --features heic
# or: cargo build -p boarding-pass-kit-ffi
```

## Test

```bash
cd packages/go
go test ./...
```

On Linux, cgo statically links `libboarding_pass_kit_ffi.a` from `target/release` or `target/debug`.

## Quick start

```go
package main

import (
    "fmt"
    "os"
    bpk "github.com/anomaddev/BoardingPassKit/packages/go"
)

func main() {
    pass, err := bpk.Decode(bpk.DemoData["Simple"], bpk.DefaultOptions())
    if err != nil {
        panic(err)
    }
    fmt.Println(pass["passengerName"])

    image, err := os.ReadFile("pass.png")
    if err != nil {
        panic(err)
    }
    payload, err := bpk.ExtractQR(image)
    if err != nil {
        panic(err)
    }
    passFromImage, err := bpk.DecodeFromImage(image, bpk.DefaultOptions())
    if err != nil {
        panic(err)
    }
    fmt.Println(payload, passFromImage["passengerName"])
}
```

`ExtractQR` reads a QR, Aztec, or PDF417 payload from PNG/JPEG bytes (and HEIC when the FFI library is built with `--features heic`). When linking a HEIC-enabled static library on Linux, pass `CGO_LDFLAGS="-lheif"`.
