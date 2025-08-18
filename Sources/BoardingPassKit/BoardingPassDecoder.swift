//
//  BoardingPassDecoder.swift
//  
//
//  Created by Justin Ackermann on 7/7/23.
//

import Foundation

/**
 * Decodes IATA boarding pass barcodes into structured data
 *
 * The `BoardingPassDecoder` class is responsible for parsing raw boarding pass barcode data
 * (either as Data or String) and converting it into a structured `BoardingPass` object.
 * It handles the complex parsing logic required for IATA BCBP (Boarding Pass Bar Code) format.
 *
 * ## Key Features
 * - **Data Format Support**: Handles both Data and String input formats
 * - **Validation Integration**: Built-in validation before parsing (configurable)
 * - **Debug Support**: Comprehensive debugging output for development
 * - **Error Handling**: Detailed error reporting with specific failure reasons
 * - **Flexible Parsing**: Supports single and multi-segment boarding passes
 *
 * ## Usage Example
 * ```swift
 * let decoder = BoardingPassDecoder()
 * decoder.debug = true  // Enable debug output
 * decoder.validationEnabled = true  // Enable validation
 * 
 * do {
 *     // Decode from string
 *     let boardingPass = try decoder.decode(code: barcodeString)
 *     print("Passenger: \(boardingPass.info.name)")
 *     print("Flight: \(boardingPass.info.operatingCarrier) \(boardingPass.info.flightno)")
 *     
 *     // Decode from Data
 *     let barcodeData = barcodeString.data(using: .ascii)!
 *     let boardingPass2 = try decoder.decode(barcodeData)
 * } catch BoardingPassError.InvalidPassFormat(let format) {
 *     print("Invalid format: \(format)")
 * } catch {
 *     print("Decoding failed: \(error)")
 * }
 * ```
 *
 * ## IATA BCBP Parsing Process
 * The decoder follows the IATA BCBP standard parsing sequence:
 * 1. **Mandatory Fields** (60 characters): Format, passenger info, flight details
 * 2. **Conditional Fields** (variable length): Additional flight and passenger data
 * 3. **Segment Data** (if multi-leg): Additional flight segments
 * 4. **Security Data**: Airline-specific validation codes
 *
 * ## Configuration Options
 * - `debug`: Enable detailed console output for development
 * - `trimLeadingZeroes`: Remove unnecessary leading zeros from numeric fields
 * - `trimWhitespace`: Remove whitespace from field values
 * - `validationEnabled`: Enable pre-parsing validation (recommended)
 *
 * ## Error Handling
 * The decoder throws `BoardingPassError` types for various failure scenarios:
 * - Format validation errors
 * - Data corruption errors
 * - Parsing structure errors
 * - Field value errors
 */
open class BoardingPassDecoder: NSObject {
    
    // MARK: - Configuration Properties
    
    /**
     * Enables detailed debug output to console
     *
     * When set to `true`, the decoder will print detailed information about
     * each parsing step, including field values and conditional field processing.
     * Useful for development and debugging parsing issues.
     *
     * ## Debug Output Includes
     * - Mandatory field values and positions
     * - Conditional field processing
     * - Sub-conditional field calculations
     * - Parsing progress and validation results
     */
    public var debug: Bool = false
    
    /**
     * Automatically removes leading zeros from numeric fields
     *
     * When enabled, fields like flight numbers and seat numbers will have
     * leading zeros removed for cleaner output. For example, "00123" becomes "123".
     *
     * ## Affected Fields
     * - Flight numbers
     * - Seat numbers
     * - Other numeric identifiers
     *
     * ## Default Value
     * `true` - Leading zeros are removed by default
     */
    public var trimLeadingZeroes: Bool = true
    
    /**
     * Automatically removes whitespace from field values
     *
     * When enabled, all field values will have leading and trailing whitespace
     * removed. This ensures consistent, clean data output.
     *
     * ## Affected Fields
     * - Passenger names
     * - Airport codes
     * - PNR codes
     * - All other text fields
     *
     * ## Default Value
     * `true` - Whitespace is trimmed by default
     */
    public var trimWhitespace: Bool = true
    
    /**
     * Enables pre-parsing validation of boarding pass data
     *
     * When enabled, the decoder will validate the boarding pass data structure
     * and format before attempting to parse it. This helps catch errors early
     * and provides better error messages.
     *
     * ## Validation Checks
     * - Format code validation (M/S)
     * - Segment count validation
     * - Field length requirements
     * - Character encoding validation
     *
     * ## Default Value
     * `true` - Validation is enabled by default (recommended)
     */
    public var validationEnabled: Bool = true
    
