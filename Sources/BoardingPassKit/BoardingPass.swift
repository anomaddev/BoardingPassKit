//
//  BoardingPass.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation

public struct BoardingPass: Codable {
    
    public let version: String
    
    public var info: BoardingPassParent
    public var main: BoardingPassMainSegment
    public var segments: [BoardingPassSegment]
    public var security: BoardingPassSecurityData
    
    public var code: String
    
    public func printout() {
        print("")
        print("SEGMENTS: \(info.legs)")
        print("======================")
        print("MAIN SEGMENT")
        print("===MANDATORY ITEMS [60 characters long]===")
        print("FORMAT CODE:  \(info.format)")
        print("LEGS ENCODED: \(info.legs)")
        print("PASSENGER:    \(info.name)")
        print("INDICATOR:    \(info.ticketIndicator)")
        print("PNR CODE:     \(info.pnrCode)")
        print("ORIGIN:       \(info.origin)")
        print("DESTINATION:  \(info.destination)")
        print("CARRIER:      \(info.operatingCarrier)")
        print("FLIGHT NO:    \(info.flightno)")
        print("JULIAN DATE:  \(info.julianDate)")
        print("COMPARTMENT:  \(info.compartment)")
        print("SEAT NO:      \(info.seatno)")
        print("CHECK IN:     \(info.checkIn)")
        print("STATUS:       \(info.passengerStatus)")
        print("VAR SIZE:     \(info.conditionalSize)")
        print("")
        print("===CONDITIONAL ITEMS [\(info.conditionalSize) characters long]===")
        print("VERSION:       \(version)")
        print("PASS STRUCT:   \(main.structSize)")
        print("PASS DESC:     \(main.passengerDesc)")
        print("SOURCE CHK IN: \(main.checkInSource)")
        print("SOURCE PASS:   \(main.passSource)")
        print("DATE ISSUED:   \(main.dateIssued)")
        print("DOC TYPE:      \(main.documentType)")
        print("AIRLINE DESIG: \(main.carrier)")
        print("BAG TAG 1:     \(main.bagtag1 ?? "none")")
        print("BAG TAG 2:     \(main.bagtag2 ?? "none")")
        print("BAG TAG 3:     \(main.bagtag3 ?? "none")")
        print("======================")
        for (i, segment) in segments.enumerated() {
            print("SEGMENT: \(i + 2)")
            print("======================")
            print("PNRCODE:       \(segment.pnrCode)")
            print("ORIGIN:        \(segment.origin)")
            print("DESTINATION:   \(segment.destination)")
            print("CARRIER:       \(segment.carrier)")
            print("FLIGHT NO:     \(segment.flightno)")
            print("JULIAN DATE:   \(segment.julianDate)")
            print("COMPARTMENT:   \(segment.compartment)")
            print("SEAT NO:       \(segment.seatno ?? "-")")
            print("CHECKED IN:    \(segment.checkedin)")
            print("PASS STATUS:   \(segment.passengerStatus)")
            print("CONDITIONAL:   \(segment.structSize)")
            print("SEGMENT SIZE:  \(segment.segmentSize)")
            print("AIRLINE CODE:  \(segment.airlineCode)")
            print("DOC NUMBER:    \(segment.ticketNumber)")
            print("SELECTEE:      \(segment.selectee)")
            print("DOC VERIFY:    \(segment.internationalDoc)")
            print("OPERATOR:      \(segment.operatingCarrier)")
            print("FF AIRLINE:    \(segment.ffAirline)")
            print("FF NUMBER:     \(segment.ffNumber)")
            print("ID INDICATOR:  \(segment.idAdIndicator ?? "-")")
            print("FREE BAGS:     \(segment.freeBags ?? "-")")
            print("FAST TRACK:    \(segment.fastTrack ?? "-")")
            print("AIRLINE USE:   \(segment.airlineUse ?? "-")")
            print("========================")
        }
        print("")
        print("SECURITY DATA")
        print("========================")
        print("TYPE:     \(security.securityType)")
        print("LENGTH:   \(security.securitylength)")
        print("DATA:     \(security.securityData ?? "-")")
        print("========================")
    }
}
