//
//  BoardingPass.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

// Core iOS

import Foundation

#if os(iOS)
import UIKit
#endif

/**
 * Represents a decoded IATA boarding pass with comprehensive flight information
 *
 * The `BoardingPass` struct is the core data model that contains all parsed information
 * from an IATA 2D barcode boarding pass. It provides structured access to passenger details,
 * flight information, segment data, and security information.
 *
 * ## Structure Overview
 * - **Parent Information**: Shared data across all segments (passenger name, PNR, etc.)
 * - **Main Segment**: Primary flight segment details
 * - **Additional Segments**: Multi-leg flight information (if applicable)
 * - **Security Data**: Airline security and validation data
 *
 * ## Usage Example
 * ```swift
 * let decoder = BoardingPassDecoder()
 * do {
 *     let boardingPass = try decoder.decode(code: barcodeString)
 *     
 *     // Access passenger information
 *     print("Passenger: \(boardingPass.info.name)")
 *     print("Flight: \(boardingPass.info.operatingCarrier) \(boardingPass.info.flightno)")
 *     print("Route: \(boardingPass.info.origin) → \(boardingPass.info.destination)")
 *     
 *     // Check if multi-segment
 *     if boardingPass.segments.count > 0 {
 *         print("Multi-leg flight with \(boardingPass.segments.count) additional segments")
 *     }
 *     
 *     // Generate QR code
 *     let qrCode = try boardingPass.qrCode()
 * } catch {
 *     print("Failed to decode boarding pass: \(error)")
 * }
 * ```
 *
 * ## IATA BCBP Format Support
 * This struct supports the IATA Boarding Pass Bar Code (BCBP) standard, which includes:
 * - **Format Code**: M (multi-segment) or S (single-segment)
 * - **Mandatory Fields**: 60 characters of essential flight information
 * - **Conditional Fields**: Variable-length additional information
 * - **Security Data**: Airline-specific validation and security codes
 *
 * ## Validation
 * The boarding pass can be validated using the `validate()` method or static `validate(_:)` method:
 * ```swift
 * // Validate existing boarding pass
 * if boardingPass.isValid {
 *     print("Boarding pass is valid")
 * }
 * 
 * // Validate code string before decoding
 * let errors = BoardingPass.validate(barcodeString)
 * if errors.isEmpty {
 *     let pass = try decoder.decode(code: barcodeString)
 * }
 * ```
 */
public struct BoardingPass: Codable {
    
    // MARK: - Core Properties
    
    /**
     * The IATA BCBP version number
     *
     * Indicates the version of the boarding pass format being used.
     * Most modern boarding passes use version "6".
     */
    public let version: String
    
    /**
     * The parent object containing information shared across all segments
     *
     * Contains essential flight information that applies to the entire journey,
     * including passenger details, PNR code, and primary flight information.
     */
    public var info: BoardingPassParent
    
    /**
     * The main segment of the boarding pass
     *
     * Represents the primary flight segment with detailed information about
     * the main leg of the journey, including bag tags and airline-specific data.
     */
    public var main: BoardingPassMainSegment
    
    /**
     * Additional flight segments for multi-leg journeys
     *
     * Contains information about additional flight segments beyond the main segment.
     * This array will be empty for single-segment boarding passes.
     */
    public var segments: [BoardingPassSegment]
    
    /**
     * Security and validation data used by the airline
     *
     * Contains airline-specific security codes, validation data, and other
     * security-related information required for boarding pass validation.
     */
    public var security: BoardingPassSecurityData
    
    /**
     * The original boarding pass barcode string
     *
     * The complete, unparsed boarding pass code that was used to create
     * this BoardingPass instance. Useful for debugging and verification.
     */
    public var code: String
    
    // MARK: - Computed Properties
    
