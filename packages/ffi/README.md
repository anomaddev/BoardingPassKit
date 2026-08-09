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

char *bpk_decode(const char *barcode, const BpkOptions *options);
char *bpk_julian_to_date(int day_of_year, int year, int64_t relative_to_ms);
const char *bpk_last_error(void);
void bpk_free_string(char *ptr);
```

Callers must free strings returned by `bpk_decode` / `bpk_julian_to_date` with `bpk_free_string`.
