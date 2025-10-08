import XCTest
@testable import BoardingPassKit

final class BoardingPassKitTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
//        XCTAssertEqual(BoardingPassKit().text, "Hello, World!")
    }
    
    func testTrimLeadingZeroes() throws {
        let decoder = BoardingPassDecoder()
        decoder.trimLeadingZeroes = true
        
        // Test the removeLeadingZeros extension method
        XCTAssertEqual("00123".removeLeadingZeros(), "123")
        XCTAssertEqual("00000".removeLeadingZeros(), "")
        XCTAssertEqual("12345".removeLeadingZeros(), "12345")
        XCTAssertEqual("0".removeLeadingZeros(), "")
        XCTAssertEqual("".removeLeadingZeros(), "")
        XCTAssertEqual("ABC".removeLeadingZeros(), "ABC")
    }
    
    func testTrimLeadingZeroesWithReadint() throws {
        // Test that the removeLeadingZeros method works correctly for numeric strings
        let decoder = BoardingPassDecoder()
        decoder.trimLeadingZeroes = true
        
        // Test various numeric strings with leading zeros
        XCTAssertEqual("00123".removeLeadingZeros(), "123")
        XCTAssertEqual("00000".removeLeadingZeros(), "")
        XCTAssertEqual("01234".removeLeadingZeros(), "1234")
        XCTAssertEqual("00001".removeLeadingZeros(), "1")
        
        // Test that non-numeric strings are handled correctly
        XCTAssertEqual("ABC".removeLeadingZeros(), "ABC")
        XCTAssertEqual("0ABC".removeLeadingZeros(), "ABC")
    }
}
