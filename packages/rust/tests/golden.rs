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
