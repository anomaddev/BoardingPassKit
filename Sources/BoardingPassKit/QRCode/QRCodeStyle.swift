//
//  QRCodeStyle.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation
#if os(iOS)
import UIKit
#endif

/// Configuration options for QR code generation
public struct QRCodeStyle {
    
    /// The error correction level for the QR code
    public enum CorrectionLevel: String, CaseIterable {
        /// Low error correction (7% recovery)
        case low = "L"
        /// Medium error correction (15% recovery) - Default
        case medium = "M"
        /// Quartile error correction (25% recovery)
        case quartile = "Q"
        /// High error correction (30% recovery)
        case high = "H"
        
        /// The percentage of data that can be recovered if damaged
        public var recoveryPercentage: Int {
            switch self {
            case .low: return 7
            case .medium: return 15
            case .quartile: return 25
            case .high: return 30
            }
        }
        
        /// Description of the error correction level
        public var description: String {
            switch self {
            case .low: return "Low (7% recovery)"
            case .medium: return "Medium (15% recovery)"
            case .quartile: return "Quartile (25% recovery)"
            case .high: return "High (30% recovery)"
            }
        }
    }
    
    #if os(iOS)
    /// The foreground color of the QR code (default: black)
    public var foregroundColor: UIColor
    
    /// The background color of the QR code (default: white)
    public var backgroundColor: UIColor
    
    /// The shadow color (default: black with 0.3 alpha)
    public var shadowColor: UIColor
    #else
    /// The foreground color of the QR code (default: black)
    public var foregroundColor: String
    
    /// The background color of the QR code (default: white)
    public var backgroundColor: String
    
    /// The shadow color (default: black with 0.3 alpha)
    public var shadowColor: String
    #endif
    
    /// The error correction level (default: medium)
    public var correctionLevel: String
    
    /// The corner radius for rounded corners (default: 0 - no rounding)
    public var cornerRadius: CGFloat
    
    /// Whether to add a subtle shadow (default: false)
    public var addShadow: Bool
    
    /// The shadow offset (default: CGSize(width: 2, height: 2))
    public var shadowOffset: CGSize
    
    /// The shadow radius (default: 4.0)
    public var shadowRadius: CGFloat
    
    /// The shadow opacity (default: 0.3)
    public var shadowOpacity: Float
    
    /// Creates a new QR code style with default values
    public init() {
        #if os(iOS)
        self.foregroundColor = .black
        self.backgroundColor = .white
        self.shadowColor = .black
        #else
        self.foregroundColor = "black"
        self.backgroundColor = "white"
        self.shadowColor = "black"
        #endif
        self.correctionLevel = CorrectionLevel.medium.rawValue
        self.cornerRadius = 0
        self.addShadow = false
        self.shadowOffset = CGSize(width: 2, height: 2)
        self.shadowRadius = 4.0
        self.shadowOpacity = 0.3
    }
    
    /// Creates a new QR code style with custom values
    /// - Parameters:
    ///   - foregroundColor: The foreground color
    ///   - backgroundColor: The background color
    ///   - correctionLevel: The error correction level
    ///   - cornerRadius: The corner radius for rounded corners
    ///   - addShadow: Whether to add a shadow
    ///   - shadowColor: The shadow color
    ///   - shadowOffset: The shadow offset
    ///   - shadowRadius: The shadow radius
    ///   - shadowOpacity: The shadow opacity
    public init(foregroundColor: Any,
                backgroundColor: Any,
                correctionLevel: CorrectionLevel = .medium,
                cornerRadius: CGFloat = 0,
                addShadow: Bool = false,
                shadowColor: Any,
                shadowOffset: CGSize = CGSize(width: 2, height: 2),
                shadowRadius: CGFloat = 4.0,
                shadowOpacity: Float = 0.3) {
        #if os(iOS)
        if let fgColor = foregroundColor as? UIColor {
            self.foregroundColor = fgColor
        } else {
            self.foregroundColor = .black
        }
        if let bgColor = backgroundColor as? UIColor {
            self.backgroundColor = bgColor
        } else {
            self.backgroundColor = .white
        }
        if let shColor = shadowColor as? UIColor {
            self.shadowColor = shColor
        } else {
            self.shadowColor = .black
        }
        #else
        if let fgColor = foregroundColor as? String {
            self.foregroundColor = fgColor
        } else {
            self.foregroundColor = "black"
        }
        if let bgColor = backgroundColor as? String {
            self.backgroundColor = bgColor
        } else {
            self.backgroundColor = "white"
        }
        if let shColor = shadowColor as? String {
            self.shadowColor = shColor
        } else {
            self.shadowColor = "black"
        }
        #endif
        self.correctionLevel = correctionLevel.rawValue
        self.cornerRadius = cornerRadius
        self.addShadow = addShadow
        self.shadowOffset = shadowOffset
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
    }
    
    /// Creates a QR code style optimized for printing
    /// - Returns: A style with high error correction and black/white colors
    public static func printing() -> QRCodeStyle {
        #if os(iOS)
        return QRCodeStyle(
            foregroundColor: UIColor.black,
            backgroundColor: UIColor.white,
            correctionLevel: .high,
            cornerRadius: 0,
            addShadow: false,
            shadowColor: UIColor.black
        )
        #else
        return QRCodeStyle(
            foregroundColor: "black",
            backgroundColor: "white",
            correctionLevel: .high,
            cornerRadius: 0,
            addShadow: false,
            shadowColor: "black"
        )
        #endif
    }
    
