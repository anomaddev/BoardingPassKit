//
//  BoardingPassKit+String.swift
//  
//
//  Created by Justin Ackermann on 11/29/22.
//

import Foundation

public extension String {
    func removeLeadingZeros() -> String
    { return replacingOccurrences(of: "^0+", with: "", options: .regularExpression) }
}
