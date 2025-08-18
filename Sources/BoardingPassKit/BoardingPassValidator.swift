//
//  BoardingPassValidator.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation

/// A utility struct for validating boarding pass data before parsing
public struct BoardingPassValidator {
    
    // MARK: - Format Validation
    
    /// Validates the boarding pass format code
    /// - Parameter format: The format code to validate
    /// - Returns: `true` if the format is valid, `false` otherwise
    public static func validateFormat(_ format: String) -> Bool {
        return ["M", "S"].contains(format)
    }
    
    /// Validates the number of segments in the boarding pass
    /// - Parameter legs: The number of legs/segments
    /// - Returns: `true` if the segment count is valid, `false` otherwise
    public static func validateSegments(_ legs: Int) -> Bool {
        return legs > 0 && legs <= 10 // Reasonable upper limit
    }
    
    // MARK: - Airport Code Validation
    
    /// Validates airport codes (IATA 3-letter codes)
    /// - Parameter code: The airport code to validate
    /// - Returns: `true` if the airport code is valid, `false` otherwise
    public static func validateAirportCode(_ code: String) -> Bool {
        return code.count == 3 && 
               code.range(of: "^[A-Z]{3}$", options: .regularExpression) != nil
    }
    
    /// Validates multiple airport codes
    /// - Parameter codes: Array of airport codes to validate
    /// - Returns: Array of invalid codes found
    public static func validateAirportCodes(_ codes: [String]) -> [String] {
        return codes.filter { !validateAirportCode($0) }
    }
    
    // MARK: - Flight Number Validation
    
    /// Validates flight numbers
    /// - Parameter number: The flight number to validate
    /// - Returns: `true` if the flight number is valid, `false` otherwise
    public static func validateFlightNumber(_ number: String) -> Bool {
        return number.count >= 1 && number.count <= 5 &&
               number.range(of: "^[A-Z0-9]{1,5}$", options: .regularExpression) != nil
    }
    
    // MARK: - Date Validation
    
    /// Validates Julian date format
    /// - Parameter date: The Julian date string to validate
    /// - Returns: `true` if the date format is valid, `false` otherwise
    public static func validateJulianDate(_ date: String) -> Bool {
        guard let dayOfYear = Int(date) else { return false }
        return dayOfYear >= 1 && dayOfYear <= 366 // Account for leap years
    }
    
    /// Validates date issued format (YYYYMMDD or similar)
    /// - Parameter date: The date string to validate
    /// - Returns: `true` if the date format is valid, `false` otherwise
    public static func validateDateIssued(_ date: String) -> Bool {
        // Basic validation - can be enhanced with more specific date parsing
        return date.count == 4 || date.count == 8
    }
    
    // MARK: - PNR Code Validation
    
    /// Validates PNR (Passenger Name Record) codes
    /// - Parameter code: The PNR code to validate
    /// - Returns: `true` if the PNR code is valid, `false` otherwise
    public static func validatePNRCode(_ code: String) -> Bool {
        return code.count == 6 && 
               code.range(of: "^[A-Z0-9]{6}$", options: .regularExpression) != nil
    }
    
    // MARK: - Seat Number Validation
    
    /// Validates seat numbers
    /// - Parameter number: The seat number to validate
    /// - Returns: `true` if the seat number is valid, `false` otherwise
    public static func validateSeatNumber(_ number: String) -> Bool {
        return !number.isEmpty && 
               number.range(of: "^[A-Z0-9]+$", options: .regularExpression) != nil
    }
    
    // MARK: - Compartment Code Validation
    
    /// Validates compartment codes
    /// - Parameter code: The compartment code to validate
    /// - Returns: `true` if the compartment code is valid, `false` otherwise
    public static func validateCompartmentCode(_ code: String) -> Bool {
        return code.count == 1 && 
               code.range(of: "^[A-Z]$", options: .regularExpression) != nil
    }
    
    // MARK: - Passenger Status Validation
    
    /// Validates passenger status codes
    /// - Parameter status: The status code to validate
    /// - Returns: `true` if the status code is valid, `false` otherwise
    public static func validatePassengerStatus(_ status: String) -> Bool {
        return status.count == 1 && 
               status.range(of: "^[A-Z0-9]$", options: .regularExpression) != nil
    }
    
    // MARK: - Name Validation
    
    /// Validates passenger names
    /// - Parameter name: The passenger name to validate
    /// - Returns: `true` if the name is valid, `false` otherwise
    public static func validatePassengerName(_ name: String) -> Bool {
        return name.count >= 3 && name.count <= 20 &&
               name.range(of: "^[A-Z/ ]+$", options: .regularExpression) != nil
    }
    
    // MARK: - Ticket Number Validation
    
    /// Validates ticket numbers
    /// - Parameter number: The ticket number to validate
    /// - Returns: `true` if the ticket number is valid, `false` otherwise
    public static func validateTicketNumber(_ number: String) -> Bool {
        return number.count >= 10 && number.count <= 13 &&
               number.range(of: "^[0-9]+$", options: .regularExpression) != nil
    }
    
    // MARK: - Bag Tag Validation
    
