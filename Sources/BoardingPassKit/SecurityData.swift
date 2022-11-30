//
//  SecurityData.swift
//  
//
//  Created by Justin Ackermann on 11/29/22.
//

import Foundation

public struct SecurityData: Codable {
    var securityType: Int?
    var securitylength: Int?
    var securityData: String?
    
    init(data: Data) throws {
        let parser = BoardingPassParser(data: data)
        
        do {
            securityType = try parser.getstring(1)?.number()
            securitylength = try parser.readhex(2)
            securityData = try parser.getstring(securitylength!)
        } catch { throw error }
    }
    
    init(data: String) {
        securityData = data
    }
}
