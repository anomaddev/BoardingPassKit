import json
from pathlib import Path

import pytest

from boarding_pass_kit import BoardingPassDecoder, DemoData, julian_to_date

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
