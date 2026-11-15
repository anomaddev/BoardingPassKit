import XCTest
@testable import BoardingPassKit

final class BoardingPassKitTests: XCTestCase {

    func testTrimLeadingZeroes() throws {
        XCTAssertEqual("00123".removeLeadingZeros(), "123")
        XCTAssertEqual("00000".removeLeadingZeros(), "")
        XCTAssertEqual("12345".removeLeadingZeros(), "12345")
        XCTAssertEqual("0".removeLeadingZeros(), "")
        XCTAssertEqual("".removeLeadingZeros(), "")
        XCTAssertEqual("ABC".removeLeadingZeros(), "ABC")
    }

    func testTrimLeadingZeroesWithReadint() throws {
        XCTAssertEqual("00123".removeLeadingZeros(), "123")
        XCTAssertEqual("00000".removeLeadingZeros(), "")
        XCTAssertEqual("01234".removeLeadingZeros(), "1234")
        XCTAssertEqual("00001".removeLeadingZeros(), "1")
        XCTAssertEqual("ABC".removeLeadingZeros(), "ABC")
        XCTAssertEqual("0ABC".removeLeadingZeros(), "ABC")
    }

    func testDecodeAfterTrailingSpacesStripped() throws {
        let cases: [(String, String, String, String, Int, String)] = [
            (
                "M1ACKERMANN/JUSTIN DAVESWMUYT YULPHLAA 5717 176Y002A0034 147>1180RO4176BAA              29001701407985430   AA 76UXK84",
                "YUL", "PHL", "5717", 176, "7014079854"
            ),
            (
                "M1ACKERMANN/JUSTIN DAVEYALLND TPADCAAA 0374 196Y008A0062 147>1180RO4196BAA              29001707442252231   AA 76UXK84",
                "TPA", "DCA", "374", 196, "7074422522"
            ),
        ]

        for (visible, origin, destination, flightno, julian, ticket) in cases {
            XCTAssertEqual(visible.count, 118)

            let decoder = BoardingPassDecoder()
            decoder.debug = false
            let pass = try decoder.decode(code: visible)

            XCTAssertEqual(pass.format, "M")
            XCTAssertEqual(pass.numberOfLegs, 1)
            XCTAssertEqual(pass.boardingPassLegs.count, 1)
            XCTAssertEqual(pass.boardingPassLegs[0].origin, origin)
            XCTAssertEqual(pass.boardingPassLegs[0].destination, destination)
            XCTAssertEqual(pass.boardingPassLegs[0].flightno, flightno)
            XCTAssertEqual(pass.boardingPassLegs[0].julianDate, julian)
            XCTAssertEqual(pass.boardingPassLegs[0].conditionalData?.ticketNumber, ticket)
            XCTAssertEqual(pass.boardingPassLegs[0].conditionalData?.ffAirline, "AA")
            XCTAssertEqual(pass.boardingPassLegs[0].conditionalData?.ffNumber, "76UXK84")
        }
    }

    func testDecodeSimpleDemoData() throws {
        let decoder = BoardingPassDecoder()
        decoder.debug = false
        let pass = try decoder.decode(code: BoardingPass.DemoData.Simple.string)

        XCTAssertEqual(pass.format, "M")
        XCTAssertEqual(pass.numberOfLegs, 1)
        XCTAssertEqual(pass.passengerName, "ACKERMANN/JUSTIN DAV")
        XCTAssertEqual(pass.boardingPassLegs.count, 1)
        XCTAssertEqual(pass.boardingPassLegs[0].origin, "MSY")
        XCTAssertEqual(pass.boardingPassLegs[0].destination, "PHX")
        XCTAssertEqual(pass.boardingPassLegs[0].julianDate, 14)
    }

    func testDecodeMultiLegDemoData() throws {
        let decoder = BoardingPassDecoder()
        decoder.debug = false
        let pass = try decoder.decode(code: BoardingPass.DemoData.MultiLeg.string)

        XCTAssertEqual(pass.numberOfLegs, 2)
        XCTAssertEqual(pass.boardingPassLegs.count, 2)
        XCTAssertEqual(pass.boardingPassLegs[0].origin, "TPA")
        XCTAssertEqual(pass.boardingPassLegs[1].destination, "JNU")
        XCTAssertNotNil(pass.securityData)
    }