    /**
     * Parsed passenger name segments
     *
     * Splits the passenger name into individual components, removing
     * separators and converting to lowercase for easier processing.
     *
     * ## Example
     * ```swift
     * // For name "ACKERMANN/JUSTIN DAVE"
     * // Returns: ["ackermann", "justin", "dave"]
     * let nameParts = boardingPass.nameSegments
     * ```
     */
    public var nameSegments: [String] {
        return info.name
            .split(separator: "/")
            .map { $0.split(separator: " ") }
            .reduce([], +)
            .map { String($0).lowercased() }
    }
    
    // MARK: - QR Code Generation
    
    #if os(iOS)
    /**
     * Generates a QR code representation of the boarding pass
     *
     * Creates a QR code image that can be scanned to retrieve the original
     * boarding pass data. This is useful for digital boarding passes and
     * mobile applications.
     *
     * - Parameter size: The dimensions of the generated QR code image
     * - Parameter correctionLevel: The error correction level (L, M, Q, H)
     * - Returns: A UIImage containing the QR code
     * - Throws: BoardingPassError if generation fails
     *
     * ## Error Correction Levels
     * - **L (Low)**: 7% recovery - Smallest size, least reliable
     * - **M (Medium)**: 15% recovery - Balanced size and reliability (default)
     * - **Q (Quartile)**: 25% recovery - Larger size, more reliable
     * - **H (High)**: 30% recovery - Largest size, most reliable
     *
     * ## Usage Example
     * ```swift
     * do {
     *     let qrCode = try boardingPass.qrCode(size: CGSize(width: 300, height: 300))
     *     qrCodeImageView.image = qrCode
     * } catch BoardingPassError.CIQRCodeGeneratorNotFound {
     *     print("QR code generation not supported on this device")
     * } catch {
     *     print("QR code generation failed: \(error)")
     * }
     * ```
     */
    public func qrCode(size: CGSize = CGSize(width: 200, height: 200), 
                       correctionLevel: String = "M") throws -> UIImage {
        let generator = QRCodeGenerator(boardingPassData: code)
        return try generator.generate(size: size, correctionLevel: correctionLevel)
    }
    
    /**
     * Generates a QR code with custom colors
     *
     * Creates a QR code with specified foreground and background colors,
     * useful for branding and visual integration with app designs.
     *
     * - Parameters:
     *   - size: The dimensions of the generated QR code image
     *   - correctionLevel: The error correction level (L, M, Q, H)
     *   - foregroundColor: The color of the QR code pattern
     *   - backgroundColor: The background color of the QR code
     * - Returns: A UIImage containing the styled QR code
     * - Throws: BoardingPassError if generation fails
     *
     * ## Usage Example
     * ```swift
     * let blueQR = try boardingPass.qrCode(
     *     size: CGSize(width: 250, height: 250),
     *     correctionLevel: "H",
     *     foregroundColor: .blue,
     *     backgroundColor: .white
     * )
     * ```
     */
    public func qrCode(size: CGSize = CGSize(width: 200, height: 200),
                       correctionLevel: String = "M",
                       foregroundColor: UIColor = .black,
                       backgroundColor: UIColor = .white) throws -> UIImage {
        let generator = QRCodeGenerator(boardingPassData: code)
        return try generator.generate(size: size, 
                                   correctionLevel: correctionLevel,
                                   foregroundColor: foregroundColor,
                                   backgroundColor: backgroundColor)
    }
    
    /**
     * Generates a QR code using a predefined style configuration
     *
     * Creates a QR code with comprehensive styling options including colors,
     * corner radius, shadows, and other visual effects.
     *
     * - Parameters:
     *   - size: The dimensions of the generated QR code image
     *   - style: The QRCodeStyle configuration object
     * - Returns: A UIImage containing the styled QR code
     * - Throws: BoardingPassError if generation fails
     *
     * ## Usage Example
     * ```swift
     * let style = QRCodeStyle.printing()
     * let printQR = try boardingPass.qrCode(size: CGSize(width: 300, height: 300), style: style)
     * ```
     */
    public func qrCode(size: CGSize = CGSize(width: 200, height: 200),
                       style: QRCodeStyle) throws -> UIImage {
        let generator = QRCodeGenerator(boardingPassData: code)
        return try generator.generate(size: size, style: style)
    }
    
