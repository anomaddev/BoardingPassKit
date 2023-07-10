//
//  BoardingPassSegment.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation


public struct BoardingPassSegment: Codable {
    
    public let pnrCode: String
    public let origin: String
    public let destination: String
    public let carrier: String
    public let flightno: String
    public let julianDate: Int
    public let compartment: String
    public var seatno: String?
    public var checkedin: Int
    public var passengerStatus: String
    public var structSize: Int
    
    public let segmentSize: Int
    public var airlineCode: String
    public var ticketNumber: String
    public var selectee: String
    public var internationalDoc: String
    public var operatingCarrier: String
    public var ffAirline: String
    public var ffNumber: String
    public var idAdIndicator: String?
    public var freeBags: String?
    public var fastTrack: String?
    public var airlineUse: String?
    
}
