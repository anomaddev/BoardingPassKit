//
//  BoardingPassSegment.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation

/**
 * Represents additional flight segments in a multi-leg journey
 *
 * The `BoardingPassSegment` struct contains information about additional flight
 * segments beyond the main segment, used for multi-leg journeys, connecting
 * flights, and complex itineraries. Each segment represents a separate flight
 * leg with its own routing, timing, and passenger information.
 *
 * ## Structure Overview
 * Additional segments contain similar information to the main segment but
 * are structured differently and may have different field requirements:
 * - **Flight Information**: Route, carrier, flight number, date
 * - **Passenger Details**: Seat assignment, check-in status, passenger status
 * - **Structural Information**: Segment size and conditional data
 * - **Airline Information**: Codes, ticket details, frequent flyer data
 *
 * ## Usage Example
 * ```swift
 * let boardingPass = try decoder.decode(code: barcodeString)
 * 
 * // Check if this is a multi-segment journey
 * if boardingPass.segments.count > 0 {
 *     print("Multi-leg journey with \(boardingPass.segments.count) additional segments")
 *     
 *     // Process each additional segment
 *     for (index, segment) in boardingPass.segments.enumerated() {
 *         print("Segment \(index + 2): \(segment.origin) → \(segment.destination)")
 *         print("  Flight: \(segment.carrier) \(segment.flightno)")
 *         print("  Date: \(segment.julianDate)")
 *         
 *         if let seat = segment.seatno {
 *             print("  Seat: \(seat)")
 *         }
 *     }
 * } else {
 *     print("Direct flight - no additional segments")
 * }
 * ```
 *
 * ## IATA BCBP Segment Structure
 * Additional segments follow the main segment and contain:
 * - **PNR and Route**: PNR code, origin, destination
 * - **Flight Details**: Carrier, flight number, date
 * - **Passenger Info**: Compartment, seat, check-in status
 * - **Structural Data**: Segment size and conditional fields
 * - **Airline Data**: Codes, ticket info, frequent flyer details
 *
 * ## Multi-Segment Journey Types
 * - **Connecting Flights**: TPA → ATL → DFW (2 segments)
 * - **Multi-Stop Journeys**: TPA → ATL → ORD → DFW (3 segments)
 * - **Round-Trip**: TPA → DFW → TPA (2 segments)
 * - **Complex Itineraries**: Multiple connections and stops
 *
 * ## Field Differences from Main Segment
 * Additional segments have some key differences:
 * - **Seat Assignment**: May be optional or different format
 * - **Check-in Status**: May indicate different check-in requirements
 * - **Conditional Fields**: May have different structure or content
 * - **Airline Data**: May include different frequent flyer information
 */
public struct BoardingPassSegment: Codable {
    
    // MARK: - Flight Information
    
    /**
     * Passenger Name Record (PNR) code for this segment
     *
     * The PNR code associated with this specific flight segment.
     * May be the same as the main segment PNR or different if
     * the segments were booked separately.
     *
     * ## Format
     * - **Length**: Exactly 7 characters
     * - **Characters**: Alphanumeric (A-Z, 0-9)
     * - **Case**: Usually uppercase
     *
     * ## Usage
     * Used to link this segment to the passenger's booking record
     * and to retrieve segment-specific information.
     */
    public let pnrCode: String
    
    /**
     * IATA code of the origin airport for this segment
     *
     * The 3-letter IATA airport code for the departure airport
     * of this specific flight segment.
     *
     * ## Format
     * - **Length**: Exactly 3 characters
     * - **Characters**: Uppercase letters only
     * - **Standard**: IATA airport code standard
     *
     * ## Examples
     * - `"ATL"`: Hartsfield-Jackson Atlanta International Airport
     * - `"ORD"`: Chicago O'Hare International Airport
     * - `"LAX"`: Los Angeles International Airport
     * - `"JFK"`: John F. Kennedy International Airport
     */
    public let origin: String
    
    /**
     * IATA code of the destination airport for this segment
     *
     * The 3-letter IATA airport code for the arrival airport
     * of this specific flight segment.
     *
     * ## Format
     * - **Length**: Exactly 3 characters
     * - **Characters**: Uppercase letters only
     * - **Standard**: IATA airport code standard
     *
     * ## Examples
     * - `"DFW"`: Dallas/Fort Worth International Airport
     * - `"SFO"`: San Francisco International Airport
     * - `"MIA"`: Miami International Airport
     * - `"BOS"`: Boston Logan International Airport
     */
    public let destination: String
    
    /**
     * IATA code of the airline operating this segment
     *
     * The 3-letter IATA airline code for the carrier that operates
     * the aircraft for this specific flight segment.
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
     *
     * ## Note
     * This may be different from the main segment carrier, especially
     * for code-share flights or complex itineraries.
     */
    public let carrier: String
    
