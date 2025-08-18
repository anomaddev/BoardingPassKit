//
//  BoardingPassParent.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation

/**
 * Core boarding pass information shared across all flight segments
 *
 * The `BoardingPassParent` struct contains the essential information that applies
 * to the entire boarding pass, regardless of whether it's a single-segment or
 * multi-segment journey. This represents the mandatory 60-character section of
 * the IATA BCBP (Boarding Pass Bar Code) standard.
 *
 * ## Structure Overview
 * The parent information contains the core flight details that are common to
 * all segments of the journey:
 * - **Passenger Information**: Name, ticket details, PNR code
 * - **Flight Information**: Origin, destination, carrier, flight number
 * - **Travel Details**: Date, compartment, seat, check-in status
 * - **Structural Information**: Format, number of legs, conditional data size
 *
 * ## Usage Example
 * ```swift
 * let boardingPass = try decoder.decode(code: barcodeString)
 * let info = boardingPass.info
 * 
 * // Access passenger information
 * print("Passenger: \(info.name)")
 * print("PNR Code: \(info.pnrCode)")
 * 
 * // Access flight information
 * print("Flight: \(info.operatingCarrier) \(info.flightno)")
 * print("Route: \(info.origin) → \(info.destination)")
 * 
 * // Access travel details
 * print("Date: \(info.julianDate)")
 * print("Seat: \(info.seatno)")
 * print("Check-in: \(info.checkIn)")
 * 
 * // Check if multi-segment
 * if info.legs > 1 {
 *     print("Multi-leg journey with \(info.legs) segments")
 * }
 * ```
 *
 * ## IATA BCBP Field Mapping
 * The parent information corresponds to the mandatory fields section of the IATA BCBP standard:
 * - **Characters 1**: Format code (M/S)
 * - **Characters 2**: Number of legs
 * - **Characters 3-22**: Passenger name
 * - **Characters 23**: Ticket indicator
 * - **Characters 24-30**: PNR code
 * - **Characters 31-33**: Origin airport
 * - **Characters 34-36**: Destination airport
 * - **Characters 37-39**: Operating carrier
 * - **Characters 40-44**: Flight number
 * - **Characters 45-47**: Julian date
 * - **Characters 48**: Compartment code
 * - **Characters 49-52**: Seat number
 * - **Characters 53-57**: Check-in sequence
 * - **Characters 58**: Passenger status
 * - **Characters 59-60**: Conditional data size (hex)
 */
public struct BoardingPassParent: Codable {
    
    // MARK: - Format and Structure Information
    
    /**
     * Boarding pass format code
     *
     * Indicates whether this is a single-segment or multi-segment boarding pass.
     * This is the first character of the IATA BCBP standard.
     *
     * ## Valid Values
     * - `"M"`: Multi-segment boarding pass (multiple flight segments)
     * - `"S"`: Single-segment boarding pass (one flight segment)
     *
     * ## Usage
     * Used to determine the parsing strategy and whether additional
     * segment data should be expected.
     */
    public let format: String
    
    /**
     * Number of flight segments (legs) in the journey
     *
     * Indicates the total number of flight segments included in this
     * boarding pass, including the main segment.
     *
     * ## Range
     * - **Minimum**: 1 (single flight)
     * - **Typical**: 1-3 (direct or connecting flights)
     * - **Maximum**: Usually 10 or less (complex itineraries)
     *
     * ## Example
     * - `1`: Direct flight (TPA → DFW)
     * - `2`: Connecting flight (TPA → ATL → DFW)
     * - `3`: Multi-stop flight (TPA → ATL → ORD → DFW)
     */
    public let legs: Int
    
    // MARK: - Passenger Information
    
    /**
     * Passenger's full name as recorded in the booking
     *
     * Contains the passenger's name in the format specified by the airline.
     * Typically follows the format "LASTNAME/FIRSTNAME" or "LASTNAME/FIRSTNAME MIDDLENAME".
     *
     * ## Format
     * - **Length**: Exactly 20 characters
     * - **Separator**: Forward slash (/) between last name and first name
     * - **Case**: Usually uppercase
     * - **Padding**: Right-padded with spaces if name is shorter than 20 characters
     *
     * ## Examples
     * - `"ACKERMANN/JUSTIN    "` (last name + first name + spaces)
     * - `"SMITH/JOHN A        "` (last name + first name + middle initial + spaces)
     * - `"JOHNSON/MARY JANE   "` (last name + first name + middle name + spaces)
     *
     * ## Processing
     * The name can be parsed into components using the `nameSegments` computed
     * property on the `BoardingPass` struct.
     */
    public let name: String
    
    /**
     * Electronic ticket indicator
     *
     * Indicates the type of ticket associated with this boarding pass.
     *
     * ## Common Values
     * - `"E"`: Electronic ticket
     * - `"P"`: Paper ticket
     * - `"M"`: Multiple tickets
     * - `"R"`: Refunded ticket
     * - `"V"`: Voided ticket
     *
     * ## Usage
     * Used by airlines to determine ticket processing requirements
     * and by passengers to understand their ticket type.
     */
    public let ticketIndicator: String
    
