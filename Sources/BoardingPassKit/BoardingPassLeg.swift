//
//  File.swift
//  
//
//  Created by Justin Ackermann on 11/29/22.
//

import Foundation

public class BoardingPassLeg: Codable {
    
    var airlineData: String?
    var ticketAirline: String?
    var ticketNumber: String?
    
    let origin: String
    let destination: String
    let carrier: String
    
    let pnrCode: String
    let flightno: String
    let dayOfYear: Int
    let compartment: String
    var seatno: String?
    var checkedin: Int?
    let passengerStatus: String
    
    var selectee: String?
    var documentVerification: String?
    var bookedAirline: String?
    var ffAirline: String?
    var ffNumber: String?
    var idAdIndicator: String?
    var freeBags: String?
    var fastTrack: Bool?
    
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
    
    init(data parser: BoardingPassParser) throws {
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
    
    func addconditionals(data parser: BoardingPassParser) throws {
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
