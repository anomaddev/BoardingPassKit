//
//  BoardingPassDecoder.swift
//
//
//  Created by Justin Ackermann on 7/7/23.
//

import Foundation

open class BoardingPassDecoder: NSObject {
    
    private var index: Int = 0
    private var subConditional: Int = 0
    private var endConditional: Int = 0
    
    /// Setting this to `true` will print lots of details to the console
    public var debug: Bool = true
    
    /// Will trim any leading zeros from fields when not needed. Default value is `true`
    public var trimLeadingZeroes: Bool = true
    
    /// Will trim any whitespace from fields when not needed. Default value is `true`
    public var trimWhitespace: Bool = true
    
    /// Empty strings should set the Boarding Pass variable to `nil`. Default value is `true`
    public var emptyStringIsNil: Bool = true
    
    /// A `Data` representation of the boarding pass barcode
    public var data: Data!
    
    /// A `String` representation of the boarding pass barcode
    public var code: String!
    
    /// takes `Data` and parses as .ascii encoded `String`
    private func raw(_ data: Data) throws -> String {
        guard let str = String(data: data,
                               encoding: String.Encoding.ascii)
        else { throw BoardingPassError.DataFailedStringDecoding }
        return str
    }
    
    /// Helper function to apply emptyStringIsNil logic to optional strings
    private func applyEmptyStringIsNil(_ value: String?) -> String? {
        guard let value = value else { return nil }
        return emptyStringIsNil && value.isEmpty ? nil : value
    }
    
    /// Decode to a Boarding Pass class
    ///
    /// - parameter data: `Data` to be decoded
    /// - returns: `BoardingPass` codable object
    /// - throws: `BoardingPassDecoderError` code
    ///
    /// - todo: remove optional in the return
    ///
    public func decode(_ data: Data) throws -> BoardingPass {
        self.data = data
        self.code = try raw(data)
        return try breakdown()
    }
    
    /// Decode to a Boarding Pass class
    ///
    /// - parameter code: `String` of a barcode scan
    /// - returns: `BoardingPass` codable object
    /// - throws: `BoardingPassDecoderError` code
    ///
    /// - todo: remove optional in the return
    ///
    public func decode(code: String) throws -> BoardingPass {
        self.data = code.data(using: .ascii)
        self.code = code
        return try breakdown()
    }
    
