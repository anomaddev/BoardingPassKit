//
//  BoardingPassKit+String.swift
//  
//
//  Created by Justin Ackermann on 11/29/22.
//

import Foundation

/**
 * String extensions for BoardingPassKit functionality
 *
 * This extension provides utility methods for processing and formatting
 * string data commonly found in boarding pass information. These methods
 * help clean and standardize data for better parsing and display.
 *
 * ## Usage Example
 * ```swift
 * let flightNumber = "00123"
 * let cleanedNumber = flightNumber.removeLeadingZeros()
 * print(cleanedNumber) // "123"
 * 
 * let seatNumber = "  14A  "
 * let trimmedSeat = seatNumber.trimmingCharacters(in: .whitespaces)
 * print(trimmedSeat) // "14A"
 * ```
 *
 * ## Common Use Cases
 * - **Flight Numbers**: Remove leading zeros for cleaner display
 * - **Seat Numbers**: Clean up whitespace and formatting
 * - **PNR Codes**: Standardize format and remove unnecessary characters
 * - **Airport Codes**: Ensure proper formatting and case
 * - **Passenger Names**: Clean up formatting and separators
 */
public extension String {
    
    /**
     * Removes leading zeros from the beginning of a string
     *
     * This method is commonly used to clean up numeric fields like
     * flight numbers, seat numbers, and other identifiers that may
     * have unnecessary leading zeros.
     *
     * ## Behavior
     * - Removes all consecutive zeros at the beginning of the string
     * - Preserves zeros that are not at the beginning
     * - Returns the original string if no leading zeros exist
     * - Handles edge cases like empty strings and strings with only zeros
     *
     * ## Examples
     * ```swift
     * "00123".removeLeadingZeros()     // "123"
     * "000456".removeLeadingZeros()    // "456"
     * "123".removeLeadingZeros()       // "123"
     * "0".removeLeadingZeros()         // "0"
     * "00".removeLeadingZeros()        // "0"
     * "".removeLeadingZeros()          // ""
     * "ABC123".removeLeadingZeros()    // "ABC123"
     * ```
     *
     * ## Use Cases in BoardingPassKit
     * - **Flight Numbers**: Convert "00123" to "123" for display
     * - **Seat Numbers**: Clean up "0014A" to "14A"
     * - **Check-in Sequence**: Convert "00033" to "33"
     * - **Bag Tag Numbers**: Clean up "000123456789" to "123456789"
     *
     * ## Implementation Details
     * Uses a regular expression to match one or more zeros at the
     * beginning of the string and replaces them with an empty string.
     * The regex pattern `^0+` matches:
     * - `^`: Start of string
     * - `0+`: One or more zero characters
     *
     * ## Performance
     * This method is efficient for typical boarding pass data lengths
     * and uses the optimized `replacingOccurrences` method for string
     * manipulation.
     */
    func removeLeadingZeros() -> String {
        return replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
    }
}