    // MARK: - Internal State
    
    /**
     * Current parsing position in the boarding pass data
     *
     * Tracks the current byte/character position during parsing.
     * Used internally to ensure proper field extraction and positioning.
     */
    private var index: Int = 0
    
    /**
     * Sub-conditional field counter for complex parsing
     *
     * Tracks the remaining length of sub-conditional fields during parsing.
     * Used for handling nested conditional field structures.
     */
    private var subConditional: Int = 0
    
    /**
     * End conditional field counter for parsing boundaries
     *
     * Tracks the remaining length of conditional fields during parsing.
     * Used to determine when conditional field processing is complete.
     */
    private var endConditional: Int = 0
    
    // MARK: - Parsed Data
    
    /**
     * Raw boarding pass data as Data object
     *
     * Contains the original boarding pass barcode data in binary format.
     * Used internally for parsing and field extraction.
     */
    public var data: Data!
    
    /**
     * Raw boarding pass data as String
     *
     * Contains the original boarding pass barcode data as an ASCII string.
     * Used internally for parsing and field extraction.
     */
    public var code: String!
    
    // MARK: - Core Decoding Methods
    
    /**
     * Converts raw Data to ASCII string for parsing
     *
     * Internal method that converts the binary boarding pass data to an
     * ASCII string representation for parsing.
     *
     * - Parameter data: The raw boarding pass data
     * - Returns: ASCII string representation of the data
     * - Throws: `BoardingPassError.DataFailedStringDecoding` if conversion fails
     *
     * ## Usage
     * This method is called internally by the decode methods to prepare
     * the data for parsing. It ensures proper ASCII encoding.
     */
    private func raw(_ data: Data) throws -> String {
        guard let str = String(data: data,
                               encoding: String.Encoding.ascii)
        else { throw BoardingPassError.DataFailedStringDecoding }
        return str
    }
    
    /**
     * Decodes boarding pass data from Data object
     *
     * Parses a boarding pass barcode from raw binary data and returns
     * a structured `BoardingPass` object.
     *
     * - Parameter data: The boarding pass barcode data
     * - Returns: A fully parsed `BoardingPass` object
     * - Throws: `BoardingPassError` if parsing or validation fails
     *
     * ## Parsing Process
     * 1. Converts Data to ASCII string
     * 2. Validates data structure (if validation enabled)
     * 3. Parses mandatory fields (60 characters)
     * 4. Parses conditional fields (variable length)
     * 5. Parses segment data (if multi-leg)
     * 6. Parses security data
     *
     * ## Usage Example
     * ```swift
     * let decoder = BoardingPassDecoder()
     * let barcodeData = barcodeString.data(using: .ascii)!
     * 
     * do {
     *     let boardingPass = try decoder.decode(barcodeData)
     *     print("Successfully decoded boarding pass for \(boardingPass.info.name)")
     * } catch {
     *     print("Failed to decode: \(error)")
     * }
     * ```
     */
    public func decode(_ data: Data) throws -> BoardingPass {
        self.data = data
        self.code = try raw(data)
        
        // Validate before parsing if enabled
        if validationEnabled {
            try BoardingPassValidator.validateAndThrow(code)
        }
        
        return try breakdown()
    }
    
    /**
     * Decodes boarding pass data from String
     *
     * Parses a boarding pass barcode from a string representation and returns
     * a structured `BoardingPass` object.
     *
     * - Parameter code: The boarding pass barcode string
     * - Returns: A fully parsed `BoardingPass` object
     * - Throws: `BoardingPassError` if parsing or validation fails
     *
     * ## Parsing Process
     * 1. Converts string to Data for internal processing
     * 2. Validates data structure (if validation enabled)
     * 3. Parses all boarding pass fields
     * 4. Returns structured boarding pass object
     *
     * ## Usage Example
     * ```swift
     * let decoder = BoardingPassDecoder()
     * let barcodeString = "M1ACKERMANN/JUSTIN    ETDPUPK TPADFWAA..."
     * 
     * do {
     *     let boardingPass = try decoder.decode(code: barcodeString)
     *     print("Flight: \(boardingPass.info.origin) → \(boardingPass.info.destination)")
     * } catch BoardingPassError.InvalidPassFormat(let format) {
     *     print("Invalid format code: \(format)")
     * } catch {
     *     print("Decoding failed: \(error)")
     * }
     * ```
     */
    public func decode(code: String) throws -> BoardingPass {
        self.data = code.data(using: .ascii)
        self.code = code
        
        // Validate before parsing if enabled
        if validationEnabled {
            try BoardingPassValidator.validateAndThrow(code)
        }
        
        return try breakdown()
    }
    
