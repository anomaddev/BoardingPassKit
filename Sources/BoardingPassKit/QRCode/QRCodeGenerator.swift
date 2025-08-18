//
//  QRCodeGenerator.swift
//  
//
//  Created by Justin Ackermann on 7/9/23.
//

import Foundation
#if os(iOS)
import UIKit
import CoreImage
#endif

/// A utility class for generating QR codes from boarding pass data
public class QRCodeGenerator {
    
    /// The boarding pass data to encode
    private let boardingPassData: String
    
    /// Creates a new QR code generator with boarding pass data
    /// - Parameter boardingPassData: The boarding pass data string to encode
    public init(boardingPassData: String) {
        self.boardingPassData = boardingPassData
    }
    
    #if os(iOS)
    /// Generates a basic QR code image
    ///
    /// - Parameters:
    ///   - size: The size of the QR code image (default: 200x200)
    ///   - correctionLevel: The error correction level (default: M)
    /// - Returns: QR code in the format of a `UIImage`
    /// - Throws: Throws a `BoardingPassError` if the `UIImage` creation fails
    ///
    public func generate(size: CGSize = CGSize(width: 200, height: 200), 
                        correctionLevel: String = "M") throws -> UIImage {
        let data = boardingPassData.data(using: String.Encoding.ascii)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw BoardingPassError.CIQRCodeGeneratorNotFound
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        guard let output = filter.outputImage else {
            throw BoardingPassError.CIQRCodeGeneratorOutputFailed
        }
        
        let transform = CGAffineTransform(scaleX: size.width / output.extent.width,
                                        y: size.height / output.extent.height)
        
        let scaledOutput = output.transformed(by: transform)
        return UIImage(ciImage: scaledOutput)
    }
    
    /// Generates a QR code with custom styling options
    ///
    /// - Parameters:
    ///   - size: The size of the QR code image
    ///   - correctionLevel: The error correction level (L, M, Q, H)
    ///   - foregroundColor: The color of the QR code (default: black)
    ///   - backgroundColor: The background color (default: white)
    /// - Returns: Styled QR code image
    /// - Throws: BoardingPassError if generation fails
    public func generate(size: CGSize = CGSize(width: 200, height: 200),
                        correctionLevel: String = "M",
                        foregroundColor: UIColor = .black,
                        backgroundColor: UIColor = .white) throws -> UIImage {
        let data = boardingPassData.data(using: String.Encoding.ascii)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw BoardingPassError.CIQRCodeGeneratorNotFound
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        guard let output = filter.outputImage else {
            throw BoardingPassError.CIQRCodeGeneratorOutputFailed
        }
        
        // Apply color filters
        let colorFilter = CIFilter(name: "CIFalseColor")
        colorFilter?.setValue(output, forKey: "inputImage")
        colorFilter?.setValue(CIColor(color: foregroundColor), forKey: "inputColor0")
        colorFilter?.setValue(CIColor(color: backgroundColor), forKey: "inputColor1")
        
        guard let coloredOutput = colorFilter?.outputImage else {
            throw BoardingPassError.CIQRCodeGeneratorOutputFailed
        }
        
        // Scale to desired size
        let transform = CGAffineTransform(scaleX: size.width / coloredOutput.extent.width,
                                        y: size.height / coloredOutput.extent.height)
        
        let scaledOutput = coloredOutput.transformed(by: transform)
        return UIImage(ciImage: scaledOutput)
    }
    
    /// Generates a QR code with custom styling
    ///
    /// - Parameters:
    ///   - size: The size of the QR code image
    ///   - style: The QR code style configuration
    /// - Returns: Styled QR code image
    /// - Throws: BoardingPassError if generation fails
    public func generate(size: CGSize = CGSize(width: 200, height: 200),
                        style: QRCodeStyle) throws -> UIImage {
        let data = boardingPassData.data(using: String.Encoding.ascii)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw BoardingPassError.CIQRCodeGeneratorNotFound
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(style.correctionLevel, forKey: "inputCorrectionLevel")
        
        guard let output = filter.outputImage else {
            throw BoardingPassError.CIQRCodeGeneratorOutputFailed
        }
        
        // Apply color filters
        let colorFilter = CIFilter(name: "CIFalseColor")
        colorFilter?.setValue(output, forKey: "inputImage")
        colorFilter?.setValue(CIColor(color: style.foregroundColor), forKey: "inputColor0")
        colorFilter?.setValue(CIColor(color: style.backgroundColor), forKey: "inputColor1")
        
        guard let coloredOutput = colorFilter?.outputImage else {
            throw BoardingPassError.CIQRCodeGeneratorOutputFailed
        }
        
        // Scale to desired size
        let transform = CGAffineTransform(scaleX: size.width / coloredOutput.extent.width,
                                        y: size.height / coloredOutput.extent.height)
        
        let scaledOutput = coloredOutput.transformed(by: transform)
        
        // Apply additional styling if needed
        if style.cornerRadius > 0 {
            let roundedFilter = CIFilter(name: "CIRoundedRectangleGenerator")
            roundedFilter?.setValue(scaledOutput, forKey: "inputImage")
            roundedFilter?.setValue(style.cornerRadius, forKey: "inputRadius")
            
            if let roundedOutput = roundedFilter?.outputImage {
                return UIImage(ciImage: roundedOutput)
            }
        }
        
        return UIImage(ciImage: scaledOutput)
    }
    
