//
//  BoardingPassParent.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation

public struct BoardingPassParent: Codable {
    
    public let format: String
    public let legs: Int
    public let name: String
    public let ticketIndicator: String
    public let pnrCode: String
    public let origin: String
    public let destination: String
    public let operatingCarrier: String
    public let flightno: String
    public let julianDate: Int
    public let compartment: String
    public let seatno: String
    public let checkIn: Int
    public let passengerStatus: String
    public let conditionalSize: Int
    
}
