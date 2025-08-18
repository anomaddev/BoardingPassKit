//
//  BoardingPassError.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation

public enum BoardingPassError: Error {
    
    case InvalidPassFormat(format: String)
    case InvalidSegments(legs: Int)
    
    case DataFailedValidation(code: String)
    case DataIsNotBoardingPass(error: Error)
    
    case CIQRCodeGeneratorNotFound
    case CIQRCodeGeneratorOutputFailed
    
    case MandatoryItemNotFound(index: Int)
    case DataFailedStringDecoding
    case FieldValueNotRequiredInteger(value: String)
    case HexStringFailedDecoding(string: String)
    
    case ConditionalIndexInvalid(Int, Int)
    case MainSegmentBagConditionalInvalid
    case MainSegmentSubConditionalInvalid
    case SegmentSubConditionalInvalid
    
    // New error cases for validation
    case invalidDateFormat(date: String)
    case invalidAirportCode(code: String)
    case invalidFlightNumber(number: String)
    case parsingFailed(at: String, reason: String)
    case invalidPNRCode(code: String)
    case invalidSeatNumber(number: String)
    case invalidCompartmentCode(code: String)
    case invalidPassengerStatus(status: String)
    
    case unexpected(code: Int)
    
}

extension BoardingPassError: LocalizedError {
    public var errorDescription: String? {
        var key: String = "unexpected"
        
        switch self {
            
        case .InvalidPassFormat:                key = "InvalidPassFormat"
        case .InvalidSegments:                  key = "InvalidSegments"
            
        case .DataFailedValidation:             key = "DataFailedValidation"
        case .DataIsNotBoardingPass:            key = "DataIsNotBoardingPass"
            
        case .CIQRCodeGeneratorNotFound:        key = "CIQRCodeGeneratorNotFound"
        case .CIQRCodeGeneratorOutputFailed:    key = "CIQRCodeGeneratorOutputFailed"
            
        case .MandatoryItemNotFound:            key = "MandatoryItemNotFound"
        case .DataFailedStringDecoding:         key = "DataFailedStringDecoding"
        case .FieldValueNotRequiredInteger:     key = "FieldValueNotRequiredInteger"
        case .HexStringFailedDecoding:          key = "HexStringFailedDecoding"
            
        case .ConditionalIndexInvalid:          key = "ConditionalIndexInvalid"
        case .MainSegmentBagConditionalInvalid: key = "MainSegmentBagConditionalInvalid"
        case .MainSegmentSubConditionalInvalid: key = "MainSegmentSubConditionalInvalid"
        case .SegmentSubConditionalInvalid:     key = "SegmentSubConditionalInvalid"
            
        // New error keys
        case .invalidDateFormat:                key = "InvalidDateFormat"
        case .invalidAirportCode:               key = "InvalidAirportCode"
        case .invalidFlightNumber:              key = "InvalidFlightNumber"
        case .parsingFailed:                    key = "ParsingFailed"
        case .invalidPNRCode:                   key = "InvalidPNRCode"
        case .invalidSeatNumber:                key = "InvalidSeatNumber"
        case .invalidCompartmentCode:           key = "InvalidCompartmentCode"
        case .invalidPassengerStatus:           key = "InvalidPassengerStatus"
            
        case .unexpected(_): key = "unexpected"
        }
        
        return NSLocalizedString(key, comment: self.localizedDescription)
    }
    
    // Add recovery suggestions for better user experience
    public var recoverySuggestion: String? {
        switch self {
        case .InvalidPassFormat:
            return "Boarding pass format must start with 'M' (multi-segment) or 'S' (single-segment)"
        case .InvalidSegments:
            return "Number of segments must be greater than 0"
        case .invalidDateFormat:
            return "Ensure the date is in the correct format (YYYYMMDD or Julian date)"
        case .invalidAirportCode:
            return "Airport codes must be exactly 3 uppercase letters (e.g., LAX, JFK, LHR)"
        case .invalidFlightNumber:
            return "Flight numbers should contain only alphanumeric characters and be 1-5 characters long"
        case .invalidPNRCode:
            return "PNR codes must be exactly 6 alphanumeric characters"
        case .invalidSeatNumber:
            return "Seat numbers should contain only alphanumeric characters"
        case .invalidCompartmentCode:
            return "Compartment codes must be a single character"
        case .invalidPassengerStatus:
            return "Passenger status must be a single character"
        case .DataFailedStringDecoding:
            return "Ensure the boarding pass data is properly encoded in ASCII format"
        case .FieldValueNotRequiredInteger:
            return "The field value must be a valid integer number"
        case .HexStringFailedDecoding:
            return "The field value must be a valid hexadecimal string"
        case .ConditionalIndexInvalid:
            return "The boarding pass data structure appears to be corrupted or incomplete"
        case .MainSegmentBagConditionalInvalid, .MainSegmentSubConditionalInvalid, .SegmentSubConditionalInvalid:
            return "The boarding pass segment data structure is invalid. The data may be corrupted."
        case .CIQRCodeGeneratorNotFound, .CIQRCodeGeneratorOutputFailed:
            return "QR code generation failed. This may be due to system limitations or corrupted data."
        default:
            return "Please verify the boarding pass data format and try again. If the problem persists, the data may be corrupted."
        }
    }
    
    // Add failure reason for better debugging
    public var failureReasonError: String? {
        switch self {
        case .InvalidPassFormat(let format):
            return "The format code '\(format)' is not recognized. Valid formats are 'M' and 'S'."
        case .InvalidSegments(let legs):
            return "The segment count \(legs) is invalid. Must be greater than 0."
        case .invalidDateFormat(let date):
            return "The date string '\(date)' does not match expected format patterns."
        case .invalidAirportCode(let code):
            return "The airport code '\(code)' is not 3 uppercase letters."
        case .invalidFlightNumber(let number):
            return "The flight number '\(number)' contains invalid characters or wrong length."
        case .parsingFailed(let location, let reason):
            return "Parsing stopped at '\(location)' because: \(reason)"
        case .ConditionalIndexInvalid(let end, let sub):
            return "Conditional parsing failed: endConditional=\(end), subConditional=\(sub)"
        default:
            return nil
        }
    }
}
