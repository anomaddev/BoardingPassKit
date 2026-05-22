//
//  BoardingPassInfo.swift
//  BoardingPassKit
//
//  Created by Justin Ackermann on 10/7/25.
//

import Foundation

public struct BoardingPassInfo: Codable {
    
    /// Beginning Char (garbage data)
    public let beginningChar: String
    
    /// IATA BCBP Version
    public let version: String
    
    /// Field Size of following text. Parsed decimal from hexidecimal.
    public let fieldSize: Int
    
    /// Passenger Description / Gender Code (Field 15)
    /// Valid values per IATA Resolution 792 Version 8:
    /// - "M" = Male
    /// - "F" = Female
    /// - "X" = Unspecified (added in Version 8)
    /// - "U" = Undisclosed (added in Version 8)
    /// - "0"-"9" = Adult, Child, Infant, etc.
    public var passengerDescription: String?
    
    /// Source of Check-In
    public var checkInSource: String?
    
    /// Source of Boarding Pass issuance
    public var passSource: String?
    
    /// Date of Issue
    public var issueDate: String?
    
    /// Document Type
    public var documentType: String?
    
    /// IATA Code for the Airline issuing pass
    public let issuingAirline: String
    
    /// Bag Tags
    public var bagTags: [String]
    
    /// Print out the details of the boarding pass parent
    public func printout() {
        print("""
        🛫 Boarding Pass Info
        Beginning Char:          \(beginningChar)
        IATA BCBP Version:       \(version)
        Field Size:              \(fieldSize)
        Passenger Description:   \(passengerDescription ?? "empty")
        Check-In Source:         \(checkInSource ?? "empty")
        Pass Issuance Source:    \(passSource ?? "empty")
        Date of Issue:           \(issueDate ?? "empty")
        Document Type:           \(documentType ?? "empty")
        Issuing Airline:         \(issuingAirline)
        
        """)
        
        for (i, tag) in bagTags.enumerated()
        { print("Bag Tag \(i + 1): \(tag)") }
        print()
    }
}
