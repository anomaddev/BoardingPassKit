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
        XCTAssertEqual(calendar.component(.year, from: flightDate!), 2025)
    }
}