    func testJulianToCalendarDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let jan1 = try JulianDateConverter.toCalendarDate(dayOfYear: 1, year: 2024, calendar: calendar)
        XCTAssertEqual(calendar.component(.month, from: jan1), 1)
        XCTAssertEqual(calendar.component(.day, from: jan1), 1)

        let dec31Leap = try JulianDateConverter.toCalendarDate(dayOfYear: 366, year: 2024, calendar: calendar)
        XCTAssertEqual(calendar.component(.month, from: dec31Leap), 12)
        XCTAssertEqual(calendar.component(.day, from: dec31Leap), 31)
    }

    func testJulianYearInference() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var components = DateComponents()
        components.year = 2024
        components.month = 8
        components.day = 1
        let reference = calendar.date(from: components)!

        let flightDate = try JulianDateConverter.toCalendarDate(dayOfYear: 14, relativeTo: reference, calendar: calendar)
        XCTAssertEqual(calendar.component(.year, from: flightDate), 2025)
        XCTAssertEqual(calendar.component(.month, from: flightDate), 1)
        XCTAssertEqual(calendar.component(.day, from: flightDate), 14)
    }

    func testBoardingPassLegFlightDate() throws {
        let decoder = BoardingPassDecoder()
        decoder.debug = false
        let pass = try decoder.decode(code: BoardingPass.DemoData.Simple.string)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var components = DateComponents()
        components.year = 2024
        components.month = 8
        components.day = 1
        let reference = calendar.date(from: components)!

        let flightDate = pass.boardingPassLegs[0].flightDate(relativeTo: reference, calendar: calendar)
        XCTAssertNotNil(flightDate)
        // Simple's date of issue is 0014 (year digit 0, day 14). The flight day matches,
        // so the year is the closest year ending in 0 to the reference: 2020-01-14.
        XCTAssertEqual(calendar.component(.year, from: flightDate!), 2020)
        XCTAssertEqual(calendar.component(.month, from: flightDate!), 1)
        XCTAssertEqual(calendar.component(.day, from: flightDate!), 14)
    }

#if canImport(Vision)
    func testdataImagesDir() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.path != "/" && url.lastPathComponent != "packages" {
            url.deleteLastPathComponent()
        }
        url.deleteLastPathComponent()
        return url.appendingPathComponent("testdata/images")
    }

    func testdataImage(_ name: String) throws -> Data {
        try Data(contentsOf: testdataImagesDir().appendingPathComponent(name))
    }

    func testExtractQRFromPNG() throws {
        let payload = try BoardingPassQRExtractor.payload(from: testdataImage("simple.png"))
        XCTAssertEqual(payload, BoardingPass.DemoData.Simple.string)
    }

    func testExtractQRFromJPEG() throws {
        let payload = try BoardingPassQRExtractor.payload(from: testdataImage("simple.jpg"))
        XCTAssertEqual(payload, BoardingPass.DemoData.Simple.string)
    }

    func testExtractQRFromHEIC() throws {
        let payload = try BoardingPassQRExtractor.payload(from: testdataImage("simple.heic"))
        XCTAssertEqual(payload, BoardingPass.DemoData.Simple.string)
    }

    func testDecodeFromImagePNG() throws {
        let decoder = BoardingPassDecoder()
        decoder.debug = false
        let pass = try decoder.decode(imageData: testdataImage("simple.png"))
        XCTAssertEqual(pass.boardingPassLegs[0].origin, "MSY")
        XCTAssertEqual(pass.code, BoardingPass.DemoData.Simple.string)
    }

    func testExtractAztecFromPNG() throws {
        let payload = try BoardingPassQRExtractor.payload(from: testdataImage("simple_aztec.png"))
        XCTAssertEqual(payload, BoardingPass.DemoData.Simple.string)
    }

    func testExtractPDF417FromPNG() throws {
        let payload = try BoardingPassQRExtractor.payload(from: testdataImage("simple_pdf417.png"))
        XCTAssertEqual(payload, BoardingPass.DemoData.Simple.string)
    }

    func testExtractQRMissingCode() {
        XCTAssertThrowsError(try BoardingPassQRExtractor.payload(from: testdataImage("no_qr.png"))) { error in
            guard case BoardingPassError.QRCodeNotFound = error else {
                return XCTFail("expected QRCodeNotFound, got \(error)")
            }
        }
    }

    func testExtractQRUnsupportedFormat() {
        XCTAssertThrowsError(try BoardingPassQRExtractor.payload(from: testdataImage("not_an_image.bin"))) { error in
            guard case BoardingPassError.UnsupportedImageFormat = error else {
                return XCTFail("expected UnsupportedImageFormat, got \(error)")
            }
        }
    }
