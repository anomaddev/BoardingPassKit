# boarding-pass-kit (Rust)

IATA BCBP (Resolution 792, Version 8) boarding pass barcode decoder. This crate is the **canonical core** used by the Python, Go, and PHP bindings in this monorepo.

## Install

```toml
[dependencies]
boarding-pass-kit = { path = "packages/rust" }
```

## Quick start

```rust
use boarding_pass_kit::{demo_data, BoardingPassDecoder};

fn main() -> Result<(), boarding_pass_kit::BoardingPassError> {
    let mut decoder = BoardingPassDecoder::new();
    decoder.debug = false;

    let pass = decoder.decode(demo_data("Simple").unwrap())?;
    println!("{}", pass.passenger_name);
    println!("{}", pass.boarding_pass_legs[0].origin);
    Ok(())
}
```

## Test

From the repository root:

```bash
cargo test -p boarding-pass-kit
```
