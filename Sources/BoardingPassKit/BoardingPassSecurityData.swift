//
//  SecurityData.swift
//  
//
//  Created by Justin Ackermann on 11/29/22.
//

import Foundation

/// Security Data for a `BoardingPass`
public struct BoardingPassSecurityData: Codable {
    
    public var beginSecurity: String?
    public var securityType: String?
    public var securitylength: Int?
    public var securityData: String?
    
}