    /// Breaks down the code/data and returns the boarding pass decoded. This is the mothership function
    private func breakdown() throws -> BoardingPass {
        if debug { print("PARSING BOARDING PASS...") }
        
        index = 0
        subConditional = 0
        endConditional = 0
        
        // BOARDING PASS HEADER INFO
        let format          = try mandatory(1)
        let numberOfLegs    = try readint(1)
        let name            = try mandatory(20)
        let ticketIndicator = try mandatory(1)
        
        guard let numberOfLegs
        else { throw BoardingPassError.DataFailedValidation(code: "Number of legs is nil") }
        
        // INITIALIZE LEGS ARRAY
        var legs: [BoardingPassLeg] = []
        
        // BOARDING PASS LEG 1 DATA (Required)
        var firstLeg = try repeatedMandatory(index: 0)
        endConditional = firstLeg.conditionalSize
        if debug { print("SET endConditional: \(endConditional)") }
        
        // BOARDING PASS UNIQUE CONDITIONAL (Optional data after the first leg's mandatory section)
        let passInfo = try uniqueConditional()
        
        // BOARDING PASS LEG 1 CONDITIONAL DATA (Optional field size indicates data)
        let firstLegConditional = try repeatedConditional()
        firstLeg.conditionalData = firstLegConditional
        legs.append(firstLeg)
        
        // LOOP THROUGH LEGS REMAINING
        let legsRemaining = numberOfLegs - 1
        if debug { print("LEGS REMAINING: \(legsRemaining)") }

        if legsRemaining > 0 {
            for i in 1..<numberOfLegs {
                if debug { print("Looping for leg: \(i)") }
                
                var leg = try repeatedMandatory(index: i)
                endConditional = leg.conditionalSize
                if debug { print("SET endConditional: \(endConditional)") }

                let legConditional = try repeatedConditional()
                leg.conditionalData = legConditional
                legs.append(leg)
            }
        }
        
        if debug { print("PARSING LEGS COMPLETE") }
        // Ensure legs are sorted by legIndex in ascending order
        legs.sort { $0.legIndex < $1.legIndex }
        
        var security: BoardingPassSecurityData?
        var blob: String?

        if index < data.count {
            // Peek the next character without advancing the index
            let firstCharData = data.subdata(in: index..<(index + 1))
            let firstChar = String(data: firstCharData, encoding: .ascii)

            if firstChar == "^" {
                // Consume the '^' marker and parse security block
                let beginSecurity = try mandatory(1)
                let typeSecurity = try mandatory(1)
                let lengthSecurity = try readhex(2, isMandatory: true)
                let securityData = try mandatory(lengthSecurity)

                security = BoardingPassSecurityData(
                    beginSecurity: applyEmptyStringIsNil(beginSecurity),
                    securityType: applyEmptyStringIsNil(typeSecurity),
                    securitylength: lengthSecurity,
                    securityData: applyEmptyStringIsNil(securityData)
                )
            }
        }
        
        // After a valid security block, if there is any remaining data, capture it as the airline blob
        if index < data.count {
            let remaining = data.subdata(in: index..<data.count)
            if let remainingString = String(data: remaining, encoding: .ascii) {
                let processedString = trimWhitespace ? remainingString.trimmingCharacters(in: .whitespaces) : remainingString
                blob = applyEmptyStringIsNil(processedString)
            }
            index = data.count
        }
        
        guard subConditional == 0
        else { throw NSError() }
        
        print("parsed boarding pass...")
        let pass = BoardingPass(
            format: format,
            numberOfLegs: numberOfLegs,
            passengerName: name,
            ticketIndicator: ticketIndicator,
            boardingPassLegs: legs,
            passInfo: passInfo,
            securityData: security,
            airlineBlob: blob,
            code: code
        )
        
        print("======================")
        print("Boarding Pass:")
        print(pass.code)
        print("======================")
        if debug { pass.printout() }
        return pass
    }
    
    /// This returns a mandatory string in the decoding sequence of the barcode scan
    private func mandatory(_ length: Int) throws -> String {
        if (data.count < index + length)
        { throw BoardingPassError.MandatoryItemNotFound(index: index) }
        
        var string: String = try readdata(length)
        if debug { print("MANDATORY: " + string) }
        
        if trimWhitespace { string = string.trimmingCharacters(in: .whitespaces) }
        
        return string
    }
    