    /// Validates bag tag numbers
    /// - Parameter tag: The bag tag to validate
    /// - Returns: `true` if the bag tag is valid, `false` otherwise
    public static func validateBagTag(_ tag: String?) -> Bool {
        guard let tag = tag else { return true } // Optional field
        return tag.isEmpty || 
               tag.range(of: "^[A-Z0-9]+$", options: .regularExpression) != nil
    }
    
    // MARK: - Comprehensive Validation
    
    /// Validates a complete boarding pass code string
    /// - Parameter code: The boarding pass code to validate
    /// - Returns: Array of validation errors found
    public static func validateBoardingPass(_ code: String) -> [BoardingPassError] {
        var errors: [BoardingPassError] = []
        
        // Basic length validation
        if code.count < 60 {
            errors.append(.parsingFailed(at: "start", reason: "Code too short (minimum 60 characters required)"))
            return errors // Can't continue with very short codes
        }
        
        // Check first character (format)
        if let firstChar = code.first {
            if !validateFormat(String(firstChar)) {
                errors.append(.InvalidPassFormat(format: String(firstChar)))
            }
        }
        
        // Check second character (number of legs)
        if code.count >= 2 {
            let legsChar = String(code[code.index(code.startIndex, offsetBy: 1)])
            if let legs = Int(legsChar) {
                if !validateSegments(legs) {
                    errors.append(.InvalidSegments(legs: legs))
                }
            }
        }
        
        // Validate passenger name (characters 3-22)
        if code.count >= 22 {
            let nameStart = code.index(code.startIndex, offsetBy: 2)
            let nameEnd = code.index(code.startIndex, offsetBy: 21)
            let name = String(code[nameStart...nameEnd])
            if !validatePassengerName(name) {
                errors.append(.parsingFailed(at: "passenger name", reason: "Invalid name format"))
            }
        }
        
        // Validate PNR code (characters 23-29)
        if code.count >= 29 {
            let pnrStart = code.index(code.startIndex, offsetBy: 22)
            let pnrEnd = code.index(code.startIndex, offsetBy: 28)
            let pnr = String(code[pnrStart...pnrEnd])
            if !validatePNRCode(pnr) {
                errors.append(.invalidPNRCode(code: pnr))
            }
        }
        
        // Validate origin airport (characters 30-32)
        if code.count >= 32 {
            let originStart = code.index(code.startIndex, offsetBy: 29)
            let originEnd = code.index(code.startIndex, offsetBy: 31)
            let origin = String(code[originStart...originEnd])
            if !validateAirportCode(origin) {
                errors.append(.invalidAirportCode(code: origin))
            }
        }
        
        // Validate destination airport (characters 33-35)
        if code.count >= 35 {
            let destStart = code.index(code.startIndex, offsetBy: 32)
            let destEnd = code.index(code.startIndex, offsetBy: 34)
            let destination = String(code[destStart...destEnd])
            if !validateAirportCode(destination) {
                errors.append(.invalidAirportCode(code: destination))
            }
        }
        
        // Validate flight number (characters 36-40)
        if code.count >= 40 {
            let flightStart = code.index(code.startIndex, offsetBy: 35)
            let flightEnd = code.index(code.startIndex, offsetBy: 39)
            let flight = String(code[flightStart...flightEnd])
            if !validateFlightNumber(flight) {
                errors.append(.invalidFlightNumber(number: flight))
            }
        }
        
        return errors
    }
    
    /// Validates boarding pass data and throws an error if validation fails
    /// - Parameter code: The boarding pass code to validate
    /// - Throws: `BoardingPassError` if validation fails
    public static func validateAndThrow(_ code: String) throws {
        let errors = validateBoardingPass(code)
        if !errors.isEmpty {
            throw errors.first!
        }
    }
    
    // MARK: - Field-Specific Validation Helpers
    
    /// Validates that a string contains only alphanumeric characters
    /// - Parameter string: The string to validate
    /// - Returns: `true` if the string is alphanumeric, `false` otherwise
    public static func isAlphanumeric(_ string: String) -> Bool {
        return string.range(of: "^[A-Za-z0-9]+$", options: .regularExpression) != nil
    }
    
    /// Validates that a string contains only uppercase letters
    /// - Parameter string: The string to validate
    /// - Returns: `true` if the string contains only uppercase letters, `false` otherwise
    public static func isUppercaseLetters(_ string: String) -> Bool {
        return string.range(of: "^[A-Z]+$", options: .regularExpression) != nil
    }
    
    /// Validates that a string contains only digits
    /// - Parameter string: The string to validate
    /// - Returns: `true` if the string contains only digits, `false` otherwise
    public static func isDigits(_ string: String) -> Bool {
        return string.range(of: "^[0-9]+$", options: .regularExpression) != nil
    }
    
    /// Validates that a string length is within specified bounds
    /// - Parameters:
    ///   - string: The string to validate
    ///   - minLength: Minimum allowed length
    ///   - maxLength: Maximum allowed length
    /// - Returns: `true` if the string length is within bounds, `false` otherwise
    public static func validateLength(_ string: String, minLength: Int, maxLength: Int) -> Bool {
        return string.count >= minLength && string.count <= maxLength
    }
}