#endif

    /// Issue #24: non-ASCII input must throw `DataFailedStringDecoding` instead of trapping.
    func testDecodeNonASCIIThrowsInsteadOfCrashing() {
        let base = BoardingPass.DemoData.Simple.string
        let chars = Array(base)
        XCTAssertGreaterThan(chars.count, 40)

        func replacing(_ index: Int, with character: Character) -> String {
            var copy = chars
            copy[index] = character
            return String(copy)
        }

        let samples = [
            "M1CAFÉ",
            replacing(2, with: "É"),
            replacing(2, with: "ñ"),
            replacing(30, with: "ü"),
            replacing(chars.count - 1, with: "€"),
            "M1✈️ACKERMANN/JUSTIN",
            "M1" + String(repeating: "😀", count: 3),
            "M1CAFE\u{0301}XXXXXXXXXXXXXXX",
            "M1王小明",
            "👨‍✈️",
            "M1CAF\u{1D538}",
        ]

        for sample in samples {
            let decoder = BoardingPassDecoder()
            decoder.debug = false
            XCTAssertThrowsError(try decoder.decode(code: sample), "expected throw for \(sample)") { error in
                guard let boardingError = error as? BoardingPassError,
                      case .DataFailedStringDecoding = boardingError else {
                    return XCTFail("expected DataFailedStringDecoding for \(sample), got \(error)")
                }
                XCTAssertTrue(
                    boardingError.description.contains("ASCII"),
                    "error should describe the ASCII rejection, got \(boardingError.description)"
                )
            }
        }
    }

    func testDecodeASCIIBoundaryDoesNotMisclassify() {
        let decoder = BoardingPassDecoder()
        decoder.debug = false

        // DEL is ASCII. Too short to be a boarding pass, but the failure is validation.
        XCTAssertThrowsError(try decoder.decode(code: "M\u{7F}")) { error in
            if case BoardingPassError.DataFailedStringDecoding = error {
                XCTFail("U+007F is ASCII and must not be reported as an encoding failure")
            }
        }

        // The first non-ASCII scalar must throw instead of trapping.
        XCTAssertThrowsError(try decoder.decode(code: "M\u{80}")) { error in
            guard case BoardingPassError.DataFailedStringDecoding = error else {
                return XCTFail("expected DataFailedStringDecoding for U+0080, got \(error)")
            }
        }
    }

    func testDecodeNonASCIIDataThrows() {
        let decoder = BoardingPassDecoder()
        decoder.debug = false
        let data = Data("M1CAFÉ".utf8)
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case BoardingPassError.DataFailedStringDecoding = error else {
                return XCTFail("expected DataFailedStringDecoding, got \(error)")
            }
        }
    }

    func testDecodeMalformedASCIIThrows() {
        let decoder = BoardingPassDecoder()
        decoder.debug = false
        XCTAssertThrowsError(try decoder.decode(code: "M")) { error in
            guard case BoardingPassError.MandatoryItemNotFound = error else {
                return XCTFail("expected MandatoryItemNotFound, got \(error)")
            }
        }
        XCTAssertThrowsError(try decoder.decode(code: "")) { error in
            guard case BoardingPassError.MandatoryItemNotFound = error else {
                return XCTFail("expected MandatoryItemNotFound, got \(error)")
            }
        }
    }

    func testDecodeValidPassAfterNonASCIIFailure() throws {
        let decoder = BoardingPassDecoder()
        decoder.debug = false
        XCTAssertThrowsError(try decoder.decode(code: "M1CAFÉ"))

        let code = BoardingPass.DemoData.Simple.string
        let pass = try decoder.decode(code: code)
        XCTAssertEqual(pass.passengerName, "ACKERMANN/JUSTIN DAV")
        XCTAssertEqual(pass.code, code)
        XCTAssertEqual(pass.boardingPassLegs[0].origin, "MSY")
    }
}