    /**
     * Passenger Name Record (PNR) code
     *
     * A unique 6-character alphanumeric code that identifies the passenger's
     * booking record in the airline's reservation system.
     *
     * ## Format
     * - **Length**: Exactly 6 characters
     * - **Characters**: Alphanumeric (A-Z, 0-9)
     * - **Case**: Usually uppercase
     *
     * ## Examples
     * - `"ETDPUPK"`
     * - `"ABC123"`
     * - `"XYZ789"`
     *
     * ## Usage
     * - Used by airlines to retrieve booking details
     * - Referenced in customer service communications
     * - Required for making changes to the booking
     * - Used for tracking baggage and special requests
     */
    public let pnrCode: String
    
    // MARK: - Flight Information
    
    /**
     * IATA code of the origin airport
     *
     * The 3-letter IATA airport code for the departure airport.
     *
     * ## Format
     * - **Length**: Exactly 3 characters
     * - **Characters**: Uppercase letters only
     * - **Standard**: IATA airport code standard
     *
     * ## Examples
     * - `"TPA"`: Tampa International Airport
     * - `"LAX"`: Los Angeles International Airport
     * - `"JFK"`: John F. Kennedy International Airport
     * - `"LHR"`: London Heathrow Airport
     *
     * ## Usage
     * Used for airport identification, flight tracking, and
     * integration with other travel systems.
     */
    public let origin: String
    
    /**
     * IATA code of the destination airport
     *
     * The 3-letter IATA airport code for the arrival airport.
     *
     * ## Format
     * - **Length**: Exactly 3 characters
     * - **Characters**: Uppercase letters only
     * - **Standard**: IATA airport code standard
     *
     * ## Examples
     * - `"DFW"`: Dallas/Fort Worth International Airport
     * - `"ORD"`: Chicago O'Hare International Airport
     * - `"ATL"`: Hartsfield-Jackson Atlanta International Airport
     * - `"CDG"`: Charles de Gaulle Airport
     *
     * ## Usage
     * Used for airport identification, flight tracking, and
     * integration with other travel systems.
     */
    public let destination: String
    
    /**
     * IATA code of the airline operating the flight
     *
     * The 3-letter IATA airline code for the carrier that operates
     * the aircraft for this flight.
     *
     * ## Format
     * - **Length**: Exactly 3 characters
     * - **Characters**: Uppercase letters only
     * - **Standard**: IATA airline code standard
     *
     * ## Examples
     * - `"AA"`: American Airlines
     * - `"DL"`: Delta Air Lines
     * - `"UA"`: United Airlines
     * - `"BA"`: British Airways
     * - `"LH"`: Lufthansa
     *
     * ## Note
     * This is the operating carrier, which may be different from
     * the marketing carrier or the airline that issued the ticket.
     */
    public let operatingCarrier: String
    
    /**
     * Flight number assigned by the operating airline
     *
     * The unique flight identifier assigned by the airline for this
     * specific flight route and departure time.
     *
     * ## Format
     * - **Length**: 1-5 characters
     * - **Characters**: Alphanumeric (A-Z, 0-9)
     * - **Case**: Usually uppercase
     *
     * ## Examples
     * - `"1189"`: American Airlines flight 1189
     * - `"AA123"`: American Airlines flight AA123
     * - `"DL456"`: Delta Air Lines flight DL456
     * - `"UA789"`: United Airlines flight UA789
     *
     * ## Usage
     * Used for flight identification, tracking, and communication
     * with airline staff and other passengers.
     */
    public let flightno: String
    
    // MARK: - Travel Details
    
    /**
     * Julian date of the flight departure
     *
     * The day of the year when the flight departs, expressed as a
     * 3-digit number from 1 to 366.
     *
     * ## Format
     * - **Length**: Exactly 3 characters
     * - **Range**: 001-366 (001 = January 1st, 366 = December 31st in leap years)
     * - **Type**: Integer
     *
     * ## Examples
     * - `"091"`: Day 91 of the year (April 1st in non-leap years)
     * - `"136"`: Day 136 of the year (May 16th in non-leap years)
     * - `"185"`: Day 185 of the year (July 4th in non-leap years)
     * - `"365"`: Day 365 of the year (December 31st in non-leap years)
     *
     * ## Conversion
     * Can be converted to a standard date using calendar calculations
     * or by using date conversion utilities.
     */
    public let julianDate: Int
    
