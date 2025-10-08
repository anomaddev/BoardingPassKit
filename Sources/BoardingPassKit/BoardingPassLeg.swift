//
//  BoardingPassLeg.swift
//  BoardingPassKit
//
//  Created by Justin Ackermann on 10/7/25.
//

// Core iOS
import Foundation

/// Represents a single flight segment (leg) in a Bar Coded Boarding Pass (BCBP).
///
/// Each boarding pass may contain one or more legs corresponding to individual flight segments.
/// The first leg has an index of 0, with subsequent legs representing additional segments of the journey.
/// This struct encapsulates the mandatory fields defined by the BCBP specification, including the record locator (PNR),
/// origin and destination airport codes, operating carrier, flight number, and other essential travel details.
///
/// Additionally, it includes an optional conditional segment (`conditionalData`) that contains extended airline-specific information,
/// which is not part of the mandatory BCBP fields but may provide further details relevant to the passenger or flight.
///
/// `BoardingPassLeg` instances are used within the larger boarding pass decoding system to parse and represent each flight segment
/// individually, allowing for detailed inspection and processing of multi-leg itineraries encoded within a single boarding pass.
public struct BoardingPassLeg: Codable {
    
    /// This is parsed as we read the boarding pass. The first leg is 0.
    public let legIndex: Int
    
    /// The record locator with the airline
    public let pnrCode: String
    
    /// The IATA code of the origin airport
    public let origin: String
    
    /// The IATA code of the destination airport
    public let destination: String
    
    /// The IATA code of the airline operating the flight
    public let operatingCarrier: String
    
    /// The flight number of the operating airline
    public let flightno: String
    
    /// The day of the year the flight takes place
    public let julianDate: Int
    
    /// The compartment code for the passenger on the main segment
    public let compartment: String
    
    /// The seat number for the passenger on the main segment
    public let seatno: String
    
    /// What number passenger you were to check in
    public let checkIn: Int
    
    /// Bag check, checked in, etc. This code needs to be parsed.
    public let passengerStatus: String
    
    /// The size of the conditional data in the boarding pass. Parsed decimal from hexidecimal.
    public let conditionalSize: Int
    
    /// The conditional data for this leg of the boarding pass
    public var conditionalData: BoardingPassLegData?
    
    /// Print out the details of the boarding pass parent
    public func printout() {
        print("""
        🛫 Boarding Pass Leg (INDEX: \(legIndex))
        =====MANDATORY DATA=====
        Record Locator:      \(pnrCode)
        Origin:              \(origin)
        Destination:         \(destination)
        Operating Carrier:   \(operatingCarrier)
        Flight Number:       \(flightno)
        Julian Date:         \(julianDate)
        Compartment:         \(compartment)
        Seat Number:         \(seatno)
        Check-in Order:      \(checkIn)
        Passenger Status:    \(passengerStatus)
        Conditional Size:    \(conditionalSize)
        
        """)
        conditionalData?.printout()
        print()
    }
}
