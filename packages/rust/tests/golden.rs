use boarding_pass_kit::{demo_data, BoardingPassDecoder};
use serde_json::Value;
use std::fs;
use std::path::PathBuf;

fn testdata_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../testdata")
}

#[test]
fn golden_fixtures_match_node() {
    let expected_raw = fs::read_to_string(testdata_dir().join("expected.json"))
        .expect("expected.json should exist");
    let expected: Value = serde_json::from_str(&expected_raw).unwrap();

    let mut decoder = BoardingPassDecoder::new();
    decoder.debug = false;

    for key in ["Simple", "Historical", "MultiLeg", "International"] {
        let barcode = demo_data(key).expect("demo key");
        let pass = decoder.decode(barcode).unwrap_or_else(|e| panic!("{key}: {e}"));
        let actual = serde_json::to_value(&pass).unwrap();
        assert_eq!(
            actual, expected[key],
            "mismatch for fixture {key}\nactual={actual}\nexpected={}",
            expected[key]
        );
    }
}

#[test]
fn truncated_input_errors() {
    let mut decoder = BoardingPassDecoder::new();
    decoder.debug = false;
    let err = decoder.decode("M1ACKERMANN/JUSTIN").unwrap_err();
    assert!(matches!(
        err.code,
        boarding_pass_kit::BoardingPassErrorCode::MandatoryItemNotFound
    ));
}

#[test]
fn short_conditional_read_does_not_panic() {
    // Oversized unique conditional size with no body — Node Buffer.subarray
    // short-reads instead of panicking; Rust must match that behavior.
    let mut barcode = String::from("M1ACKERMANN/JUSTIN DAV");
    barcode.push_str("EJKLEAJ"); // pnr
    barcode.push_str("MSY"); // origin
    barcode.push_str("PHX"); // dest
    barcode.push_str("AA "); // carrier
    barcode.push_str("2819 "); // flight
    barcode.push_str("014"); // julian
    barcode.push_str("S"); // compartment
    barcode.push_str("008F"); // seat
    barcode.push_str("0059 "); // check-in
    barcode.push_str("1"); // status
    barcode.push_str("04"); // conditional size = 4
    barcode.push_str(">30A"); // unique start + version + oversized hex size, no body

    let mut decoder = BoardingPassDecoder::new();
    decoder.debug = false;
    let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| decoder.decode(&barcode)));
    assert!(result.is_ok(), "decode panicked on short conditional read");
    assert!(result.unwrap().is_err(), "expected a decode error, not success");
}