    /**
     * Generates a QR code with an embedded logo
     *
     * Creates a QR code with a logo overlay in the center, useful for
     * airline branding and visual identification. Uses high error correction
     * to ensure the logo doesn't interfere with scanning.
     *
     * - Parameters:
     *   - size: The dimensions of the generated QR code image
     *   - logo: The logo image to overlay
     *   - logoSize: The size of the logo (defaults to 20% of QR code size)
     *   - correctionLevel: The error correction level (defaults to H for logo overlay)
     * - Returns: A UIImage containing the QR code with logo
     * - Throws: BoardingPassError if generation fails
     *
     * ## Logo Guidelines
     * - Logo should be simple and high contrast
     * - Recommended size: 15-25% of QR code dimensions
     * - Use high error correction (H) for reliable scanning
     * - Ensure logo doesn't cover critical QR code patterns
     *
     * ## Usage Example
     * ```swift
     * let airlineLogo = UIImage(named: "airline_logo")!
     * let brandedQR = try boardingPass.qrCodeWithLogo(
     *     size: CGSize(width: 300, height: 300),
     *     logo: airlineLogo,
     *     logoSize: CGSize(width: 60, height: 60)
     * )
     * ```
     */
    public func qrCodeWithLogo(size: CGSize = CGSize(width: 200, height: 200),
                              logo: UIImage,
                              logoSize: CGSize? = nil,
                              correctionLevel: String = "H") throws -> UIImage {
        let generator = QRCodeGenerator(boardingPassData: code)
        return try generator.generateWithLogo(size: size, 
                                            logo: logo,
                                            logoSize: logoSize,
                                            correctionLevel: correctionLevel)
    }
    
    /**
     * Generates a QR code optimized for printing
     *
     * Creates a high-quality QR code suitable for physical printing on
     * boarding passes, tickets, and other printed materials.
     *
     * - Parameters:
     *   - printSize: The size in points for printing (default: 300x300)
     *   - correctionLevel: The error correction level (default: H for high reliability)
     * - Returns: A high-quality QR code image for printing
     * - Throws: BoardingPassError if generation fails
     *
     * ## Print Optimization Features
     * - High error correction for damage resistance
     * - Optimized size for print resolution
     * - Black and white colors for maximum contrast
     * - Suitable for various print media
     */
    public func qrCodeForPrinting(printSize: CGSize = CGSize(width: 300, height: 300),
                                 correctionLevel: String = "H") throws -> UIImage {
        let generator = QRCodeGenerator(boardingPassData: code)
        return try generator.generateForPrinting(printSize: printSize, correctionLevel: correctionLevel)
    }
    
    /**
     * Generates a QR code optimized for screen display
     *
     * Creates a QR code optimized for display on mobile devices, tablets,
     * and other digital screens.
     *
     * - Parameters:
     *   - displaySize: The size for screen display (default: 150x150)
     *   - correctionLevel: The error correction level (default: M for balanced)
     * - Returns: A QR code optimized for digital display
     * - Throws: BoardingPassError if generation fails
     *
     * ## Display Optimization Features
     * - Balanced error correction for size and reliability
     * - Optimized for screen resolution
     * - Suitable for mobile app integration
     * - Fast generation for real-time display
     */
    public func qrCodeForDisplay(displaySize: CGSize = CGSize(width: 150, height: 150),
                                correctionLevel: String = "M") throws -> UIImage {
        let generator = QRCodeGenerator(boardingPassData: code)
        return try generator.generateForDisplay(displaySize: displaySize, correctionLevel: correctionLevel)
    }
    #endif
    
    // MARK: - QR Code Utilities
    
    #if os(iOS)
    /**
     * Raw QR code data representation
     *
     * Returns the boarding pass data encoded as Data object, useful for
     * custom QR code generation or data processing.
     */
    public var qrCodeData: Data? {
        return code.data(using: .ascii)
    }
    