    // MARK: - Core Parsing Logic
    
    /**
     * Main parsing method that orchestrates the entire decoding process
     *
     * This is the core method that coordinates all parsing steps to create
     * a complete `BoardingPass` object from the raw barcode data.
     *
     * - Returns: A fully parsed `BoardingPass` object
     * - Throws: `BoardingPassError` if any parsing step fails
     *
     * ## Parsing Sequence
     * 1. **Parent Information**: Format, passenger details, flight basics
     * 2. **Version**: Boarding pass format version
     * 3. **Main Segment**: Primary flight segment details
     * 4. **Additional Segments**: Multi-leg flight information
     * 5. **Security Data**: Airline validation and security codes
     *
     * ## Internal State Management
     * - Resets parsing indices
     * - Manages conditional field boundaries
     * - Handles multi-segment parsing
     * - Validates final data integrity
     */
    private func breakdown() throws -> BoardingPass {
        index = 0
        subConditional = 0
        endConditional = 0
    
        let info        = try parent()
        endConditional  = info.conditionalSize
        
        if debug
        { print("Conditional Size: \(info.conditionalSize)") }
        
        let _           = try conditional(1)
        let version     = try conditional(1)
        
        var main: BoardingPassMainSegment!
        var segments: [BoardingPassSegment] = []
        
        for i in 0...(info.legs) {
            if i == 0 { main = try mainSegment() }
            else if i != info.legs { segments.append(try segment()) }
        }
        
        let beginSecurity = try? mandatory(1)
        var typeSecurity: String!
        var lengthSecurity: Int!
        var data: String!
        
        if beginSecurity == ">" {
            typeSecurity = try mandatory(1)
            lengthSecurity = try readhex(2, isMandatory: true)
            
            subConditional = lengthSecurity
            data = try conditional(lengthSecurity)
        } else {
            subConditional = code.count - index
            data = try conditional(subConditional)
        }
        
        guard subConditional == 0
        else { throw NSError() }
        
        let securityData = BoardingPassSecurityData(
            beginSecurity: beginSecurity,
            securityType: typeSecurity,
            securitylength: lengthSecurity,
            securityData: data
        )
        
        print("parsed boarding pass...")
        let pass = BoardingPass(
            version: version,
            info: info,
            main: main,
            segments: segments,
            security: securityData,
            code: code
        )
        
        print("======================")
        print("Boarding Pass:")
        print(pass.code)
        print("======================")
        if debug { pass.printout() }
        return pass
    }
    
    // MARK: - Field Parsing Methods
    
    /**
     * Extracts mandatory fields from the boarding pass data
     *
     * Mandatory fields are the core 60 characters that must be present
     * in every boarding pass. These fields contain essential flight information.
     *
     * - Parameter length: The length of the field to extract
     * - Returns: The extracted field value as a string
     * - Throws: `BoardingPassError.MandatoryItemNotFound` if field is missing
     *
     * ## Mandatory Fields Include
     * - Format code (1 character)
     * - Number of legs (1 character)
     * - Passenger name (20 characters)
     * - Ticket indicator (1 character)
     * - PNR code (7 characters)
     * - Origin airport (3 characters)
     * - Destination airport (3 characters)
     * - Operating carrier (3 characters)
     * - Flight number (5 characters)
     * - Julian date (3 characters)
     * - Compartment code (1 character)
     * - Seat number (4 characters)
     * - Check-in sequence (5 characters)
     * - Passenger status (1 character)
     * - Conditional size (2 hex characters)
     *
     * ## Processing
     * - Extracts data at current parsing position
     * - Advances parsing index
     * - Applies whitespace trimming if enabled
     * - Logs debug information if debug mode is enabled
     */
    private func mandatory(_ length: Int) throws -> String {
        if (data.count < index + length)
        { throw BoardingPassError.MandatoryItemNotFound(index: index) }
        
        var string: String = try readdata(length)
        if debug { print("MANDATORY: " + string) }
        
        if trimWhitespace { string = string.trimmingCharacters(in: .whitespaces) }
        
        return string
    }
    
