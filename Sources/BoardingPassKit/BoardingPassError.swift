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
    case FieldValueNotRequiredInteger(value: String)
    case HexStringFailedDecoding(string: String)
    
    case ConditionalIndexInvalid(Int, Int)
    case MainSegmentBagConditionalInvalid
    case MainSegmentSubConditionalInvalid
    case SegmentSubConditionalInvalid
    
    case unexpected(code: Int)
}

extension BoardingPassError: CustomStringConvertible {
    public var description: String {
        switch self {
            
        case .MandatoryItemNotFound(let index):         return "Mandatory field value is not found at index \(index)"
        case .InvalidBoardingPassLegs(let legs):        return "Invalid number of boarding pass segments \(legs)"
        case .DataFailedStringDecoding:                 return "Data fail .ascii String decoding"
        case .FieldValueNotRequiredInteger(let value):  return "Field value \(value) is supposed to be an integer and is not"
        case .HexStringFailedDecoding(let str):         return "String \(str) failed to decode as hexidecimal"
            
        case .ConditionalIndexInvalid(let end, let sub):
            return "Conditional parsing failed due to endConditional \(end) or subConditional \(sub)"
            
        case .MainSegmentBagConditionalInvalid:         return "Main segment conditional is invalid parsing after bag tags"
        case .MainSegmentSubConditionalInvalid:         return "Final main segment conditional is invalid parsing index"
        case .SegmentSubConditionalInvalid:             return "Segment sub conditional is invalid parsing index"
            
        case .unexpected(let code):         return "Error code \(code) occured."
        }
    }
}

extension BoardingPassError: LocalizedError {
    public var errorDescription: String? {
        var key: String = "unexpected"
        
        switch self {
            
        case .MandatoryItemNotFound:            key = "MandatoryItemNotFound"
        case .InvalidBoardingPassLegs:          key = "InvalidBoardingPassLegs"
        case .DataFailedStringDecoding:         key = "DataFailedStringDecoding"
        case .FieldValueNotRequiredInteger:     key = "FieldValueNotRequiredInteger"
        case .HexStringFailedDecoding:          key = "HexStringFailedDecoding"
            
        case .ConditionalIndexInvalid:          key = "ConditionalIndexInvalid"
        case .MainSegmentBagConditionalInvalid: key = "MainSegmentBagConditionalInvalid"
        case .MainSegmentSubConditionalInvalid: key = "MainSegmentSubConditionalInvalid"
        case .SegmentSubConditionalInvalid:     key = "SegmentSubConditionalInvalid"
            
        case .unexpected(_):            key = "unexpected"
        }
        
        return NSLocalizedString(key, comment: self.description)
    }
}
