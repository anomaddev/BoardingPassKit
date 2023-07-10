//
//  BoardingPassDecoder.swift
//  
//
//  Created by Justin Ackermann on 7/7/23.
//

import Foundation

open class BoardingPassDecoder: NSObject {
    
    public var debug: Bool = false
    
    /// Will trim any leading zeros from fields when not needed. Default value is `true`
    public var trimLeadingZeroes: Bool  = true
    
    /// Will trim any whitespace from fields when not needed. Default value is `true`
    public var trimWhitespace: Bool     = true
    
    private var index: Int = 0
    private var subConditional: Int = 0
    private var endConditional: Int = 0
    
    /// A `Data` representation of the boarding pass barcode
    public var data: Data!
    
    /// A `String` representation of the boarding pass barcode
    public var code: String!
    
    /// takes `Data` and parses as .ascii encoded `String`
    private func raw(_ data: Data) throws -> String {
        guard let str = String(data: data,
                               encoding: String.Encoding.ascii)
        else { throw NSError() } // THROW:
        return str
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
    
    /// This returns a conditional field give it does not go over the length specified
    private func conditional(_ length: Int) throws -> String {
        if (data.count < index + length) &&
           (endConditional > 0)
        { throw NSError() } // THROW:
        
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
    
    /// Read the next section of data of a given length and return the string value
    public func readint(_ length: Int) throws -> Int {
        let rawString = try mandatory(length)
        if debug { print("RAW INT: \(rawString)") }
        
        guard let number = Int(rawString.trimmingCharacters(in: .whitespaces))
        else { throw BoardingPassError.FieldValueNotRequiredInteger(value: rawString) }
        
        return number
    }
    
    /// Read the next section of data of a given length and return the string value
    public func readdata(_ length: Int) throws -> String {
        let subdata = data.subdata(in: index ..< (index + length))
        index += length
        
        guard let rawString = String(data: subdata, encoding: String.Encoding.ascii)
        else { throw BoardingPassError.DataFailedStringDecoding }
        return rawString
    }
    
    
    /// Read the next section of data of a given length and return the decimal hex value
    public func readhex(_ length: Int, isMandatory: Bool! = true) throws -> Int {
        let str: String!
        
        if isMandatory { str = try mandatory(length) }
        else { str = try conditional(length) }
        
        guard let int = Int(str, radix: 16)
        else { throw BoardingPassError.HexStringFailedDecoding(string: str) }
        
        if debug { print("HEX: \(int)") }
        return int
    }
    
    /// Cycle through the boarding pass code and pull out the `BoardingPassParent` data
    private func parent() throws -> BoardingPassParent {
        let parent = BoardingPassParent(
            format:             try mandatory(1),
            legs:               try readint(1),
            name:               try mandatory(20),
            ticketIndicator:    try mandatory(1),
            pnrCode:            try mandatory(7),
            origin:             try mandatory(3),
            destination:        try mandatory(3),
            operatingCarrier:   try mandatory(3),
            flightno:           try mandatory(5),
            julianDate:         try readint(3),
            compartment:        try mandatory(1),
            seatno:             try mandatory(4),
            checkIn:            try readint(5),
            passengerStatus:    try mandatory(1),
            conditionalSize:    try readhex(2)
        )
        
        guard parent.legs > 0
        else { throw BoardingPassError.InvalidBoardingPassLegs(parent.legs) }
        
        return parent
    }
    
    /// Cycle through the boarding pass code and pull out the `BoardingPassMainSegment` data
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
    
    /// Cycle through the boarding pass code and pull out all the `BoardingPassSegment` data objects
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
            operatingCarrier: opCarrier,
            ffAirline: ffAirline,
            ffNumber: ffNumber,
            idAdIndicator: idad,
            freeBags: freeBags,
            fastTrack: fastTrack,
            airlineUse: airlineUse
        )
    }
}