    /**
     * Extracts conditional fields from the boarding pass data
     *
     * Conditional fields contain additional information that may vary in length
     * and content depending on the boarding pass type and airline.
     *
     * - Parameter length: The length of the field to extract
     * - Returns: The extracted field value as a string
     * - Throws: `BoardingPassError.ConditionalIndexInvalid` if structure is invalid
     *
     * ## Conditional Fields Include
     * - Boarding pass version
     * - Passenger description
     * - Check-in source
     * - Pass source
     * - Date issued
     * - Document type
     * - Airline designation
     * - Bag tag information
     * - Airline-specific data
     *
     * ## Processing
     * - Tracks remaining conditional field length
     * - Updates sub-conditional counters
     * - Applies whitespace trimming if enabled
     * - Logs debug information if debug mode is enabled
     */
    private func conditional(_ length: Int) throws -> String {
        if (data.count < index + length) &&
           (endConditional > 0)
        { throw BoardingPassError.ConditionalIndexInvalid(endConditional, subConditional) }
        
        if subConditional != 0
        { subConditional -= length }
        
        if endConditional != 0
        { endConditional -= length }
        
        var string: String = try readdata(length)
        if debug {
            print("CONDITIONAL: " + string)
            print("SUB-CONDITIONAL: \(subConditional)")
            print("END CONDITIONAL: \(endConditional)")
        }
        
        if trimWhitespace { string = string.trimmingCharacters(in: .whitespaces) }
        
        return string
    }
    
    /**
     * Extracts and converts integer fields from the boarding pass data
     *
     * Converts string field values to integers, useful for numeric fields
     * like check-in sequence numbers and segment counts.
     *
     * - Parameter length: The length of the field to extract
     * - Returns: The extracted field value as an integer
     * - Throws: `BoardingPassError.FieldValueNotRequiredInteger` if conversion fails
     *
     * ## Usage
     * Used for fields that should contain numeric values:
     * - Number of legs
     * - Julian date
     * - Check-in sequence
     * - Segment sizes
     *
     * ## Processing
     * - Extracts string value using mandatory parsing
     * - Trims whitespace
     * - Converts to integer
     * - Logs debug information if debug mode is enabled
     */
    private func readint(_ length: Int) throws -> Int {
        let rawString = try mandatory(length)
        if debug { print("RAW INT: \(rawString)") }
        
        guard let number = Int(rawString.trimmingCharacters(in: .whitespaces))
        else { throw BoardingPassError.FieldValueNotRequiredInteger(value: rawString) }
        
        return number
    }
    
    /**
     * Extracts raw data from the boarding pass at the current position
     *
     * Low-level method that extracts raw bytes from the data and converts
     * them to a string. This is the foundation for all field extraction.
     *
     * - Parameter length: The length of data to extract
     * - Returns: The extracted data as a string
     * - Throws: `BoardingPassError.DataFailedStringDecoding` if conversion fails
     *
     * ## Processing
     * - Extracts raw bytes from current position
     * - Advances parsing index
     * - Converts bytes to ASCII string
     * - Handles encoding errors gracefully
     */
    private func readdata(_ length: Int) throws -> String {
        let subdata = data.subdata(in: index ..< (index + length))
        index += length
        
        guard let rawString = String(data: subdata, encoding: String.Encoding.ascii)
        else { throw BoardingPassError.DataFailedStringDecoding }
        return rawString
    }
    
    /**
     * Extracts and converts hexadecimal fields from the boarding pass data
     *
     * Converts hexadecimal string values to integers, used for fields that
     * contain hex-encoded size information.
     *
     * - Parameters:
     *   - length: The length of the hex field to extract
     *   - isMandatory: Whether to use mandatory or conditional parsing
     * - Returns: The extracted field value as an integer
     * - Throws: `BoardingPassError.HexStringFailedDecoding` if conversion fails
     *
     * ## Usage
     * Used for fields that contain hexadecimal values:
     * - Conditional field sizes
     * - Segment structure sizes
     * - Security data lengths
     *
     * ## Processing
     * - Extracts string value using appropriate parsing method
     * - Converts hex string to integer
     * - Logs debug information if debug mode is enabled
     */
    private func readhex(_ length: Int, isMandatory: Bool! = true) throws -> Int {
        let str: String!
        
        if isMandatory { str = try mandatory(length) }
        else { str = try conditional(length) }
        
        guard let int = Int(str, radix: 16)
        else { throw BoardingPassError.HexStringFailedDecoding(string: str) }
        
        if debug { print("HEX: \(int)") }
        return int
    }
    
