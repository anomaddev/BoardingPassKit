//
//  BoardingPassError.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation

/**
 * Comprehensive error handling for BoardingPassKit operations
 *
 * This enum provides detailed error information for all possible failure scenarios
 * when working with boarding pass data, including parsing, validation, and QR code generation.
 * Each error case includes associated data to help developers understand and resolve issues.
 *
 * ## Usage Example
 * ```swift
 * do {
 *     let boardingPass = try decoder.decode(code: code)
 * } catch BoardingPassError.InvalidPassFormat(let format) {
 *     print("Invalid format: \(format). Expected 'M' or 'S'")
 * } catch BoardingPassError.DataFailedValidation(let code) {
 *     print("Validation failed for code: \(code)")
 * } catch {
 *     print("Unexpected error: \(error)")
 * }
 * ```
 *
 * ## Error Categories
 * - **Format & Structure Errors**: Invalid boarding pass format or segment count
 * - **Data Validation Errors**: Failed validation of boarding pass data
 * - **Parsing Errors**: Issues during the parsing process
 * - **QR Code Errors**: Problems with QR code generation
 * - **System Errors**: Core system or framework failures
 */
public enum BoardingPassError: Error {
    
    // MARK: - Format & Structure Errors
    
    /**
     * Invalid boarding pass format code
     *
     * Boarding passes must start with either 'M' (multi-segment) or 'S' (single-segment).
     * This error occurs when the first character is not one of these valid options.
     *
     * - Parameter format: The invalid format character found
     *
     * ## Example
     * ```swift
     * // Thrown when parsing "X1ACKERMANN/JUSTIN..."
     * // Expected: "M1ACKERMANN/JUSTIN..." or "S1ACKERMANN/JUSTIN..."
     * ```
     */
    case InvalidPassFormat(format: String)
    
    /**
     * Invalid number of segments in the boarding pass
     *
     * Boarding passes must have at least 1 segment and typically no more than 10.
     * This error occurs when the segment count is 0 or unreasonably high.
     *
     * - Parameter legs: The invalid segment count found
     *
     * ## Example
     * ```swift
     * // Thrown when parsing "M0ACKERMANN/JUSTIN..." (0 segments)
     * // Expected: "M1ACKERMANN/JUSTIN..." (1 segment) or higher
     * ```
     */
    case InvalidSegments(legs: Int)
    
    // MARK: - Data Validation Errors
    
    /**
     * Boarding pass data failed validation checks
     *
     * This error occurs when the boarding pass data doesn't meet basic requirements
     * such as minimum length, character encoding, or structural integrity.
     *
     * - Parameter code: The boarding pass code that failed validation
     *
     * ## Example
     * ```swift
     * // Thrown when code is too short (< 60 characters)
     * // or contains invalid characters
     * ```
     */
    case DataFailedValidation(code: String)
    
    /**
     * Data provided is not a valid boarding pass
     *
     * This error occurs when the data structure doesn't match expected boarding pass format,
     * often due to corrupted data or wrong data type.
     *
     * - Parameter error: The underlying error that caused the failure
     *
     * ## Example
     * ```swift
     * // Thrown when parsing non-boarding pass data
     * // or when the data structure is completely invalid
     * ```
     */
    case DataIsNotBoardingPass(error: Error)
    
    // MARK: - System & Framework Errors
    
    /**
     * Core Image QR code generator filter not found
     *
     * This error occurs when the device doesn't support QR code generation
     * or when the Core Image framework is unavailable.
     *
     * ## Resolution
     * - Check if running on iOS device
     * - Verify Core Image framework availability
     * - Ensure device supports required iOS version
     */
    case CIQRCodeGeneratorNotFound
    
    /**
     * QR code generation output failed
     *
     * This error occurs when the QR code generation process completes
     * but fails to produce a valid output image.
     *
     * ## Resolution
     * - Verify input data is valid
     * - Check available memory
     * - Ensure image size is reasonable
     */
    case CIQRCodeGeneratorOutputFailed
    
    // MARK: - Parsing Errors
    
    /**
     * Required field not found during parsing
     *
     * This error occurs when a mandatory field is missing or truncated
     * at the expected position in the boarding pass data.
     *
     * - Parameter index: The position where the field was expected
     *
     * ## Example
     * ```swift
     * // Thrown when passenger name field is missing at position 3
     * // or when PNR code is truncated at position 23
     * ```
     */
    case MandatoryItemNotFound(index: Int)
    
    /**
     * Failed to decode data as ASCII string
     *
     * This error occurs when the boarding pass data cannot be converted
     * from raw bytes to an ASCII string representation.
     *
     * ## Resolution
     * - Verify data encoding is ASCII
     * - Check for corrupted bytes
     * - Ensure proper data format
     */
    case DataFailedStringDecoding
    
    /**
     * Field value is not a valid integer
     *
     * This error occurs when a field that should contain a number
     * contains non-numeric characters.
     *
     * - Parameter value: The invalid string value found
     *
     * ## Example
     * ```swift
     * // Thrown when flight number contains letters: "ABC12"
     * // Expected: numeric value like "12345"
     * ```
     */
    case FieldValueNotRequiredInteger(value: String)
    
