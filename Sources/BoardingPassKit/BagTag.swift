//
//  BagTag.swift
//  
//
//  Created by Justin Ackermann on 11/29/22.
//

import Foundation

public struct BagTag: Codable {
    var type: String?
    var airlineNumeric: String?
    
    init(data: Data) throws {
        let parser = BoardingPassParser(data: data)
        do {
            type = try parser.getstring(1)
            airlineNumeric = try parser.getstring(3)
        } catch { throw error }
    }
}
