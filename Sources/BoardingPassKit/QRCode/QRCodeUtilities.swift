//
//  QRCodeUtilities.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation
#if os(iOS)
import UIKit
#endif

/// Utility methods for QR code functionality
public struct QRCodeUtilities {
    
    /// Calculates the optimal QR code size for a given display area
    /// - Parameters:
    ///   - displaySize: The available display size
    ///   - margin: The margin around the QR code (default: 20)
    /// - Returns: The optimal QR code size
    public static func optimalSize(for displaySize: CGSize, margin: CGFloat = 20) -> CGSize {
        let availableSize = CGSize(
            width: displaySize.width - (margin * 2),
            height: displaySize.height - (margin * 2)
        )
        
        // QR codes should be square, so use the smaller dimension
        let size = min(availableSize.width, availableSize.height)
        return CGSize(width: size, height: size)
    }
    
    /// Checks if the given data is suitable for QR code generation
    /// - Parameter data: The data to check
    /// - Returns: `true` if suitable, `false` otherwise
    public static func isDataSuitableForQRCode(_ data: Data) -> Bool {
        let dataSize = data.count
        
        // For medium error correction, QR code version 40 can handle up to 2334 bytes
        // Most boarding passes are well under this limit
        return dataSize <= 2000 // Conservative limit
    }
    
    /// Checks if the given string is suitable for QR code generation
    /// - Parameter string: The string to check
    /// - Returns: `true` if suitable, `false` otherwise
    public static func isStringSuitableForQRCode(_ string: String) -> Bool {
        guard let data = string.data(using: .ascii) else { return false }
        return isDataSuitableForQRCode(data)
    }
    
    /// Gets the recommended error correction level for the given data size
    /// - Parameter dataSize: The size of the data in bytes
    /// - Returns: The recommended error correction level
    public static func recommendedErrorCorrectionLevel(for dataSize: Int) -> QRCodeStyle.CorrectionLevel {
        if dataSize <= 100 {
            return .low
        } else if dataSize <= 500 {
            return .medium
        } else if dataSize <= 1000 {
            return .quartile
        } else {
            return .high
        }
    }
    
    /// Calculates the minimum QR code version needed for the given data and error correction
    /// - Parameters:
    ///   - dataSize: The size of the data in bytes
    ///   - errorCorrection: The error correction level
    /// - Returns: The minimum QR code version (1-40)
    public static func minimumQRCodeVersion(for dataSize: Int, errorCorrection: QRCodeStyle.CorrectionLevel) -> Int {
        // This is a simplified calculation. In practice, you'd use the full QR code specification
        let capacityMultiplier: Double
        switch errorCorrection {
        case .low: capacityMultiplier = 1.0
        case .medium: capacityMultiplier = 0.8
        case .quartile: capacityMultiplier = 0.6
        case .high: capacityMultiplier = 0.5
        }
        
        let requiredCapacity = Double(dataSize) / capacityMultiplier
        
        // Rough estimation: each version adds about 8 bytes of capacity
        let estimatedVersion = Int(ceil(requiredCapacity / 8.0))
        return max(1, min(40, estimatedVersion))
    }
    
    /// Validates QR code dimensions
    /// - Parameter size: The size to validate
    /// - Returns: `true` if valid, `false` otherwise
    public static func isValidSize(_ size: CGSize) -> Bool {
        return size.width > 0 && size.height > 0 && 
               size.width <= 1000 && size.height <= 1000 // Reasonable upper limit
    }
    
    /// Calculates the optimal margin for a QR code based on its size
    /// - Parameter qrCodeSize: The size of the QR code
    /// - Returns: The recommended margin
    public static func optimalMargin(for qrCodeSize: CGSize) -> CGFloat {
        let minSize = min(qrCodeSize.width, qrCodeSize.height)
        return max(10, minSize * 0.1) // 10% of size, minimum 10 points
    }
    