    /// Generates a QR code with a logo overlay in the center
    ///
    /// - Parameters:
    ///   - size: The size of the QR code image
    ///   - logo: The logo image to overlay
    ///   - logoSize: The size of the logo (default: 20% of QR code size)
    ///   - correctionLevel: The error correction level (default: H for logo overlay)
    /// - Returns: QR code with logo overlay
    /// - Throws: BoardingPassError if generation fails
    public func generateWithLogo(size: CGSize = CGSize(width: 200, height: 200),
                                logo: UIImage,
                                logoSize: CGSize? = nil,
                                correctionLevel: String = "H") throws -> UIImage {
        // Generate base QR code with high error correction for logo overlay
        let baseQRCode = try generate(size: size, correctionLevel: correctionLevel)
        
        let finalLogoSize = logoSize ?? CGSize(width: size.width * 0.2, height: size.height * 0.2)
        
        // Create graphics context
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            throw BoardingPassError.CIQRCodeGeneratorOutputFailed
        }
        
        // Draw QR code
        baseQRCode.draw(in: CGRect(origin: .zero, size: size))
        
        // Calculate logo position (center)
        let logoX = (size.width - finalLogoSize.width) / 2
        let logoY = (size.height - finalLogoSize.height) / 2
        let logoRect = CGRect(x: logoX, y: logoY, width: finalLogoSize.width, height: finalLogoSize.height)
        
        // Draw logo with rounded corners
        context.saveGState()
        let logoPath = UIBezierPath(roundedRect: logoRect, cornerRadius: finalLogoSize.width * 0.1)
        logoPath.addClip()
        logo.draw(in: logoRect)
        context.restoreGState()
        
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else {
            throw BoardingPassError.CIQRCodeGeneratorOutputFailed
        }
        
        return result
    }
    
    // MARK: - Convenience Methods
    
    /// Generates a QR code optimized for printing
    ///
    /// - Parameters:
    ///   - printSize: The size in points for printing (default: 300x300)
    ///   - correctionLevel: The error correction level (default: H for high reliability)
    /// - Returns: High-quality QR code suitable for printing
    /// - Throws: BoardingPassError if generation fails
    public func generateForPrinting(printSize: CGSize = CGSize(width: 300, height: 300),
                                   correctionLevel: String = "H") throws -> UIImage {
        return try generate(size: printSize, correctionLevel: correctionLevel)
    }
    
    /// Generates a QR code optimized for display on screens
    ///
    /// - Parameters:
    ///   - displaySize: The size for screen display (default: 150x150)
    ///   - correctionLevel: The error correction level (default: M for balanced)
    /// - Returns: QR code optimized for screen display
    /// - Throws: BoardingPassError if generation fails
    public func generateForDisplay(displaySize: CGSize = CGSize(width: 150, height: 150),
                                  correctionLevel: String = "M") throws -> UIImage {
        return try generate(size: displaySize, correctionLevel: correctionLevel)
    }
    
    /// Generates a QR code with airline branding colors
    ///
    /// - Parameters:
    ///   - size: The size of the QR code
    ///   - airlineColor: The airline's brand color
    /// - Returns: A branded QR code image
    /// - Throws: BoardingPassError if generation fails
    public func generateBranded(size: CGSize = CGSize(width: 200, height: 200),
                               airlineColor: UIColor) throws -> UIImage {
        let style = QRCodeStyle.airlineBranded(airlineColor: airlineColor)
        return try generate(size: size, style: style)
    }
    #endif
}
