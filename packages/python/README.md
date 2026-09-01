# boarding-pass-kit (Python)

Python bindings for the Rust `boarding-pass-kit` core (PyO3 / maturin).

## Install (from this repo)

```bash
pip install maturin pytest
cd packages/python
maturin develop
pytest
```

## Quick start

```python
from boarding_pass_kit import BoardingPassDecoder, DemoData

decoder = BoardingPassDecoder()
decoder.debug = False

pass_data = decoder.decode(DemoData["Simple"])
print(pass_data["passengerName"])
print(pass_data["boardingPassLegs"][0]["origin"])

from pathlib import Path
from boarding_pass_kit import extract_qr_payload

payload = extract_qr_payload(Path("pass.png").read_bytes())
pass_from_image = decoder.decode_from_image(Path("pass.heic").read_bytes())
```

Decoded results are plain dicts with the same camelCase field names as the Node package.

PNG and JPEG QR extraction is always available. HEIC requires building with the `heic` feature (`maturin develop --features heic`) and a system `libheif`.