    /// Creates a QR code style optimized for display
    /// - Returns: A style with medium error correction and black/white colors
    public static func display() -> QRCodeStyle {
        #if os(iOS)
        return QRCodeStyle(
            foregroundColor: UIColor.black,
            backgroundColor: UIColor.white,
            correctionLevel: .medium,
            cornerRadius: 0,
            addShadow: false,
            shadowColor: UIColor.black
        )
        #else
        return QRCodeStyle(
            foregroundColor: "black",
            backgroundColor: "white",
            correctionLevel: .medium,
            cornerRadius: 0,
            addShadow: false,
            shadowColor: "black"
        )
        #endif
    }
    
    /// Creates a QR code style with custom colors
    /// - Parameters:
    ///   - foregroundColor: The foreground color
    ///   - backgroundColor: The background color
    /// - Returns: A style with custom colors and medium error correction
    public static func custom(foregroundColor: Any, backgroundColor: Any) -> QRCodeStyle {
        return QRCodeStyle(
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            correctionLevel: .medium,
            shadowColor: foregroundColor
        )
    }
    
    /// Creates a QR code style with rounded corners
    /// - Parameter cornerRadius: The corner radius
    /// - Returns: A style with rounded corners
    public static func rounded(cornerRadius: CGFloat) -> QRCodeStyle {
        #if os(iOS)
        return QRCodeStyle(
            foregroundColor: UIColor.black,
            backgroundColor: UIColor.white,
            correctionLevel: .medium,
            cornerRadius: cornerRadius,
            shadowColor: UIColor.black
        )
        #else
        return QRCodeStyle(
            foregroundColor: "black",
            backgroundColor: "white",
            correctionLevel: .medium,
            cornerRadius: cornerRadius,
            shadowColor: "black"
        )
        #endif
    }
    
    /// Creates a QR code style with a shadow
    /// - Returns: A style with a subtle shadow
    public static func withShadow() -> QRCodeStyle {
        #if os(iOS)
        return QRCodeStyle(
            foregroundColor: UIColor.black,
            backgroundColor: UIColor.white,
            correctionLevel: .medium,
            addShadow: true,
            shadowColor: UIColor.black
        )
        #else
        return QRCodeStyle(
            foregroundColor: "black",
            backgroundColor: "white",
            correctionLevel: .medium,
            addShadow: true,
            shadowColor: "black"
        )
        #endif
    }
    
    /// Creates a QR code style for dark mode
    /// - Returns: A style with white foreground and dark background
    public static func darkMode() -> QRCodeStyle {
        #if os(iOS)
        return QRCodeStyle(
            foregroundColor: UIColor.white,
            backgroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0),
            correctionLevel: .medium,
            shadowColor: UIColor.white
        )
        #else
        return QRCodeStyle(
            foregroundColor: "white",
            backgroundColor: "dark",
            correctionLevel: .medium,
            shadowColor: "white"
        )
        #endif
    }
    
    /// Creates a QR code style for airline branding
    /// - Parameter airlineColor: The airline's brand color
    /// - Returns: A style with airline branding colors
    public static func airlineBranded(airlineColor: Any) -> QRCodeStyle {
        #if os(iOS)
        return QRCodeStyle(
            foregroundColor: airlineColor,
            backgroundColor: UIColor.white,
            correctionLevel: .medium,
            shadowColor: airlineColor
        )
        #else
        return QRCodeStyle(
            foregroundColor: airlineColor,
            backgroundColor: "white",
            correctionLevel: .medium,
            shadowColor: airlineColor
        )
        #endif
    }
}

// MARK: - Convenience Extensions

extension QRCodeStyle {
    
    /// Creates a copy of the current style with updated values
    /// - Parameter updates: A closure to modify the style
    /// - Returns: A new style with the updated values
    public func updating(_ updates: (inout QRCodeStyle) -> Void) -> QRCodeStyle {
        var copy = self
        updates(&copy)
        return copy
    }
    
    /// Creates a copy with a different foreground color
    /// - Parameter color: The new foreground color
    /// - Returns: A new style with the updated foreground color
    public func withForegroundColor(_ color: Any) -> QRCodeStyle {
        return updating { style in
            #if os(iOS)
            if let uiColor = color as? UIColor {
                style.foregroundColor = uiColor
            }
            #else
            if let stringColor = color as? String {
                style.foregroundColor = stringColor
            }
            #endif
        }
    }
    
    /// Creates a copy with a different background color
    /// - Parameter color: The new background color
    /// - Returns: A new style with the updated background color
    public func withBackgroundColor(_ color: Any) -> QRCodeStyle {
        return updating { style in
            #if os(iOS)
            if let uiColor = color as? UIColor {
                style.backgroundColor = uiColor
            }
            #else
            if let stringColor = color as? String {
                style.backgroundColor = stringColor
            }
            #endif
        }
    }
    
    /// Creates a copy with a different error correction level
    /// - Parameter level: The new error correction level
    /// - Returns: A new style with the updated error correction level
    public func withCorrectionLevel(_ level: CorrectionLevel) -> QRCodeStyle {
        return updating { $0.correctionLevel = level.rawValue }
    }
    
    /// Creates a copy with rounded corners
    /// - Parameter radius: The corner radius
    /// - Returns: A new style with rounded corners
    public func withRoundedCorners(_ radius: CGFloat) -> QRCodeStyle {
        return updating { $0.cornerRadius = radius }
    }
    
    /// Creates a copy with a shadow
    /// - Returns: A new style with a shadow
    public func withShadow() -> QRCodeStyle {
        return updating { $0.addShadow = true }
    }
}
