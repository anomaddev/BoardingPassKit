//
//  BoardingPassMainSegment.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

// TODO: Handle last day of the year for issue date vs flight date

import Foundation

/**
 * Represents the main segment information for a boarding pass
 *
 * The `BoardingPassMainSegment` struct contains detailed information about the primary
 * flight segment, including passenger details, bag tags, airline information, and
 * frequent flyer data. This is the core segment that applies to the main leg of
 * the journey.
 *
 * ## Structure Overview
 * The main segment contains two main sections:
 * - **Passenger and Document Information**: Description, check-in source, pass source, dates
 * - **Airline and Baggage Information**: Bag tags, airline codes, ticket details, frequent flyer data
 *
 * ## Usage Example
 * ```swift
 * let boardingPass = try decoder.decode(code: barcodeString)
 * let mainSegment = boardingPass.main
 * 
 * // Access passenger information
 * print("Passenger Description: \(mainSegment.passengerDesc)")
 * print("Check-in Source: \(mainSegment.checkInSource)")
 * 
 * // Access bag tag information
 * if let bagTag1 = mainSegment.bagtag1 {
 *     print("Primary Bag Tag: \(bagTag1)")
 * }
 * 
 * // Access frequent flyer information
 * if let ffCarrier = mainSegment.ffCarrier, let ffNumber = mainSegment.ffNumber {
 *     print("Frequent Flyer: \(ffCarrier) \(ffNumber)")
 * }
 * ```
 *
 * ## IATA BCBP Field Mapping
 * The main segment corresponds to the conditional fields section of the IATA BCBP standard:
 * - **Characters 61-62**: Structure size (hex)
 * - **Characters 63+**: Variable-length conditional data
 * - **Bag Tags**: Up to 3 bag tag numbers (13 characters each)
 * - **Airline Data**: Airline codes, ticket numbers, frequent flyer information
 */
public struct BoardingPassMainSegment: Codable {
    
    // MARK: - Structure and Passenger Information
    
    /**
     * The size of the passenger information structure in hexadecimal
     *
     * Indicates the total length of passenger-related conditional fields.
     * Used internally by the parser to determine field boundaries.
     *
     * ## Format
     * Hexadecimal value representing the number of characters in the
     * passenger information section.
     */
    public let structSize: Int
    
    /**
     * Passenger description or type indicator
     *
     * Single character code indicating the type of passenger or
     * special passenger category.
     *
     * ## Common Values
     * - `"1"`: Adult passenger
     * - `"2"`: Child passenger
     * - `"3"`: Infant passenger
     * - `"C"`: Crew member
     * - `"I"`: Infant with seat
     */
    public let passengerDesc: String
    
    /**
     * Source of the check-in process
     *
     * Indicates where or how the passenger checked in for the flight.
     *
     * ## Common Values
     * - `"W"`: Web check-in
     * - `"K"`: Kiosk check-in
     * - `"C"`: Counter check-in
     * - `"M"`: Mobile check-in
     * - `"T"`: Transfer check-in
     */
    public let checkInSource: String
    
    /**
     * Source of the boarding pass
     *
     * Indicates where the boarding pass was issued or generated.
     *
     * ## Common Values
     * - `"W"`: Web boarding pass
     * - `"M"`: Mobile boarding pass
     * - `"P"`: Printed boarding pass
     * - `"K"`: Kiosk boarding pass
     * - `"C"`: Counter boarding pass
     */
    public let passSource: String
    
    /**
     * Date when the boarding pass was issued
     *
     * Contains the date information in a format that varies by airline.
     * Can be parsed using the computed properties `year` and `nthDay`.
     *
     * ## Format Variations
     * - **3 characters**: Julian day of year (e.g., "123" for May 3rd)
     * - **4 characters**: Year + Julian day (e.g., "3123" for 2023, day 123)
     * - **8 characters**: YYYYMMDD format (e.g., "20230503")
     */
    public let dateIssued: String
    
    /**
     * Type of travel document used
     *
     * Indicates the type of identification or travel document
     * associated with the boarding pass.
     *
     * ## Common Values
     * - `"B"`: Boarding pass
     * - `"T"`: Ticket
     * - `"P"`: Passport
     * - `"I"`: ID card
     * - `"V"`: Visa
     */
    public let documentType: String
    
    /**
     * Airline that issued the boarding pass
     *
     * The airline responsible for issuing the boarding pass, which may
     * be different from the operating carrier.
     *
     * ## Format
     * 3-character IATA airline code (e.g., "AA" for American Airlines)
     */
    public let passIssuer: String
    
    // MARK: - Bag Tag Information
    
    /**
     * Primary bag tag number
     *
     * The main bag tag number for the passenger's primary checked luggage.
     * May be empty if no bags are checked.
     *
     * ## Format
     * Up to 13 characters containing the bag tag identifier.
     * Format varies by airline but typically includes airline code and sequence number.
     */
    public var bagtag1: String?
    
    /**
     * Secondary bag tag number
     *
     * Additional bag tag for a second checked bag, if applicable.
     * Only present when the passenger has multiple checked bags.
     */
    public var bagtag2: String?
    
    /**
     * Tertiary bag tag number
     *
     * Third bag tag for a third checked bag, if applicable.
     * Rarely used, only for passengers with extensive luggage.
     */
    public var bagtag3: String?
    
    // MARK: - Airline and Ticket Information
    
