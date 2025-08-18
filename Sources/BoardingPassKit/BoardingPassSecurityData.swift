//
//  SecurityData.swift
//  
//
//  Created by Justin Ackermann on 11/29/22.
//

import Foundation

/**
 * Security and validation data for boarding pass authentication
 *
 * The `BoardingPassSecurityData` struct contains airline-specific security codes,
 * validation data, and other security-related information required for boarding
 * pass validation and authentication. This data is used by airlines to verify
 * the authenticity of boarding passes and prevent fraud.
 *
 * ## Structure Overview
 * The security data section contains:
 * - **Security Indicator**: Marks the beginning of security data
 * - **Security Type**: Type of security validation used
 * - **Security Length**: Size of the security data in characters
 * - **Security Data**: Actual security codes and validation information
 *
 * ## Usage Example
 * ```swift
 * let boardingPass = try decoder.decode(code: barcodeString)
 * let security = boardingPass.security
 * 
 * // Check if security data is present
 * if let securityType = security.securityType {
 *     print("Security Type: \(securityType)")
 *     print("Security Length: \(security.securitylength ?? 0)")
 *     
 *     if let securityData = security.securityData {
 *         print("Security Data: \(securityData)")
 *     }
 * } else {
 *     print("No security data present")
 * }
 * ```
 *
 * ## IATA BCBP Security Data
 * The security data section follows the conditional fields and contains:
 * - **Security Marker**: Usually ">" character indicating security data start
 * - **Security Type**: 1-character code indicating security method
 * - **Security Length**: 2-character hexadecimal length
 * - **Security Data**: Variable-length security information
 *
 * ## Security Types
 * Different airlines use various security validation methods:
 * - **"A"**: Airline-specific algorithm
 * - **"B"**: Boarding pass validation
 * - **"C"**: Cryptographic validation
 * - **"D"**: Digital signature
 * - **"E"**: Encrypted data
 * - **"F"**: Format validation
 * - **"G"**: Government security
 * - **"H"**: Hash validation
 * - **"I"**: Integrity check
 * - **"J"**: Journey validation
 * - **"K"**: Key validation
 * - **"L"**: Legacy validation
 * - **"M"**: Multi-factor validation
 * - **"N"**: Network validation
 * - **"O"**: Operational validation
 * - **"P"**: Passenger validation
 * - **"Q"**: Quality check
 * - **"R"**: Route validation
 * - **"S"**: Security validation
 * - **"T"**: Time validation
 * - **"U"**: User validation
 * - **"V"**: Verification
 * - **"W"**: Web validation
 * - **"X"**: Extended validation
 * - **"Y"**: Year validation
 * - **"Z"**: Zone validation
 *
 * ## Security Data Formats
 * The actual security data varies by airline and security type:
 * - **Base64 encoded**: Common for cryptographic signatures
 * - **Hexadecimal**: Used for hash values and checksums
 * - **Alphanumeric**: Airline-specific validation codes
 * - **Binary**: Encoded security information
 *
 * ## Validation Process
 * Airlines use this security data to:
 * 1. **Verify Authenticity**: Ensure the boarding pass is genuine
 * 2. **Prevent Fraud**: Detect counterfeit or modified passes
 * 3. **Validate Data**: Confirm data integrity and accuracy
 * 4. **Track Usage**: Monitor boarding pass generation and usage
 * 5. **Comply with Regulations**: Meet security and safety requirements
 */
public struct BoardingPassSecurityData: Codable {
    
    // MARK: - Security Structure
    
    /**
     * Security data section indicator
     *
     * A character (usually ">") that marks the beginning of the
     * security data section in the boarding pass.
     *
     * ## Common Values
     * - `">"`: Standard security data indicator
     * - `"^"`: Alternative security data indicator
     * - `"|"`: Separator for multiple security sections
     * - `nil`: No security data present
     *
     * ## Usage
     * Used by the parser to identify where security data begins
     * and to distinguish it from other boarding pass sections.
     */
    public var beginSecurity: String?
    
    /**
     * Type of security validation used
     *
     * A single character code indicating the method of security
     * validation employed by the airline.
     *
     * ## Security Methods
     * - **"A"**: Algorithm-based validation
     * - **"B"**: Boarding pass checksum
     * - **"C"**: Cryptographic signature
     * - **"D"**: Digital certificate
     * - **"E"**: Encrypted validation
     * - **"F"**: Format validation
     * - **"G"**: Government security
     * - **"H"**: Hash validation
     * - **"I"**: Integrity check
     * - **"J"**: Journey validation
     * - **"K"**: Key-based validation
     * - **"L"**: Legacy validation
     * - **"M"**: Multi-factor validation
     * - **"N"**: Network validation
     * - **"O"**: Operational validation
     * - **"P"**: Passenger validation
     * - **"Q"**: Quality assurance
     * - **"R"**: Route validation
     * - **"S"**: Security validation
     * - **"T"**: Time-based validation
     * - **"U"**: User authentication
     * - **"V"**: Verification code
     * - **"W"**: Web-based validation
     * - **"X"**: Extended validation
     * - **"Y"**: Year validation
     * - **"Z"**: Zone validation
     *
     * ## Note
     * The specific meaning of each code varies by airline and
     * may be proprietary or confidential information.
     */
    public var securityType: String?
    
    /**
     * Length of the security data in characters
     *
     * The number of characters in the security data section,
     * expressed as a decimal integer.
     *
     * ## Range
     * - **Typical**: 10-200 characters
     * - **Minimum**: Usually 8 characters
     * - **Maximum**: Varies by airline and security method
     *
     * ## Usage
     * Used by the parser to determine the boundaries of the
     * security data section and to validate data integrity.
     *
     * ## Note
     * This value is parsed from the 2-character hexadecimal
     * length field in the boarding pass.
     */
    public var securitylength: Int?
    
    /**
     * Actual security validation data
     *
     * The raw security codes, signatures, or validation information
     * used by the airline to authenticate the boarding pass.
     *
     * ## Data Formats
     * - **Base64**: Common for cryptographic signatures and certificates
     * - **Hexadecimal**: Used for hash values, checksums, and binary data
     * - **Alphanumeric**: Airline-specific validation codes and keys
     * - **Binary**: Encoded security information in various formats
     *
     * ## Content Examples
     * - **Cryptographic Signatures**: Long Base64 strings for digital signatures
     * - **Hash Values**: Shorter hexadecimal strings for data integrity
     * - **Validation Codes**: Alphanumeric codes for airline-specific validation
     * - **Encrypted Data**: Binary or encoded security information
     *
     * ## Security Features
     * This data may include:
     * - Digital signatures for authenticity verification
     * - Hash values for data integrity checking
     * - Encryption keys for secure communication
     * - Validation codes for fraud prevention
     * - Timestamps for time-based validation
     * - Route information for journey validation
     * - Passenger-specific security tokens
     * - Airline-specific security protocols
     *
     * ## Note
     * The content and format of this data is typically proprietary
     * to each airline and may be encrypted or obfuscated for security.
     */
    public var securityData: String?
}
