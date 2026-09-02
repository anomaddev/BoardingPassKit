use boarding_pass_kit::{demo_data, extract_qr_payload, BoardingPassDecoder, BoardingPassErrorCode};
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
fn trailing_space_padding_may_be_stripped() {
    // AA YUL-PHL: declared conditional size is 0x47 (71), but copy/paste often
    // drops the trailing IATA space padding on FF / ID-AD / bags / fast-track.
    let visible = "M1ACKERMANN/JUSTIN DAVESWMUYT YULPHLAA 5717 176Y002A0034 147>1180RO4176BAA              29001701407985430   AA 76UXK84";
    assert_eq!(visible.len(), 118);

    let mut decoder = BoardingPassDecoder::new();
    decoder.debug = false;
    let pass = decoder.decode(visible).expect("stripped trailing spaces should still decode");
    assert_eq!(pass.boarding_pass_legs[0].origin, "YUL");
    assert_eq!(pass.boarding_pass_legs[0].destination, "PHL");
    assert_eq!(pass.boarding_pass_legs[0].flightno, "5717");
    assert_eq!(pass.boarding_pass_legs[0].julian_date, 176);
    let cond = pass.boarding_pass_legs[0]
        .conditional_data
        .as_ref()
        .expect("conditional data");
    assert_eq!(cond.ticket_number, "7014079854");
    assert_eq!(cond.ff_airline, "AA");
    assert_eq!(cond.ff_number, "76UXK84");
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

fn testdata_image(name: &str) -> Vec<u8> {
    fs::read(testdata_dir().join("images").join(name)).unwrap_or_else(|e| panic!("{name}: {e}"))
}

#[test]
fn extract_qr_from_png() {
    let payload = extract_qr_payload(&testdata_image("simple.png")).expect("png qr");
    assert_eq!(payload, demo_data("Simple").unwrap());
}

#[test]
fn extract_qr_from_jpeg() {
    let payload = extract_qr_payload(&testdata_image("simple.jpg")).expect("jpeg qr");
    assert_eq!(payload, demo_data("Simple").unwrap());
}

#[test]
fn decode_from_image_png() {
    let mut decoder = BoardingPassDecoder::new();
    decoder.debug = false;
    let pass = decoder
        .decode_from_image(&testdata_image("simple.png"))
        .expect("decode from png");
    assert_eq!(pass.boarding_pass_legs[0].origin, "MSY");
    assert_eq!(pass.code, demo_data("Simple").unwrap());
}

#[test]
fn extract_aztec_from_png() {
    let payload = extract_qr_payload(&testdata_image("simple_aztec.png")).expect("png aztec");
    assert_eq!(payload, demo_data("Simple").unwrap());
}

#[test]
fn extract_pdf417_from_png() {
    let payload = extract_qr_payload(&testdata_image("simple_pdf417.png")).expect("png pdf417");
    assert_eq!(payload, demo_data("Simple").unwrap());
}

#[test]
fn extract_qr_missing_code() {
    let err = extract_qr_payload(&testdata_image("no_qr.png")).unwrap_err();
    assert_eq!(err.code, BoardingPassErrorCode::QRCodeNotFound);
}

#[test]
fn extract_qr_not_an_image() {
    let err = extract_qr_payload(&testdata_image("not_an_image.bin")).unwrap_err();
    assert_eq!(err.code, BoardingPassErrorCode::UnsupportedImageFormat);
}

#[cfg(feature = "heic")]
#[test]
fn extract_qr_from_heic() {
    let payload = extract_qr_payload(&testdata_image("simple.heic")).expect("heic qr");
    assert_eq!(payload, demo_data("Simple").unwrap());
}

#[cfg(not(feature = "heic"))]
#[test]
fn extract_qr_heic_requires_feature() {
    let err = extract_qr_payload(&testdata_image("simple.heic")).unwrap_err();
    assert_eq!(err.code, BoardingPassErrorCode::UnsupportedImageFormat);
}