    /**
     * Failed to decode hexadecimal string
     *
     * This error occurs when a field that should contain hexadecimal data
     * contains invalid characters or wrong format.
     *
     * - Parameter string: The invalid hexadecimal string
     *
     * ## Example
     * ```swift
     * // Thrown when hex field contains "XYZ" instead of "1A2B"
     * // Expected: valid hexadecimal characters (0-9, A-F)
     * ```
     */
    case HexStringFailedDecoding(string: String)
    
    /**
     * Conditional field parsing failed
     *
     * This error occurs when the conditional field structure is invalid
     * or when the parsing indices don't align properly.
     *
     * - Parameter end: The end conditional index
     * - Parameter sub: The sub conditional index
     *
     * ## Resolution
     * - Verify boarding pass data integrity
     * - Check for truncated or corrupted data
     * - Ensure proper conditional field structure
     */
    case ConditionalIndexInvalid(Int, Int)
    
    /**
     * Main segment bag tag parsing failed
     *
     * This error occurs when parsing bag tag information in the main segment
     * and the conditional field structure becomes invalid.
     */
    case MainSegmentBagConditionalInvalid
    
    /**
     * Main segment conditional parsing failed
     *
     * This error occurs when the main segment conditional fields
     * cannot be properly parsed due to structural issues.
     */
    case MainSegmentSubConditionalInvalid
    
    /**
     * Segment conditional parsing failed
     *
     * This error occurs when parsing conditional fields in additional segments
     * and the structure becomes invalid.
     */
    case SegmentSubConditionalInvalid
    
    // MARK: - Validation Errors
    
    /**
     * Invalid date format in boarding pass
     *
     * This error occurs when date fields don't match expected formats
     * such as Julian dates or YYYYMMDD format.
     *
     * - Parameter date: The invalid date string found
     *
     * ## Example
     * ```swift
     * // Thrown when date is "ABC" instead of "123" (Julian)
     * // or "20231201" (YYYYMMDD format)
     * ```
     */
    case invalidDateFormat(date: String)
    
    /**
     * Invalid airport code format
     *
     * Airport codes must be exactly 3 uppercase letters (IATA format).
     * This error occurs when the code doesn't match this pattern.
     *
     * - Parameter code: The invalid airport code found
     *
     * ## Example
     * ```swift
     * // Thrown when airport code is "AB" (too short)
     * // or "abc" (lowercase) or "123" (numbers)
     * // Expected: "LAX", "JFK", "LHR", etc.
     * ```
     */
    case invalidAirportCode(code: String)
    
    /**
     * Invalid flight number format
     *
     * Flight numbers must be 1-5 alphanumeric characters.
     * This error occurs when the format doesn't match requirements.
     *
     * - Parameter number: The invalid flight number found
     *
     * ## Example
     * ```swift
     * // Thrown when flight number is "" (empty)
     * // or "123456" (too long) or "ABC-123" (invalid chars)
     * // Expected: "123", "AA123", "ABC12", etc.
     * ```
     */
    case invalidFlightNumber(number: String)
    
    /**
     * General parsing failure
     *
     * This error occurs when parsing fails at a specific location
     * with a given reason.
     *
     * - Parameter at: The location where parsing failed
     * - Parameter reason: The reason for the failure
     *
     * ## Example
     * ```swift
     * // Thrown when parsing fails at "passenger name" due to "invalid format"
     * // or at "PNR code" due to "missing field"
     * ```
     */
    case parsingFailed(at: String, reason: String)
    
    /**
     * Invalid PNR (Passenger Name Record) code
     *
     * PNR codes must be exactly 6 alphanumeric characters.
     * This error occurs when the format doesn't match requirements.
     *
     * - Parameter code: The invalid PNR code found
     *
     * ## Example
     * ```swift
     * // Thrown when PNR is "ABC" (too short)
     * // or "ABC1234" (too long) or "ABC-12" (invalid chars)
     * // Expected: "ABC123", "XYZ789", etc.
     * ```
     */
    case invalidPNRCode(code: String)
    
    /**
     * Invalid seat number format
     *
     * Seat numbers must contain only alphanumeric characters.
     * This error occurs when invalid characters are found.
     *
     * - Parameter number: The invalid seat number found
     *
     * ## Example
     * ```swift
     * // Thrown when seat number is "12A-" (invalid char)
     * // or "12 A" (space) or "12@A" (special char)
     * // Expected: "12A", "34B", "15C", etc.
     * ```
     */
    case invalidSeatNumber(number: String)
    
    /**
     * Invalid compartment code
     *
     * Compartment codes must be a single character.
     * This error occurs when the format doesn't match requirements.
     *
     * - Parameter code: The invalid compartment code found
     *
     * ## Example
     * ```swift
     * // Thrown when compartment code is "AB" (too long)
     * // or "" (empty) or "1" (number instead of letter)
     * // Expected: "Y", "F", "C", "M", etc.
     * ```
     */
    case invalidCompartmentCode(code: String)
    
