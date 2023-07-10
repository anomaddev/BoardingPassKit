//
//  BoardingPassParent.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation

public struct BoardingPassParent: Codable {
    
    /// The format code of the boarding pass
    public let format: String
    
    /// The number of legs included in this boarding pass
    public let legs: Int
    
    /// The passenger's name information
    public let name: String
    
    /// The electronic ticket indicator
    public let ticketIndicator: String
    
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
    
}