    /**
     * Calculates optimal QR code size for a display area
     *
     * Determines the best QR code dimensions for a given display area,
     * ensuring proper margins and readability.
     *
     * - Parameter displaySize: The available display dimensions
     * - Parameter margin: The desired margin around the QR code
     * - Returns: The optimal QR code size for the display area
     *
     * ## Usage Example
     * ```swift
     * let availableSize = view.bounds.size
     * let optimalSize = boardingPass.optimalQRCodeSize(for: availableSize, margin: 20)
     * let qrCode = try boardingPass.qrCode(size: optimalSize)
     * ```
     */
    public func optimalQRCodeSize(for displaySize: CGSize, margin: CGFloat = 20) -> CGSize {
        return QRCodeUtilities.optimalSize(for: displaySize, margin: margin)
    }
    
    /**
     * Checks if boarding pass data is suitable for QR code generation
     *
     * Validates that the boarding pass data meets size and format requirements
     * for reliable QR code generation.
     *
     * ## Validation Criteria
     * - Data size within QR code capacity limits
     * - Proper ASCII encoding
     * - Valid boarding pass format
     */
    public var isSuitableForQRCode: Bool {
        return QRCodeUtilities.isStringSuitableForQRCode(code)
    }
    
    /**
     * Recommended error correction level for this boarding pass
     *
     * Automatically determines the optimal error correction level based on
     * the boarding pass data size and intended use case.
     *
     * ## Recommendations
     * - **Low (L)**: Small data, minimal damage risk
     * - **Medium (M)**: Standard data, balanced reliability (default)
     * - **Quartile (Q)**: Larger data, moderate damage risk
     * - **High (H)**: Large data, high damage risk or logo overlay
     */
    public var recommendedErrorCorrectionLevel: QRCodeStyle.CorrectionLevel {
        guard let data = qrCodeData else { return .medium }
        return QRCodeUtilities.recommendedErrorCorrectionLevel(for: data.count)
    }
    
    /**
     * Generates an optimized QR code for the current boarding pass
     *
     * Creates a QR code with automatically determined optimal settings
     * based on the boarding pass data characteristics.
     *
     * - Parameter size: The desired size (uses optimal size if nil)
     * - Returns: An optimized QR code image
     * - Throws: BoardingPassError if generation fails
     */
    public func optimizedQRCode(size: CGSize? = nil) throws -> UIImage {
        let finalSize = size ?? CGSize(width: 200, height: 200)
        let correctionLevel = recommendedErrorCorrectionLevel
        
        return try qrCode(size: finalSize, correctionLevel: correctionLevel.rawValue)
    }
    
    /**
     * Generates a QR code with airline branding colors
     *
     * Creates a branded QR code using the airline's brand colors,
     * maintaining visual consistency with airline applications.
     *
     * - Parameters:
     *   - size: The dimensions of the QR code
     *   - airlineColor: The airline's brand color
     * - Returns: A branded QR code image
     * - Throws: BoardingPassError if generation fails
     */
    public func brandedQRCode(size: CGSize = CGSize(width: 200, height: 200),
                             airlineColor: UIColor) throws -> UIImage {
        let style = QRCodeStyle.airlineBranded(airlineColor: airlineColor)
        return try qrCode(size: size, style: style)
    }
    
    /**
     * Generates a QR code suitable for printing on boarding passes
     *
     * Creates a high-quality QR code optimized for physical printing,
     * with appropriate size and error correction for print media.
     */
    public func printableQRCode(printSize: CGSize = CGSize(width: 300, height: 300)) throws -> UIImage {
        return try qrCodeForPrinting(printSize: printSize)
    }
    
    /**
     * Generates a QR code optimized for mobile app display
     *
     * Creates a QR code sized and configured for optimal display
     * on mobile devices and tablets.
     */
    public func mobileDisplayQRCode(displaySize: CGSize = CGSize(width: 150, height: 150)) throws -> UIImage {
        return try qrCodeForDisplay(displaySize: displaySize)
    }
    #endif
    
    // MARK: - Debug and Development
    