    // MARK: - Structure Parsing Methods
    
    /**
     * Parses the parent information section of the boarding pass
     *
     * Extracts the core mandatory fields that apply to the entire boarding pass,
     * including passenger details and primary flight information.
     *
     * - Returns: A `BoardingPassParent` object with parsed information
     * - Throws: `BoardingPassError` if parsing fails or data is invalid
     *
     * ## Parsed Fields
     * - Format code (M/S)
     * - Number of legs
     * - Passenger name
     * - Ticket indicator
     * - PNR code
     * - Origin and destination airports
     * - Operating carrier and flight number
     * - Julian date
     * - Compartment and seat information
     * - Check-in sequence and passenger status
     * - Conditional data size
     *
     * ## Validation
     * - Ensures format code is valid (M or S)
     * - Validates segment count is greater than 0
     * - Applies leading zero trimming if enabled
     */
    private func parent() throws -> BoardingPassParent {
        do {
            let format          = try mandatory(1)
            let legs            = try readint(1)
            let name            = try mandatory(20)
            let ticketIndicator = try mandatory(1)
            let pnrCode         = try mandatory(7)
            let origin          = try mandatory(3)
            let destination     = try mandatory(3)
            let opCarrier       = try mandatory(3)
            var flightno        = try mandatory(5)
            let julianDate      = try readint(3)
            let compartment     = try mandatory(1)
            var seatno          = try mandatory(4)
            
            guard format == "M" || format == "S"
            else { throw BoardingPassError.InvalidPassFormat(format: format) }
            
            guard legs > 0
            else { throw BoardingPassError.InvalidSegments(legs: legs) }
            
            // TODO: Add more validation
            
            if trimLeadingZeroes {
                flightno = flightno.removeLeadingZeros()
                seatno = seatno.removeLeadingZeros()
            }
            
            return BoardingPassParent(
                format:             format,
                legs:               legs,
                name:               name,
                ticketIndicator:    ticketIndicator,
                pnrCode:            pnrCode,
                origin:             origin,
                destination:        destination,
                operatingCarrier:   opCarrier,
                flightno:           flightno,
                julianDate:         julianDate,
                compartment:        compartment,
                seatno:             seatno,
                checkIn:            try readint(5),
                passengerStatus:    try mandatory(1),
                conditionalSize:    try readhex(2)
            )
        } catch { throw BoardingPassError.DataIsNotBoardingPass(error: error) }
    }
    
    /**
     * Parses the main segment section of the boarding pass
     *
     * Extracts detailed information about the primary flight segment,
     * including bag tags, airline codes, and passenger-specific data.
     *
     * - Returns: A `BoardingPassMainSegment` object with parsed information
     * - Throws: `BoardingPassError` if parsing fails or structure is invalid
     *
     * ## Parsed Fields
     * - Passenger description and check-in source
     * - Pass source and date issued
     * - Document type and airline designation
     * - Bag tag information (up to 3 tags)
     * - Airline code and ticket number
     * - Selectee and international document indicators
     * - Operating carrier and frequent flyer information
     * - ID indicators and airline-specific data
     *
     * ## Structure Handling
     * - Manages conditional field boundaries
     * - Handles variable-length bag tag fields
     * - Processes airline-specific conditional data
     * - Validates field structure integrity
     */
    private func mainSegment() throws -> BoardingPassMainSegment {
        let passStruct  = try readhex(2, isMandatory: false)
        subConditional  = passStruct
        
        let desc        = try conditional(1)
        let sourceCheck = try conditional(1)
        let sourcePass  = try conditional(1)
        let dateIssued  = try conditional(4)
        let docType     = try conditional(1)
        let airDesig    = try conditional(3)
        let bagtag      = try conditional(13)
        var bagtag2: String?
        var bagtag3: String?
        
        if subConditional > 0 {
            let tags = subConditional / 13
            for i in 0...tags {
                if i == 0 { bagtag2 = try conditional(13) }
                else if i == 1 { bagtag3 = try conditional(13) }
            }
        }
        
        guard subConditional == 0
        else { throw BoardingPassError.MainSegmentBagConditionalInvalid }
        
        let airStruct   = try readhex(2, isMandatory: false)
        subConditional  = airStruct
        
        let airlinecode = try conditional(3)
        let docnumber   = try conditional(10)
        let selectee    = try conditional(1)
        let docVerify   = try conditional(1)
        let opCarrier   = try conditional(3)
        let ffAirline   = try conditional(3)
        let ffNumber    = try conditional(16)
        
        var idIndicator: String?
        if subConditional > 0
        { idIndicator = try conditional(1) }
        
        var freeBags: String?
        if subConditional > 0
        { freeBags    = try conditional(3) }
        
        var fastTrack: String?
        if subConditional > 0
        { fastTrack   = try conditional(1) }
        
        var airlineUse: String?
        if subConditional >= 0 && endConditional > 0
        { airlineUse = try conditional(endConditional) }
        
        guard subConditional == 0 && endConditional == 0
        else { throw BoardingPassError.MainSegmentSubConditionalInvalid }
        
        return BoardingPassMainSegment(
            structSize: passStruct,
            passengerDesc: desc,
            checkInSource: sourceCheck,
            passSource: sourcePass,
            dateIssued: dateIssued,
            documentType: docType,
            passIssuer: airDesig,
            bagtag1: bagtag,
            bagtag2: bagtag2,
            bagtag3: bagtag3,
            nextSize: airStruct,
            airlineCode: airlinecode,
            ticketNumber: docnumber,
            selectee: selectee,
            internationalDoc: docVerify,
            carrier: opCarrier,
            ffCarrier: ffAirline,
            ffNumber: ffNumber,
            IDADIndicator: idIndicator,
            freeBags: freeBags,
            fastTrack: fastTrack,
            airlineUse: airlineUse
        )
    }
    
