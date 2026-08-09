# boarding-pass-kit (Go)

Go bindings for the Rust `boarding-pass-kit` core via the C FFI library.

## Prerequisites

Build the FFI library from the repository root (release **or** debug):

```bash
cargo build -p boarding-pass-kit-ffi --release
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
    bpk "github.com/anomaddev/BoardingPassKit/packages/go"
)

func main() {
    pass, err := bpk.Decode(bpk.DemoData["Simple"], bpk.DefaultOptions())
    if err != nil {
        panic(err)
    }
    fmt.Println(pass["passengerName"])
}
```