    /**
     * Comprehensive text representation for debugging
     *
     * Prints a detailed, formatted representation of the entire boarding pass
     * to the console, useful for development and debugging purposes.
     *
     * ## Output Format
     * The output includes all parsed fields organized by category:
     * - Mandatory items (60 characters)
     * - Conditional items (variable length)
     * - Segment information (for multi-leg flights)
     * - Security data
     *
     * ## Usage Example
     * ```swift
     * // Enable debug output
     * boardingPass.printout()
     * ```
     */
    public func printout() {
        print("")
        print("SEGMENTS: \(info.legs)")
        print("======================")
        print("MAIN SEGMENT")
        print("===MANDATORY ITEMS [60 characters long]===")
        print("FORMAT CODE:  \(info.format)")
        print("LEGS ENCODED: \(info.legs)")
        print("PASSENGER:    \(info.name)")
        print("INDICATOR:    \(info.ticketIndicator)")
        print("PNR CODE:     \(info.pnrCode)")
        print("ORIGIN:       \(info.origin)")
        print("DESTINATION:  \(info.destination)")
        print("CARRIER:      \(info.operatingCarrier)")
        print("FLIGHT NO:    \(info.flightno)")
        print("JULIAN DATE:  \(info.julianDate)")
        print("COMPARTMENT:  \(info.compartment)")
        print("SEAT NO:      \(info.seatno)")
        print("CHECK IN:     \(info.checkIn)")
        print("STATUS:       \(info.passengerStatus)")
        print("VAR SIZE:     \(info.conditionalSize)")
        print("")
        print("===CONDITIONAL ITEMS [\(info.conditionalSize) characters long]===")
        print("VERSION:       \(version)")
        print("PASS STRUCT:   \(main.structSize)")
        print("PASS DESC:     \(main.passengerDesc)")
        print("SOURCE CHK IN: \(main.checkInSource)")
        print("SOURCE PASS:   \(main.passSource)")
        print("DATE ISSUED:   \(main.dateIssued)")
        print("ISSUED YEAR:   \(main.year == nil ? "none" : "\(main.year ?? 999)")")
        print("ISSUED DAY:    \(main.nthDay == nil ? "none" : "\(main.nthDay ?? 999)")")
        print("DOC TYPE:      \(main.documentType)")
        print("AIRLINE DESIG: \(main.carrier)")
        print("BAG TAG 1:     \(main.bagtag1 ?? "none")")
        print("BAG TAG 2:     \(main.bagtag2 ?? "none")")
        print("BAG TAG 3:     \(main.bagtag3 ?? "none")")
        print("FIELD SIZE:    \(main.nextSize)")
        print("AIRLINE CODE:  \(main.airlineCode)")
        print("TICKET NO:     \(main.ticketNumber)")
        print("SELECTEE:      \(main.selectee)")
        print("INTERNATIONAL: \(main.internationalDoc)")
        print("CARRIER:       \(main.carrier)")
        print("FREQ CARRIER:  \(main.ffCarrier ?? "-")")
        print("FREQ NUMBER:   \(main.ffNumber ?? "-")")
        print("")
        print("AD ID:         \(main.IDADIndicator ?? "-")")
        print("FREE BAGS:     \(main.freeBags ?? "-")")
        print("FAST TRACK:    \(main.fastTrack ?? "-")")
        print("AIRLINE USE:   \(main.airlineUse ?? "-")")
        print("======================")
        for (i, segment) in segments.enumerated() {
            print("SEGMENT: \(i + 2)")
            print("======================")
            print("PNRCODE:       \(segment.pnrCode)")
            print("ORIGIN:        \(segment.origin)")
            print("DESTINATION:   \(segment.destination)")
            print("CARRIER:       \(segment.carrier)")
            print("FLIGHT NO:     \(segment.flightno)")
            print("JULIAN DATE:   \(segment.julianDate)")
            print("COMPARTMENT:   \(segment.compartment)")
            print("SEAT NO:       \(segment.seatno ?? "-")")
            print("CHECKED IN:    \(segment.checkedin)")
            print("PASS STATUS:   \(segment.passengerStatus)")
            print("CONDITIONAL:   \(segment.structSize)")
            print("SEGMENT SIZE:  \(segment.segmentSize)")
            print("AIRLINE CODE:  \(segment.airlineCode)")
            print("DOC NUMBER:    \(segment.ticketNumber)")
            print("SELECTEE:      \(segment.selectee)")
            print("DOC VERIFY:    \(segment.internationalDoc)")
            print("TICKET CARRIER:\(segment.ticketingCarrier)")
            print("FF AIRLINE:    \(segment.ffAirline)")
            print("FF NUMBER:     \(segment.ffNumber)")
            print("ID INDICATOR:  \(segment.idAdIndicator ?? "-")")
            print("FREE BAGS:     \(segment.freeBags ?? "-")")
            print("FAST TRACK:    \(segment.fastTrack ?? "-")")
            print("AIRLINE USE:   \(segment.airlineUse ?? "-")")
            print("========================")
        }
        print("")
        print("SECURITY DATA")
        print("========================")
        print("TYPE:     \(security.securityType)")
        print("LENGTH:   \(security.securitylength)")
        print("TYPE:     \(security.securityType ?? "-")")
        print("LENGTH:   \(security.securitylength ?? -1)")
        print("DATA:     \(security.securityData ?? "-")")
        print("========================")
    }
    