    /**
     * Parses additional flight segment information
     *
     * Extracts information about additional flight segments beyond the main segment,
     * used for multi-leg journeys and connecting flights.
     *
     * - Returns: A `BoardingPassSegment` object with parsed information
     * - Throws: `BoardingPassError` if parsing fails or structure is invalid
     *
     * ## Parsed Fields
     * - PNR code and route information
     * - Carrier and flight details
     * - Date and compartment information
     * - Seat and check-in status
     * - Passenger status and structure size
     * - Airline codes and ticket information
     * - Frequent flyer and airline-specific data
     *
     * ## Multi-Segment Handling
     * - Processes variable-length segment data
     * - Manages conditional field boundaries
     * - Handles airline-specific extensions
     * - Validates segment structure integrity
     */
    private func segment() throws -> BoardingPassSegment {
        let pnrCode = try conditional(7)
        let origin = try conditional(3)
        let destination = try conditional(3)
        let carrier = try conditional(3)
        let flightno = try conditional(5)
        let julianDate = try readint(3)
        let compartment = try conditional(1)
        let seatno = try conditional(4)
        let checkedin = try readint(5)
        let passengerStatus = try conditional(1)
        let structSize = try readhex(2)
        endConditional = structSize
        
        let segmentSize = try readhex(2, isMandatory: false)
        subConditional  = segmentSize
        
        let airlineCode = try conditional(3)
        let ticketNumber = try conditional(10)
        let selectee = try conditional(1)
        let internationalDoc = try conditional(1)
        let opCarrier = try conditional(3)
        let ffAirline = try conditional(3)
        let ffNumber = try conditional(16)
        
        var idad: String?
        if subConditional > 0
        { idad = try conditional(1) }
        
        var freeBags: String?
        if subConditional > 0
        { freeBags = try conditional(3) }
        
        var fastTrack: String?
        if subConditional > 0
        { fastTrack = try conditional(1) }
        
        var airlineUse: String?
        if subConditional >= 0 && endConditional > 0
        { airlineUse = try conditional(endConditional) }
        
        guard subConditional == 0
        else { throw BoardingPassError.SegmentSubConditionalInvalid }
        
        return BoardingPassSegment(
            pnrCode: pnrCode,
            origin: origin,
            destination: destination,
            carrier: carrier,
            flightno: flightno,
            julianDate: julianDate,
            compartment: compartment,
            seatno: seatno,
            checkedin: checkedin,
            passengerStatus: passengerStatus,
            structSize: structSize,
            segmentSize: segmentSize,
            airlineCode: airlineCode,
            ticketNumber: ticketNumber,
            selectee: selectee,
            internationalDoc: internationalDoc,
            ticketingCarrier: opCarrier,
            ffAirline: ffAirline,
            ffNumber: ffNumber,
            idAdIndicator: idad,
            freeBags: freeBags,
            fastTrack: fastTrack,
            airlineUse: airlineUse
        )
    }
}

// TODO: Implement
//extension String {
//    func removeLeading() -> String
//    { return replacingOccurrences(of: "^0+", with: "", options: .regularExpression) }
//}