    /**
     * Flight number for this segment
     *
     * The unique flight identifier assigned by the airline for this
     * specific flight segment.
     *
     * ## Format
     * - **Length**: 1-5 characters
     * - **Characters**: Alphanumeric (A-Z, 0-9)
     * - **Case**: Usually uppercase
     *
     * ## Examples
     * - `"1234"`: Flight 1234
     * - `"AA567"`: American Airlines flight AA567
     * - `"DL890"`: Delta Air Lines flight DL890
     * - `"UA123"`: United Airlines flight UA123
     */
    public let flightno: String
    
    /**
     * Julian date of this segment's departure
     *
     * The day of the year when this flight segment departs,
     * expressed as a 3-digit number from 1 to 366.
     *
     * ## Format
     * - **Length**: Exactly 3 characters
     * - **Range**: 001-366 (001 = January 1st, 366 = December 31st in leap years)
     * - **Type**: Integer
     *
     * ## Examples
     * - `"136"`: Day 136 of the year (May 16th in non-leap years)
     * - `"185"`: Day 185 of the year (July 4th in non-leap years)
     * - `"213"`: Day 213 of the year (August 1st in non-leap years)
     * - `"365"`: Day 365 of the year (December 31st in non-leap years)
     *
     * ## Note
     * This may be the same as the main segment date for same-day
     * connections or different for multi-day journeys.
     */
    public let julianDate: Int
    
    // MARK: - Passenger Information
    
    /**
     * Compartment code for this segment
     *
     * A single character indicating the cabin class or compartment
     * where the passenger is seated on this flight segment.
     *
     * ## Format
     * - **Length**: Exactly 1 character
     * - **Characters**: Single uppercase letter
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
     *
     * ## Note
     * The cabin class may be different from the main segment,
     * especially for upgrades, downgrades, or mixed-class itineraries.
     */
    public let compartment: String
    
    /**
     * Passenger's assigned seat number for this segment
     *
     * The specific seat assignment for the passenger on this
     * flight segment. May be optional or different from the main segment.
     *
     * ## Format
     * - **Length**: 1-4 characters (when present)
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
     * ## Note
     * This field is optional and may be `nil` if:
     * - Seat assignment is pending
     * - Seat is assigned at the gate
     * - Segment is standby or waitlisted
     * - Seat information is not available
     */
    public var seatno: String?
    
    /**
     * Check-in sequence number for this segment
     *
     * A 5-digit number indicating the order in which the passenger
     * checked in for this specific flight segment.
     *
     * ## Format
     * - **Length**: Exactly 5 characters
     * - **Range**: 00001-99999
     * - **Type**: Integer
     *
     * ## Examples
     * - `"00148"`: 148th passenger to check in for this segment
     * - `"00218"`: 218th passenger to check in for this segment
     * - `"00001"`: 1st passenger to check in for this segment
     *
     * ## Usage
     * Used by airlines for operational purposes and may indicate
     * boarding priority for this specific segment.
     */
    public var checkedin: Int
    
    /**
     * Passenger status for this segment
     *
     * A single character indicating the passenger's current status
     * and any special processing requirements for this segment.
     *
     * ## Format
     * - **Length**: Exactly 1 character
     * - **Characters**: Single character code
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
     *
     * ## Note
     * Status may be different from the main segment, especially
     * for standby segments or segments with different requirements.
     */
    public var passengerStatus: String
    
    // MARK: - Structural Information
    
    /**
     * Size of this segment's conditional data in hexadecimal
     *
     * Indicates the total length of the conditional data section
     * for this specific segment.
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
     * of this segment's conditional data section.
     */
    public var structSize: Int
    
    /**
     * Size of this segment's airline data in hexadecimal
     *
     * Indicates the total length of the airline-specific data section
     * for this segment.
     *
     * ## Format
     * - **Length**: Exactly 2 characters
     * - **Base**: Hexadecimal (0-9, A-F)
     * - **Case**: Usually uppercase
     *
     * ## Usage
     * Used internally by the parser to determine the boundaries
     * of this segment's airline data section.
     */
    public let segmentSize: Int
    
    // MARK: - Airline and Ticket Information
    
    /**
     * IATA code of the airline for this segment
     *
     * The 3-letter IATA airline code for this specific segment.
     * May be different from the main segment airline.
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
     */
    public var airlineCode: String
    
    /**
     * Electronic ticket number for this segment
     *
     * The unique identifier for the electronic ticket associated
     * with this specific flight segment.
     *
     * ## Format
     * - **Length**: 10-13 characters
     * - **Characters**: Numeric digits
     * - **Format**: Varies by airline
     *
     * ## Examples
     * - `"1234567890"`: 10-digit ticket number
     * - `"1234567890123"`: 13-digit ticket number
     *
     * ## Note
     * May be the same as the main segment ticket number or different
     * if segments were booked separately or involve different carriers.
     */
    public var ticketNumber: String
    