    // MARK: - Sample Data
    
    /**
     * Sample boarding pass codes for testing and development
     *
     * These static properties provide real-world boarding pass examples
     * that can be used for testing, development, and demonstration purposes.
     * Each sample represents different scenarios and data formats.
     */
    
    /// Single-segment domestic flight (American Airlines)
    public static let scan1 = "M1ACKERMANN/JUSTIN    ETDPUPK TPADFWAA 1189 091R003A0033 14A>318   0091BAA 00000000000002900121232782703 AA AA 76UXK84             2IN"
    
    /// Single-segment flight with security data
    public static let scan2 = "M1ACKERMANN/JUSTIN    ELIIBGP CLTTPAAA 1632 136R003A0030 148>218 MM    BAA              29001001212548532AA AA 76UXK84              AKAlfj2mu1aTkVQ5xj83jTf/c5bb+8G61Q==|Wftygjey5EygW2IxQt+9v1+DHuklYFnr"
    
    /// Single-segment flight with different security format
    public static let scan3 = "M1ACKERMANN/JUSTIN    ELIIBGP STLCLTAA 1990 136R003A0026 148>218 MM    BAA              29001001212548532AA AA 76UXK84              ZulMW9ujSJJInrqdwbpy44gCfsK+lwdE|ALqh3u+QhfCfPINi1TMzFFDhCKM7ydqGDg=="
    
    /// International flight (Cathay Pacific)
    public static let scan4 = "M1ACKERMANN/JUSTIN DAVEUXPVFK HKGSINCX 0715 326Y040G0059 34B>6180 O9326BCX              2A00174597371330 AA AA 76UXK84             N3AA"
    
    /// Domestic flight (American Airlines)
    public static let scan5 = "M1ACKERMANN/JUSTIN DAVEJKLEAJ MSYPHXAA 2819 014S008F0059 14A>318   0014BAA 00000000000002900174844256573 AA AA 76UXK84             223"
    
    /// Domestic flight (American Airlines)
    public static let scan6 = "M1ACKERMANN/JUSTIN DAVEQAEWGY SANDFWAA 1765 157K012A0028 14A>318   2157BAA 00000000000002900177636421733 AA AA 76UXK84             253"
    
    /// International flight with security (American Airlines)
    public static let scan7 = "M1FERRER/JOSE          XYJZ2V TPASJUNK 0538 248Y026F0038 147>1181  0247BNK 000000000000029487000000000000                          ^460MEQCIGJLJLMYXzgkks7Z1jWfkW/cZSPFunmpdfrF/s4m40oYAiBjZH1WLm+3olwz+tMC+uBhr2fuS1EXwDg5qxBhge4RMg=="
    
