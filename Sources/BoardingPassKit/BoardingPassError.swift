//
//  BoardingPassError.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation

public enum BoardingPassError: Error {
    
    case MandatoryItemNotFound(index: Int)
    case InvalidBoardingPassLegs(Int)
    case DataFailedStringDecoding
    case FieldValueNotRequiredInteger
    case HexStringFailedDecoding
    
}
