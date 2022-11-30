//
//  File.swift
//  
//
//  Created by Justin Ackermann on 11/29/22.
//

import Foundation

public class BoardingPassLeg: Codable {
    
    public var airlineData: String?
    public var ticketAirline: String?
    public var ticketNumber: String?
    
    public let origin: String
    public let destination: String
    public let carrier: String
    
    public let pnrCode: String
    public let flightno: String
    public let dayOfYear: Int
    public let compartment: String
    public var seatno: String?
    public var checkedin: Int?
    public let passengerStatus: String
    
    public var selectee: String?
    public var documentVerification: String?
    public var bookedAirline: String?
    public var ffAirline: String?
    public var ffNumber: String?
    public var idAdIndicator: String?
    public var freeBags: String?
    public var fastTrack: Bool?
    
    // computed
//    var originAirport: Airport
//    { origin.airport ?? Airport.UKWN }
//
//    var destinationAirport: Airport
//    { destination.airport ?? Airport.UKWN }
//
//    var airline: Airline?
//    { carrier.airline }
    
//    var ident: String? {
//        let no = flightno.removeLeadingZeros()
//        guard let airline = airline
//        else { return nil }
//        return "\(airline.ident)\(no)"
//    }
    
//    var distance: Distance {
//        let o = originAirport
//        let d = destinationAirport
//        return Distance(from: o.coordinate, to: d.coordinate)
//    }
    
//    var path: MKGeodesicPolyline? {
//        let o = originAirport.coordinate
//        let d = destinationAirport.coordinate
//        return MKGeodesicPolyline(coordinates: [o, d], count: 2)
//    }
    
    public init(data parser: BoardingPassParser) throws {
        pnrCode = try parser.getstring(7, mandatory: true)!
        origin = try parser.getstring(3, mandatory: true)!
        destination = try parser.getstring(3, mandatory: true)!
        carrier = try parser.getstring(3, mandatory: true)!
        flightno = try parser.getstring(5, mandatory: true)!
        dayOfYear = try parser.getstring(3, mandatory: true)!.number()
        compartment = try parser.getstring(1, mandatory: true)!
        seatno = try parser.getstring(4, mandatory: true)?.removeLeadingZeros()
        checkedin = try parser.getstring(5, mandatory: true)?.number()
        passengerStatus = try parser.getstring(1, mandatory: true)!
    }
    
    public func addconditionals(data parser: BoardingPassParser) throws {
        ticketAirline = try parser.getstring(3)
        ticketNumber = try parser.getstring(10)
        
        selectee = try parser.getstring(1)
        documentVerification = try parser.getstring(1)
        bookedAirline = try parser.getstring(3)
        ffAirline = try parser.getstring(3)
        ffNumber = try parser.getstring(16)
        idAdIndicator = try parser.getstring(1)
        freeBags = try parser.getstring(3)
        // <v5 won't find fast track
        fastTrack = try parser.getstring(1)?.bool()
    }
}