    /**
     * Size of the airline information structure in hexadecimal
     *
     * Indicates the total length of airline-related conditional fields.
     * Used internally by the parser to determine field boundaries.
     */
    public let nextSize: Int
    
    /**
     * IATA code of the airline operating the flight
     *
     * The airline that actually operates the flight, which may be
     * different from the ticketing carrier.
     *
     * ## Format
     * 3-character IATA airline code (e.g., "AA", "DL", "UA")
     */
    public let airlineCode: String
    
    /**
     * Electronic ticket number
     *
     * The unique identifier for the electronic ticket associated
     * with this boarding pass.
     *
     * ## Format
     * Typically 10-13 digits, format varies by airline.
     * May include airline code prefix.
     */
    public let ticketNumber: String
    
    /**
     * Selectee indicator for security screening
     *
     * Indicates whether the passenger was selected for additional
     * security screening.
     *
     * ## Common Values
     * - `"S"`: Selected for screening
     * - `"N"`: Not selected
     * - `"P"`: Pre-check eligible
     * - `"T"`: TSA pre-check
     */
    public let selectee: String
    
    /**
     * International document verification indicator
     *
     * Indicates whether the passenger's travel documents have been
     * verified for international travel.
     *
     * ## Common Values
     * - `"I"`: International document verified
     * - `"D"`: Domestic travel only
     * - `"V"`: Visa verified
     * - `"P"`: Passport verified
     */
    public let internationalDoc: String
    
    /**
     * Operating carrier for the flight
     *
     * The airline that actually operates the aircraft, which may be
     * different from the marketing carrier.
     *
     * ## Format
     * 3-character IATA airline code
     */
    public let carrier: String
    
    /**
     * Frequent flyer program carrier
     *
     * The airline where the passenger's frequent flyer miles will
     * be credited, if different from the operating carrier.
     *
     * ## Usage
     * Used for code-share flights where the operating carrier is
     * different from the frequent flyer program carrier.
     */
    public var ffCarrier: String?
    
    /**
     * Frequent flyer membership number
     *
     * The passenger's frequent flyer membership number for the
     * specified frequent flyer program.
     *
     * ## Format
     * Varies by airline, typically 6-16 alphanumeric characters.
     * May include airline code prefix.
     */
    public var ffNumber: String?
    
    // MARK: - Additional Airline Information
    
    /**
     * ID indicator for additional identification
     *
     * Indicates whether additional identification documents are required
     * or have been presented.
     *
     * ## Common Values
     * - `"Y"`: Additional ID required/presented
     * - `"N"`: No additional ID required
     * - `"P"`: Passport required/presented
     * - `"V"`: Visa required/presented
     */
    public var IDADIndicator: String?
    
    /**
     * Free baggage allowance indicator
     *
     * Indicates the passenger's free baggage allowance or special
     * baggage privileges.
     *
     * ## Format
     * Typically 3 characters, format varies by airline.
     * May indicate number of free bags or special status.
     */
    public var freeBags: String?
    
    /**
     * Fast track security lane eligibility
     *
     * Indicates whether the passenger is eligible for expedited
     * security screening.
     *
     * ## Common Values
     * - `"Y"`: Fast track eligible
     * - `"N"`: Standard screening
     * - `"P"`: Priority screening
     * - `"T"`: TSA pre-check
     */
    public var fastTrack: String?
    
    /**
     * Airline-specific use field
     *
     * Reserved field for airline-specific information or special
     * processing requirements.
     *
     * ## Usage
     * Content and format vary by airline. May contain:
     * - Special service indicators
     * - Revenue management codes
     * - Operational notes
     * - Customer status information
     */
    public var airlineUse: String?
    
    // MARK: - Computed Properties
    
    /**
     * Julian year when the boarding pass was issued
     *
     * Extracts the year component from the `dateIssued` field.
     * Returns `nil` if the date format doesn't include year information.
     *
     * ## Parsing Logic
     * - **4-character format**: Extracts first character as year
     * - **3-character format**: Returns `nil` (no year information)
     * - **8-character format**: Returns `nil` (not yet implemented)
     *
     * ## Example
     * ```swift
     * if let year = mainSegment.year {
     *     print("Boarding pass issued in year: \(year)")
     * } else {
     *     print("Year information not available")
     * }
     * ```
     */
    public var year: Int? {
        guard dateIssued != "    " else { return nil}
        if dateIssued.count == 4 { return Int(String(dateIssued.first!)) }
        else { return nil }
    }
    
    /**
     * Julian day of the year when the boarding pass was issued
     *
     * Extracts the day component from the `dateIssued` field.
     * Returns `nil` if the date format is invalid or empty.
     *
     * ## Parsing Logic
     * - **3-character format**: Direct conversion to integer
     * - **4-character format**: Extracts last 3 characters as day
     * - **8-character format**: Returns `nil` (not yet implemented)
     *
     * ## Example
     * ```swift
     * if let day = mainSegment.nthDay {
     *     print("Boarding pass issued on day \(day) of the year")
     * } else {
     *     print("Day information not available")
     * }
     * ```
     *
     * ## Note
     * This property represents the day of the year (1-366), not the day of the month.
     * For example, day 32 would be February 1st in a non-leap year.
     */
    public var nthDay: Int? {
        guard dateIssued != "    " else { return nil}
        if dateIssued.count == 3 { return Int(dateIssued) }
        else { return Int(String(dateIssued.dropFirst())) }
    }
}