    /// International flight with security (Gulf Air)
    public static let scan8 = "M1PRUETT/KAILEY       E9169f13BLVPIEG4 0769 057Y011C0001 147>3182OO1057BG4              29268000000000000G4                    00PC^160MEUCIFzucrR1+DVpDo0bBTgfSKeynBc0igyZvQ8fLm67nMLdAiEAxNiljXHk9lNdiG4Nd5LYQwMIvWpohaRMp7E7ogYgQy8="
    
    /// Domestic flight (American Airlines)
    public static let scan9 = "M1ACKERMANN/JUSTIN DAVEWHNSNI TPAPHXAA 1466 185R005A0056 14A>318   2185BAA 00000000000002900177708173663 AA AA 76UXK84             243"
    
    /// Multi-segment international flight (American Airlines)
    public static let scan10 = "M2ACKERMANN/JUSTIN DAVEWHFPBW TPASEAAS 0635 213L007A0000 148>2181MM    BAS              25             3    AA 76UXK84         1    WHFPBW SEAJNUAS 0555 213L007A0000 13125             3    AA 76UXK84         1    01010^460MEQCICRNjFGBPfJr84Ma6vMjxTQLtZ1z7uB0tUfO+fS/3vvuAiAReH4kY4ZcmXR+vD8Y+KoA1Dn1YKpr8YxCYbREeOYcsA=="
    
    /// International flight (Japan Airlines)
    public static let scan11 = "M1ACKERMANN/JUSTIN DAVEJPYKJI SINNRTJL 0712 336Y025C0231 348>3180 O9335BJL 01315361700012900174601118720 JL AA 76UXK84             3"
    
    /// Multi-segment international flight (Virgin Atlantic)
    public static let scan12 = "M2FORHETZ/BETHANY     EP2DJMN CDGLHRAF 1780 117Y017C0130 348>5182 O    BAF              2A93223260324620    VS 1091120160          NP2DJMN LHRTPAVS 0129 117W026H0088 32C2A93223260324620    VS 1091120160          N"
    
    /// Multi-segment international flight (Delta Airlines)
    public static let scan13 = "M2ACKERMANN/JUSTIN    EP2DJMN CDGLHRAF 1780 117Y017A0129 348>5181 O    BAF              2A93223260324630    DL 9379805238          NP2DJMN LHRTPAVS 0129 117W026K0087 32C2A93223260324630    DL 9379805238          N"
    
    /// Domestic flight (American Airlines)
    public static let scan14 = "M1FORHETZ/BETHANY     EJNRBUA TPADFWAA 2529 342C014E0099 147>1180OO3342BAA              29             31                          "
    
    // MARK: - Validation Methods
    
    /**
     * Validates a boarding pass code string without creating an instance
     *
     * Performs comprehensive validation of boarding pass data before parsing,
     * allowing early detection of format and data issues.
     *
     * - Parameter code: The boarding pass code string to validate
     * - Returns: Array of validation errors found, empty if valid
     *
     * ## Validation Checks
     * - Format code validation (M/S)
     * - Segment count validation
     * - Field length requirements
     * - Character encoding validation
     * - Data structure integrity
     *
     * ## Usage Example
     * ```swift
     * let errors = BoardingPass.validate(barcodeString)
     * if errors.isEmpty {
     *     let pass = try decoder.decode(code: barcodeString)
     * } else {
     *     print("Validation errors: \(errors)")
     * }
     * ```
     */
    public static func validate(_ code: String) -> [BoardingPassError] {
        return BoardingPassValidator.validateBoardingPass(code)
    }
    
    /**
     * Validates the current boarding pass instance
     *
     * Performs validation on the already parsed boarding pass data,
     * useful for verifying data integrity after parsing.
     *
     * - Returns: Array of validation errors found, empty if valid
     */
    public func validate() -> [BoardingPassError] {
        return BoardingPassValidator.validateBoardingPass(code)
    }
    
    /**
     * Quick validity check for the current boarding pass
     *
     * Returns true if the boarding pass passes all validation checks,
     * false if any validation errors are found.
     */
    public var isValid: Bool {
        return validate().isEmpty
    }
}