    /**
     * Invalid passenger status code
     *
     * Passenger status codes must be a single character.
     * This error occurs when the format doesn't match requirements.
     *
     * - Parameter status: The invalid status code found
     *
     * ## Example
     * ```swift
     * // Thrown when status is "AB" (too long)
     * // or "" (empty) or "@" (special character)
     * // Expected: "1", "2", "3", "C", "I", etc.
     * ```
     */
    case invalidPassengerStatus(status: String)
    
    // MARK: - QR Code Generation Errors
    
    /**
     * QR code generation failed with specific reason
     *
     * This error occurs when QR code generation fails for a specific reason
     * such as data size limits or memory constraints.
     *
     * - Parameter reason: The specific reason for the failure
     *
     * ## Example
     * ```swift
     * // Thrown when generation fails due to "data too large"
     * // or "insufficient memory" or "invalid parameters"
     * ```
     */
    case qrCodeGenerationFailed(reason: String)
    
    /**
     * Failed to overlay logo on QR code
     *
     * This error occurs when attempting to add a logo overlay
     * to a generated QR code image.
     *
     * ## Resolution
     * - Verify logo image is valid
     * - Check logo size relative to QR code
     * - Ensure sufficient error correction level
     */
    case qrCodeLogoOverlayFailed
    
    /**
     * Failed to apply styling to QR code
     *
     * This error occurs when applying custom styling such as
     * colors, rounded corners, or shadows fails.
     *
     * ## Resolution
     * - Verify styling parameters are valid
     * - Check for memory constraints
     * - Ensure Core Image filters are available
     */
    case qrCodeStylingFailed
    
    /**
     * QR code data exceeds size limits
     *
     * This error occurs when the boarding pass data is too large
     * to encode in a QR code with the specified error correction level.
     *
     * - Parameter size: The size of the data in bytes
     *
     * ## Resolution
     * - Reduce error correction level
     * - Use larger QR code version
     * - Consider splitting data into multiple codes
     */
    case qrCodeDataTooLarge(size: Int)
    
    // MARK: - General Errors
    
    /**
     * Unexpected error occurred
     *
     * This error occurs when an unexpected failure happens
     * that doesn't fit into other error categories.
     *
     * - Parameter code: The error code for debugging
     *
     * ## Resolution
     * - Check error code for specific details
     * - Review system logs
     * - Contact support with error details
     */
    case unexpected(code: Int)
}

// MARK: - LocalizedError Conformance

/**
 * Provides localized error descriptions and recovery suggestions
 *
 * This extension implements the LocalizedError protocol to provide
 * user-friendly error messages and actionable recovery suggestions.
 */
extension BoardingPassError: LocalizedError {
    
    /**
     * Localized error description key
     *
     * Returns the appropriate localization key for each error type,
     * enabling internationalization of error messages.
     */
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
        
        // QR Code error keys
        case .qrCodeGenerationFailed:           key = "QRCodeGenerationFailed"
        case .qrCodeLogoOverlayFailed:          key = "QRCodeLogoOverlayFailed"
        case .qrCodeStylingFailed:              key = "QRCodeStylingFailed"
        case .qrCodeDataTooLarge:               key = "QRCodeDataTooLarge"
            
        case .unexpected(_): key = "unexpected"
        }
        
        return NSLocalizedString(key, comment: self.localizedDescription)
    }
    
    /**
     * Actionable recovery suggestions
     *
     * Provides specific, actionable advice for resolving each error type,
     * helping users understand how to fix the problem.
     */
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
        case .invalidPassengerStatus(let status):
            return "Invalid passenger status: \(status). Must be a single character"
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
        case .qrCodeGenerationFailed(let reason):
            return "QR code generation failed: \(reason)"
        case .qrCodeLogoOverlayFailed:
            return "Failed to overlay logo on QR code"
        case .qrCodeStylingFailed:
            return "Failed to apply styling to QR code"
        case .qrCodeDataTooLarge(let size):
            return "QR code data too large: \(size) bytes. Maximum recommended: 2000 bytes"
        default:
            return "Please verify the boarding pass data format and try again. If the problem persists, the data may be corrupted."
        }
    }
    
    /**
     * Detailed failure reason for debugging
     *
     * Provides technical details about why the error occurred,
     * useful for developers debugging issues.
     */
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
        case .qrCodeGenerationFailed(let reason):
            return "QR code generation failed: \(reason)"
        case .qrCodeLogoOverlayFailed:
            return "Logo overlay failed during QR code generation"
        case .qrCodeStylingFailed:
            return "Styling application failed during QR code generation"
        case .qrCodeDataTooLarge(let size):
            return "QR code data size \(size) bytes exceeds recommended limit of 2000 bytes"
        case .unexpected(let code): return "Unexpected error occurred with code \(code)"
        default:
            return nil
        }
    }
}
