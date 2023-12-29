//
//  BoardingPassMainSegment.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

// TODO: Handle last day of the year for issue date vs flight date

import Foundation

public struct BoardingPassMainSegment: Codable {
    
    public let structSize: Int
    public let passengerDesc: String
    public let checkInSource: String
    public let passSource: String
    public let dateIssued: String
    public let documentType: String
    public let passIssuer: String
    
    public var bagtag1: String?
    public var bagtag2: String?
    public var bagtag3: String?
    
    public let nextSize: Int
    public let airlineCode: String
    public let ticketNumber: String
    public let selectee: String
    public let internationalDoc: String
    public let carrier: String
    public var ffCarrier: String?
    public var ffNumber: String?
    
    public var IDADIndicator: String?
    public var freeBags: String?
    public var fastTrack: String?
    public var airlineUse: String?

    /// julian year
    public var year: Int? {
        guard dateIssued != "    " else { return nil}
        if dateIssued.count == 4 { return Int(String(dateIssued.first!)) }
        else { return nil }
    }
    
    /// julian day
    public var nthDay: Int? {
        guard dateIssued != "    " else { return nil}
        if dateIssued.count == 3 { return Int(dateIssued) }
        else { return Int(String(dateIssued.dropFirst())) }
    }
}
