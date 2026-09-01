import json
from pathlib import Path

import pytest

from boarding_pass_kit import BoardingPassDecoder, DemoData, extract_qr_payload, julian_to_date

TESTDATA = Path(__file__).resolve().parents[3] / "testdata"


@pytest.fixture
def expected():
    return json.loads((TESTDATA / "expected.json").read_text())


@pytest.fixture
def decoder():
    d = BoardingPassDecoder()
    d.debug = False
    return d


@pytest.mark.parametrize("key", ["Simple", "Historical", "MultiLeg", "International"])
def test_golden(decoder, expected, key):
    barcode = DemoData[key]
    pass_dict = decoder.decode(barcode)
    assert pass_dict == expected[key]


def test_truncated_raises(decoder):
    with pytest.raises(ValueError):
        decoder.decode("M1ACKERMANN/JUSTIN")


def test_julian_to_date():
    assert julian_to_date(14, year=2025) == "2025-01-14"


def test_extract_qr_png():
    payload = extract_qr_payload((TESTDATA / "images" / "simple.png").read_bytes())
    assert payload == DemoData["Simple"]


def test_extract_qr_jpeg():
    payload = extract_qr_payload((TESTDATA / "images" / "simple.jpg").read_bytes())
    assert payload == DemoData["Simple"]


def test_decode_from_image_png(decoder):
    pass_dict = decoder.decode_from_image((TESTDATA / "images" / "simple.png").read_bytes())
    assert pass_dict["boardingPassLegs"][0]["origin"] == "MSY"
    assert pass_dict["code"] == DemoData["Simple"]


def test_extract_aztec_png():
    payload = extract_qr_payload((TESTDATA / "images" / "simple_aztec.png").read_bytes())
    assert payload == DemoData["Simple"]


def test_extract_pdf417_png():
    payload = extract_qr_payload((TESTDATA / "images" / "simple_pdf417.png").read_bytes())
    assert payload == DemoData["Simple"]


def test_extract_qr_no_code():
    with pytest.raises(ValueError, match="No QR, Aztec, or PDF417"):
        extract_qr_payload((TESTDATA / "images" / "no_qr.png").read_bytes())


def test_extract_qr_not_an_image():
    with pytest.raises(ValueError, match="Unsupported image format"):
        extract_qr_payload((TESTDATA / "images" / "not_an_image.bin").read_bytes())


def test_extract_qr_heic():
    image = (TESTDATA / "images" / "simple.heic").read_bytes()
    try:
        payload = extract_qr_payload(image)
    except ValueError as exc:
        if "heic" in str(exc).lower() or "HEIC" in str(exc):
            pytest.skip(str(exc))
        raise
    assert payload == DemoData["Simple"]