    /**
     * Compartment code for the passenger's cabin class
     *
     * A single character indicating the cabin class or compartment
     * where the passenger is seated.
     *
     * ## Common Values
     * - `"F"`: First Class
     * - `"C"`: Business Class (Club Class)
     * - `"Y"`: Economy Class
     * - `"M"`: Premium Economy
     * - `"P"`: Premium Economy Plus
     * - `"S"`: Super Economy
     * - `"K"`: Discount Economy
     * - `"L"`: Discount Economy
     * - `"T"`: Discount Economy
     * - `"V"`: Discount Economy
     * - `"X"`: Discount Economy
     * - `"B"`: Discount Economy
     * - `"N"`: Discount Economy
     * - `"Q"`: Discount Economy
     * - `"O"`: Discount Economy
     * - `"Z"`: Discount Economy
     * - `"E"`: Discount Economy
     * - `"W"`: Premium Economy
     * - `"U"`: Premium Economy
     * - `"G"`: Premium Economy
     * - `"H"`: Premium Economy
     * - `"J"`: Premium Economy
     * - `"D"`: Premium Economy
     * - `"I"`: Premium Economy
     * - `"R"`: Premium Economy
     * - `"A"`: Premium Economy
     * - `"1"`: First Class
     * - `"2"`: Business Class
     * - `"3"`: Economy Class
     */
    public let compartment: String
    
    /**
     * Passenger's assigned seat number
     *
     * The specific seat assignment for the passenger on this flight.
     *
     * ## Format
     * - **Length**: 1-4 characters
     * - **Characters**: Alphanumeric (A-Z, 0-9)
     * - **Case**: Usually uppercase
     *
     * ## Examples
     * - `"14A"`: Row 14, Seat A (window seat on left side)
     * - `"32B"`: Row 32, Seat B (middle seat)
     * - `"15C"`: Row 15, Seat C (aisle seat on right side)
     * - `"1A"`: Row 1, Seat A (first row, window seat)
     * - `"25F"`: Row 25, Seat F (window seat on right side)
     *
     * ## Seat Layout
     * Seat letters typically follow this pattern:
     * - **A**: Left window seat
     * - **B**: Left middle seat
     * - **C**: Left aisle seat
     * - **D**: Right aisle seat
     * - **E**: Right middle seat
     * - **F**: Right window seat
     *
     * ## Note
     * Actual seat layout may vary by aircraft type and airline configuration.
     */
    public let seatno: String
    
    /**
     * Passenger's check-in sequence number
     *
     * A 5-digit number indicating the order in which the passenger
     * checked in for the flight.
     *
     * ## Format
     * - **Length**: Exactly 5 characters
     * - **Range**: 00001-99999
     * - **Type**: Integer
     *
     * ## Examples
     * - `"00033"`: 33rd passenger to check in
     * - `"00148"`: 148th passenger to check in
     * - `"00218"`: 218th passenger to check in
     *
     * ## Usage
     * - Used by airlines for operational purposes
     * - May indicate boarding priority in some cases
     * - Useful for tracking check-in patterns
     */
    public let checkIn: Int
    
    /**
     * Passenger's current status and special indicators
     *
     * A single character indicating the passenger's current status
     * and any special processing requirements.
     *
     * ## Common Values
     * - `"1"`: Confirmed passenger
     * - `"2"`: Standby passenger
     * - `"3"`: Waitlisted passenger
     * - `"4"`: No-show passenger
     * - `"5"`: Cancelled passenger
     * - `"6"`: Boarded passenger
     * - `"7"`: Checked-in passenger
     * - `"8"`: Pre-boarded passenger
     * - `"9"`: Priority passenger
     * - `"A"`: Special assistance required
     * - `"B"`: Unaccompanied minor
     * - `"C"`: Crew member
     * - `"I"`: Infant
     * - `"M"`: Military personnel
     * - `"P"`: Premium passenger
     * - `"S"`: Senior citizen
     * - `"V"`: VIP passenger
     * - `"W"`: Wheelchair required
     * - `"X"`: Special handling required
     * - `"Y"`: Youth passenger
     * - `"Z"`: Special category passenger
     */
    public let passengerStatus: String
    
    // MARK: - Structural Information
    
    /**
     * Size of conditional data section in hexadecimal
     *
     * Indicates the total length of the conditional data section
     * that follows the mandatory 60-character parent section.
     *
     * ## Format
     * - **Length**: Exactly 2 characters
     * - **Base**: Hexadecimal (0-9, A-F)
     * - **Case**: Usually uppercase
     *
     * ## Examples
     * - `"0033"`: 51 characters of conditional data (0x33 = 51 decimal)
     * - `"00A0"`: 160 characters of conditional data (0xA0 = 160 decimal)
     * - `"00F0"`: 240 characters of conditional data (0xF0 = 240 decimal)
     *
     * ## Usage
     * Used internally by the parser to determine the boundaries
     * of the conditional data section and to validate the overall
     * structure of the boarding pass.
     *
     * ## Note
     * This value is stored as an integer after conversion from
     * the hexadecimal string representation.
     */
    public let conditionalSize: Int
}
