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
```

Decoded results are plain dicts with the same camelCase field names as the Node package.
