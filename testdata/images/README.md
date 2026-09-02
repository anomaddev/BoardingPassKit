# Image fixtures

Barcode images of `DemoData.Simple` plus error cases used by Node, Rust, Python, Go, PHP, and Swift tests.

| File | Contents |
|------|----------|
| `simple.png` | QR of `Simple` |
| `simple.jpg` | QR of `Simple` |
| `simple.heic` | QR of `Simple` (`ftypheic`) |
| `simple_aztec.png` | Aztec of `Simple` |
| `simple_pdf417.png` | PDF417 of `Simple` |
| `no_qr.png` | Valid PNG with no barcode |
| `wallet_aztec_low_contrast.png` | 1024×577 wallet crop: washed-out light-gray Aztec on white, blue card (Node hard-image retry) |
| `not_an_image.bin` | Garbage bytes |