    /// Calculates the optimal logo size for a QR code
    /// - Parameter qrCodeSize: The size of the QR code
    /// - Parameter errorCorrection: The error correction level
    /// - Returns: The recommended logo size
    public static func optimalLogoSize(for qrCodeSize: CGSize, errorCorrection: QRCodeStyle.CorrectionLevel) -> CGSize {
        let minSize = min(qrCodeSize.width, qrCodeSize.height)
        let maxLogoPercentage: CGFloat
        
        switch errorCorrection {
        case .low: maxLogoPercentage = 0.15
        case .medium: maxLogoPercentage = 0.20
        case .quartile: maxLogoPercentage = 0.25
        case .high: maxLogoPercentage = 0.30
        }
        
        let logoSize = minSize * maxLogoPercentage
        return CGSize(width: logoSize, height: logoSize)
    }
    
    /// Checks if the current device supports QR code generation
    /// - Returns: `true` if supported, `false` otherwise
    public static var isQRCodeGenerationSupported: Bool {
        #if os(iOS)
        return CIFilter(name: "CIQRCodeGenerator") != nil
        #else
        return false
        #endif
    }
    
    /// Gets the maximum supported QR code version on the current device
    /// - Returns: The maximum supported version (typically 40)
    public static var maxSupportedQRCodeVersion: Int {
        // Most modern devices support version 40
        // This could be made dynamic by testing actual generation
        return 40
    }
    
    /// Calculates the estimated file size of a generated QR code image
    /// - Parameters:
    ///   - qrCodeSize: The size of the QR code
    ///   - scale: The scale factor (default: 1.0)
    ///   - format: The image format (default: PNG)
    /// - Returns: Estimated file size in bytes
    public static func estimatedFileSize(qrCodeSize: CGSize, scale: CGFloat = 1.0, format: ImageFormat = .png) -> Int {
        let pixelCount = Int(qrCodeSize.width * qrCodeSize.height * scale * scale)
        
        switch format {
        case .png:
            // PNG is lossless, estimate based on complexity
            return pixelCount * 4 // 4 bytes per pixel (RGBA)
        case .jpeg:
            // JPEG is lossy, estimate based on quality
            return pixelCount * 3 // 3 bytes per pixel (RGB)
        }
    }
    
    /// Image format for QR code export
    public enum ImageFormat {
        case png
        case jpeg
    }
}

// MARK: - QR Code Validation

extension QRCodeUtilities {
    
    /// Validates a complete QR code configuration
    /// - Parameters:
    ///   - size: The QR code size
    ///   - data: The data to encode
    ///   - errorCorrection: The error correction level
    /// - Returns: Array of validation errors
    public static func validateConfiguration(size: CGSize, data: Data, errorCorrection: QRCodeStyle.CorrectionLevel) -> [String] {
        var errors: [String] = []
        
        if !isValidSize(size) {
            errors.append("Invalid QR code size: \(size)")
        }
        
        if !isDataSuitableForQRCode(data) {
            errors.append("Data too large for QR code: \(data.count) bytes")
        }
        
        let minVersion = minimumQRCodeVersion(for: data.count, errorCorrection: errorCorrection)
        if minVersion > maxSupportedQRCodeVersion {
            errors.append("Data requires QR code version \(minVersion), but device only supports up to \(maxSupportedQRCodeVersion)")
        }
        
        return errors
    }
    
    /// Validates a QR code style configuration
    /// - Parameter style: The style to validate
    /// - Returns: Array of validation errors
    public static func validateStyle(_ style: QRCodeStyle) -> [String] {
        var errors: [String] = []
        
        if style.cornerRadius < 0 {
            errors.append("Corner radius cannot be negative")
        }
        
        if style.cornerRadius > 0 && style.cornerRadius > 50 {
            errors.append("Corner radius too large: \(style.cornerRadius)")
        }
        
        if style.shadowRadius < 0 {
            errors.append("Shadow radius cannot be negative")
        }
        
        if style.shadowOpacity < 0 || style.shadowOpacity > 1 {
            errors.append("Shadow opacity must be between 0 and 1")
        }
        
        return errors
    }
}
