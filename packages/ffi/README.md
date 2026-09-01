# boarding-pass-kit-ffi

C ABI for the Rust `boarding-pass-kit` core. Decode results are returned as JSON strings.

## Build

From the repository root:

```bash
cargo build -p boarding-pass-kit-ffi --release
```

Artifacts:

- `target/release/libboarding_pass_kit_ffi.so` (Linux)
- `target/release/libboarding_pass_kit_ffi.a`
- Header: [`include/boarding_pass_kit.h`](include/boarding_pass_kit.h)

## API

```c
typedef struct BpkOptions {
    int debug;
    int trim_leading_zeroes;
    int trim_whitespace;
    int empty_string_is_nil;
} BpkOptions;

char *bpk_decode(const char *barcode, const BpkOptions *options, char **error_out);
char *bpk_extract_qr(const uint8_t *data, size_t len, char **error_out);
char *bpk_julian_to_date(int day_of_year, int year, int64_t relative_to_ms, char **error_out);
const char *bpk_last_error(void); /* borrowed TLS; do not free */
void bpk_free_string(char *ptr);
```

`bpk_extract_qr` reads PNG/JPEG bytes (and HEIC when the crate is built with `--features heic`) and returns the first QR, Aztec, or PDF417 payload string. Callers must free strings returned by `bpk_decode` / `bpk_extract_qr` / `bpk_julian_to_date` and any `*error_out` with `bpk_free_string`. Prefer `error_out` over `bpk_last_error` in multi-threaded hosts.

HEIC support:

```bash
cargo build -p boarding-pass-kit-ffi --release --features heic
```