    /// This returns a conditional field given it does not go over the length specified
    private func conditional(_ length: Int) throws -> String {
        if (data.count < index + length) && (endConditional > 0)
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
    
    /// Read the next section of data of a given length and return the `Int` value
    private func readint(_ length: Int) throws -> Int? {
        var rawString = try mandatory(length)
        if debug { print("RAW INT: \(rawString)") }
        
        // Apply leading zero trimming if enabled
        if trimWhitespace { rawString = rawString.trimmingCharacters(in: .whitespaces) }
        if trimLeadingZeroes { rawString = rawString.removeLeadingZeros() }
        if emptyStringIsNil && rawString.isEmpty { return nil }
        if !emptyStringIsNil && rawString.isEmpty { return 0 }
        
        guard let number = Int(rawString)
        else { throw BoardingPassError.FieldValueNotRequiredInteger(value: rawString) }
        
        return number
    }
    
    /// Read the next section of data of a given length and return the `String` value
    private func readdata(_ length: Int) throws -> String {
        let subdata = data.subdata(in: index ..< (index + length))
        index += length
        
        guard let rawString = String(data: subdata, encoding: String.Encoding.ascii)
        else { throw BoardingPassError.DataFailedStringDecoding }
        return rawString
    }
    
    
    /// Read the next section of data of a given length and return the decimal hex value as an `Int`
    private func readhex(_ length: Int, isMandatory: Bool! = true) throws -> Int {
        let str: String!
        
        if isMandatory { str = try mandatory(length) }
        else { str = try conditional(length) }
        
        guard let int = Int(str, radix: 16)
        else { throw BoardingPassError.HexStringFailedDecoding(string: str) }
        
        if debug { print("HEX: \(int)") }
        return int
    }
    
    /// Cycle through the boarding pass code and pull out the `BoardingPassParent` data
    private func repeatedMandatory(index: Int) throws -> BoardingPassLeg {
        do {
            if debug { print("PARSING REPEATED MANDATORY") }
            let pnrCode         = try mandatory(7)
            let origin          = try mandatory(3)
            let destination     = try mandatory(3)
            let opCarrier       = try mandatory(3)
            var flightno        = try mandatory(5)
            let julianDate      = try readint(3)
            let compartment     = try mandatory(1)
            var seatno          = try mandatory(4)
            let checkIn         = try readint(5)
            let passengerStatus = try mandatory(1)
            let fieldSize       = try readhex(2)
            
            // TODO: Add more validation
            if trimLeadingZeroes {
                flightno = flightno.removeLeadingZeros()
                seatno = seatno.removeLeadingZeros()
            }
            
            guard let julianDate
            else { throw BoardingPassError.DataFailedValidation(code: "Julian Date is nil") }
            
            return BoardingPassLeg(
                legIndex:           index,
                pnrCode:            pnrCode,
                origin:             origin,
                destination:        destination,
                operatingCarrier:   opCarrier,
                flightno:           flightno,
                julianDate:         julianDate,
                compartment:        compartment,
                seatno:             seatno,
                checkIn:            checkIn,
                passengerStatus:    passengerStatus,
                conditionalSize:    fieldSize
            )
        } catch { throw BoardingPassError.DataIsNotBoardingPass(error: error) }
    }
    
    /// Cycle through the boarding pass code and pull out the unique conditionals
    private func uniqueConditional() throws -> BoardingPassInfo {
        do {
            if debug { print("PARSING UNIQUE CONDITIONAL") }
            
            // The unique conditionals block begins with a marker and a version,
            // followed by a 2-hex-length field that defines the size of this sub-block.
            let beginningChar = try conditional(1)
            let version       = try conditional(1)
            
            // Size (hex) of the remaining unique-conditional payload
            let fieldSize     = try readhex(2, isMandatory: false)
            
            // Track remaining bytes in this unique-conditional section
            subConditional = fieldSize
            if debug { print("SET subConditional: \(subConditional)") }
            
            // Parse fixed fields defined by IATA BCBP for the Unique Section
            var passDesc: String?    = try conditional(1)
            var checkSource: String? = try conditional(1)
            var passSource: String?  = try conditional(1)
            var issueDate: String?   = try conditional(4)
            var docType: String?     = try conditional(1)
            let airlineCode: String  = try conditional(3)
            
            // Apply leading zero trimming to relevant fields
            if trimLeadingZeroes {
                issueDate = issueDate?.removeLeadingZeros()
            }
            
            // Apply emptyStringIsNil logic to optional fields
            passDesc = applyEmptyStringIsNil(passDesc)
            checkSource = applyEmptyStringIsNil(checkSource)
            passSource = applyEmptyStringIsNil(passSource)
            issueDate = applyEmptyStringIsNil(issueDate)
            docType = applyEmptyStringIsNil(docType)
            
            var bagTags: [String] = []
            // Read any 13-character bag tag chunks remaining in this sub-conditional
            while subConditional >= 13 {
                let tag = try conditional(13)
                if !tag.isEmpty && (!emptyStringIsNil || !tag.trimmingCharacters(in: .whitespaces).isEmpty) { 
                    bagTags.append(tag) 
                }
            }
            
            // If any non-bag-tag padding remains, consume it defensively to avoid desync
            if subConditional > 0 {
                _ = try? conditional(subConditional)
                subConditional = 0
            }
            
            return BoardingPassInfo(
                beginningChar: beginningChar,
                version: version,
                fieldSize: fieldSize,
                passengerDescription: passDesc,
                checkInSource: checkSource,
                passSource: passSource,
                issueDate: issueDate,
                documentType: docType,
                issuingAirline: airlineCode,
                bagTags: bagTags
            )
        } catch { throw BoardingPassError.DataIsNotBoardingPass(error: error) }
    }
    
    /// Parse the repeated conditional fields
    private func repeatedConditional() throws -> BoardingPassLegData {
        do {
            if debug { print("PARSING REPEATED CONDITIONAL") }
            // Size (hex) of the remaining unique-conditional payload
            let fieldSize = try readhex(2, isMandatory: false)
            subConditional = fieldSize
            if debug { print("SET subConditional: \(subConditional)") }
            
            // Check that the sub conditional chars we have left is less than or equal to the end conditional chars left
            guard subConditional <= endConditional
            else { throw BoardingPassError.BoardingPassLegConditionalMismatch }
            
            if debug {
                print()
                print("Sub Conditional Check Passed: \(fieldSize)")
                print()
            }
            
            let airlineNumeric: String    = try conditional(3)
            let documentNumber: String    = try conditional(10)
            let selectee: String          = try conditional(1)
            let internationalDoc: String  = try conditional(1)
            let marketingCarrier: String  = try conditional(3)
            
            /// We subtrack the number of chars before freq flier info (18), plus the chars we know come after (5) to get the size of the freq flier data.
            let ffFieldSize: Int = fieldSize - 23
            
            if debug {
                print("Conditional chars left: \(subConditional)")
                print("Freq Flyer size: \(ffFieldSize)")
            }
            
            let ffInfo: String = try conditional(ffFieldSize)
            // Parse Frequent Flyer fields from ffInfo
            let parsedFFAirline: String = trimWhitespace 
                ? String(ffInfo.prefix(3)).trimmingCharacters(in: .whitespaces)
                : String(ffInfo.prefix(3))
            let parsedFFNumber: String = ffInfo.count > 3
                ? (trimWhitespace 
                    ? String(ffInfo.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    : String(ffInfo.dropFirst(3)))
                : ""
  
            if debug {
                print("FF Airline: \(parsedFFAirline)")
                print("FF Number: \(parsedFFNumber)")
                print()
                print("Parsed Freq Flyer Info: \(ffInfo)")
                print("Conditional chars left: \(subConditional)")
            }
            
            var idAdIndicator: String? = try conditional(1)
            var freeBags: String?      = try conditional(3)
            var fastTrack: String?     = try conditional(1)
            
            var airlineUse: String?
            let leftOver: Int = endConditional - subConditional
            if leftOver > 0 { airlineUse = try conditional(leftOver) }
            
            // Apply emptyStringIsNil logic to optional fields
            idAdIndicator = applyEmptyStringIsNil(idAdIndicator)
            freeBags = applyEmptyStringIsNil(freeBags)
            fastTrack = applyEmptyStringIsNil(fastTrack)
            airlineUse = applyEmptyStringIsNil(airlineUse)
            
            guard endConditional == subConditional
            else { throw BoardingPassError.BoardingPassLegConditionalMismatch }
            
            if debug {
                print()
                print("Sub Conditional Parsing Complete!")
                print()
            }
            
            return BoardingPassLegData(
                segmentSize: fieldSize,
                airlineCode: airlineNumeric,
                ticketNumber: documentNumber,
                selectee: selectee,
                internationalDoc: internationalDoc,
                ticketingCarrier: marketingCarrier,
                ffAirline: parsedFFAirline,
                ffNumber: parsedFFNumber,
                idAdIndicator: idAdIndicator,
                freeBags: freeBags,
                fastTrack: fastTrack,
                airlineUse: airlineUse
            )
        } catch { throw BoardingPassError.DataIsNotBoardingPass(error: error) }
    }
}
