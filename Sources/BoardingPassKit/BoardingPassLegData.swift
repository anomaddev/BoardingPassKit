//
//  BoardingPassLegData.swift
//  BoardingPassKit
//
//  Created by Justin Ackermann on 10/7/25.
//

// Core iOS
import Foundation

/// Represents a single leg's conditional data segment within a boarding pass barcode (BCBP) decoding system.
/// This struct captures detailed information extracted from the leg-specific portion of a BCBP,
/// providing properties that correspond to various airline and passenger data elements.
/// Each property maps directly to fields defined in the IATA BCBP specification for leg data.
public struct BoardingPassLegData: Codable {
    
    /// Total length in characters of this leg’s conditional segment.
    public let segmentSize: Int
    
    /// 2-letter IATA airline designator.
    public var airlineCode: String
    
    /// Electronic ticket number or reference.
    public var ticketNumber: String
    
    /// Security selectee flag.
    public var selectee: String
    
    /// International documentation indicator.
    public var internationalDoc: String
    
    /// Carrier responsible for ticketing.
    public var ticketingCarrier: String
    
    /// Frequent flyer airline code.
    public var ffAirline: String
    
    /// Frequent flyer number.
    public var ffNumber: String
    
    /// ID/AD travel indicator (optional).
    public var idAdIndicator: String?
    
    /// Number of free bags allowed (optional).
    public var freeBags: String?
    
    /// Fast track security indicator (optional).
    public var fastTrack: String?
    
    /// Airline-specific data block (optional).
    public var airlineUse: String?
    
    /// print the data to the console
    public func printout() {
        print("""
        ====CONDITIONAL DATA====

        Segment Size:           \(segmentSize)
        Airline Code:           \(airlineCode)
        Ticket Number:          \(ticketNumber)
        Selectee:               \(selectee)
        International Doc:      \(internationalDoc)
        Ticketing Carrier:      \(ticketingCarrier)
        Frequent Flyer Airline: \(ffAirline)
        Frequent Flyer Number:  \(ffNumber)
        """)
        if let idAd = idAdIndicator { print(
        "ID/AD Indicator:       \(idAd)"
        )}
        
        if let bags = freeBags { print(
        "Free Bags:             \(bags)"
        )}
        
        if let fast = fastTrack { print(
        "Fast Track:            \(fast)"
        )}
        
        if let use = airlineUse { print(
        "Airline Use:           \(use)"
        )}
    }
}