    /**
     * Selectee indicator for this segment
     *
     * Indicates whether the passenger was selected for additional
     * security screening for this specific segment.
     *
     * ## Format
     * - **Length**: Exactly 1 character
     * - **Characters**: Single character code
     *
     * ## Common Values
     * - `"S"`: Selected for screening
     * - `"N"`: Not selected
     * - `"P"`: Pre-check eligible
     * - `"T"`: TSA pre-check
     *
     * ## Note
     * Security screening status may vary by segment, especially
     * for international connections or different security protocols.
     */
    public var selectee: String
    
    /**
     * International document verification for this segment
     *
     * Indicates whether the passenger's travel documents have been
     * verified for international travel on this segment.
     *
     * ## Format
     * - **Length**: Exactly 1 character
     * - **Characters**: Single character code
     *
     * ## Common Values
     * - `"I"`: International document verified
     * - `"D"`: Domestic travel only
     * - `"V"`: Visa verified
     * - `"P"`: Passport verified
     *
     * ## Note
     * Document verification requirements may vary by segment,
     * especially for mixed domestic/international itineraries.
     */
    public var internationalDoc: String
    
    /**
     * Operating carrier for this segment
     *
     * The airline that actually operates the aircraft for this
     * specific flight segment.
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
     *
     * ## Note
     * This is the operating carrier, which may be different from
     * the marketing carrier or the airline that issued the ticket.
     */
    public var ticketingCarrier: String
    
    /**
     * Frequent flyer program carrier for this segment
     *
     * The airline where the passenger's frequent flyer miles will
     * be credited for this specific segment.
     *
     * ## Format
     * - **Length**: Exactly 3 characters
     * - **Characters**: Uppercase letters only
     * - **Standard**: IATA airline code standard
     *
     * ## Usage
     * Used for code-share flights where the operating carrier is
     * different from the frequent flyer program carrier.
     */
    public var ffAirline: String
    
    /**
     * Frequent flyer membership number for this segment
     *
     * The passenger's frequent flyer membership number for the
     * specified frequent flyer program on this segment.
     *
     * ## Format
     * - **Length**: 6-16 characters
     * - **Characters**: Alphanumeric (A-Z, 0-9)
     * - **Format**: Varies by airline
     *
     * ## Examples
     * - `"123456"`: 6-digit membership number
     * - `"ABC123456789"`: 12-character membership number
     *
     * ## Note
     * May be the same as the main segment frequent flyer number
     * or different if using different programs for different segments.
     */
    public var ffNumber: String
    
    // MARK: - Additional Airline Information
    
    /**
     * ID indicator for additional identification on this segment
     *
     * Indicates whether additional identification documents are required
     * or have been presented for this specific segment.
     *
     * ## Format
     * - **Length**: 1 character (when present)
     * - **Characters**: Single character code
     *
     * ## Common Values
     * - `"Y"`: Additional ID required/presented
     * - `"N"`: No additional ID required
     * - `"P"`: Passport required/presented
     * - `"V"`: Visa required/presented
     *
     * ## Note
     * This field is optional and may be `nil` if no additional
     * identification is required for this segment.
     */
    public var idAdIndicator: String?
    
    /**
     * Free baggage allowance indicator for this segment
     *
     * Indicates the passenger's free baggage allowance or special
     * baggage privileges for this specific segment.
     *
     * ## Format
     * - **Length**: 3 characters (when present)
     * - **Characters**: Alphanumeric
     * - **Format**: Varies by airline
     *
     * ## Note
     * This field is optional and may be `nil` if no special
     * baggage allowance applies to this segment.
     */
    public var freeBags: String?
    
    /**
     * Fast track security lane eligibility for this segment
     *
     * Indicates whether the passenger is eligible for expedited
     * security screening for this specific segment.
     *
     * ## Format
     * - **Length**: 1 character (when present)
     * - **Characters**: Single character code
     *
     * ## Common Values
     * - `"Y"`: Fast track eligible
     * - `"N"`: Standard screening
     * - `"P"`: Priority screening
     * - `"T"`: TSA pre-check
     *
     * ## Note
     * This field is optional and may be `nil` if no special
     * screening privileges apply to this segment.
     */
    public var fastTrack: String?
    
    /**
     * Airline-specific use field for this segment
     *
     * Reserved field for airline-specific information or special
     * processing requirements for this segment.
     *
     * ## Format
     * - **Length**: Variable (when present)
     * - **Characters**: Varies by airline
     * - **Content**: Airline-specific information
     *
     * ## Usage
     * Content and format vary by airline. May contain:
     * - Special service indicators
     * - Revenue management codes
     * - Operational notes
     * - Customer status information
     * - Segment-specific requirements
     *
     * ## Note
     * This field is optional and may be `nil` if no airline-specific
     * information is required for this segment.
     */
    public var airlineUse: String?
}
