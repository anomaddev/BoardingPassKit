//
//  BoardingPassQRExtractor.swift
//
//  Reads a QR payload from PNG, JPEG, or HEIC image data.
//

import CoreGraphics
import Foundation
import ImageIO
import Vision

#if os(iOS)
import UIKit
#endif

public enum BoardingPassQRExtractor {

    /// Extract the first QR payload from PNG, JPEG, or HEIC bytes.
    public static func payload(from imageData: Data) throws -> String {
        try validateImageFormat(imageData)
        guard
            let source = CGImageSourceCreateWithData(imageData as CFData, nil),
            let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw BoardingPassError.ImageDecodeFailed
        }
        return try payload(from: cgImage)
    }

    /// Extract the first QR payload from a `CGImage`.
    public static func payload(from image: CGImage) throws -> String {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw BoardingPassError.ImageDecodeFailed
        }

        guard let results = request.results else {
            throw BoardingPassError.QRCodeNotFound
        }
        for result in results {
            if let value = result.payloadStringValue, !value.isEmpty {
                return value
            }
        }
        throw BoardingPassError.QRCodeNotFound
    }

    #if os(iOS)
    /// Extract the first QR payload from a `UIImage`.
    public static func payload(from image: UIImage) throws -> String {
        guard let cgImage = image.cgImage else {
            throw BoardingPassError.ImageDecodeFailed
        }
        return try payload(from: cgImage)
    }
    #endif

    private static func validateImageFormat(_ data: Data) throws {
        let bytes = [UInt8](data.prefix(16))
        if bytes.count >= 8 &&
            bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 &&
            bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A {
            return
        }
        if bytes.count >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return
        }
        if isHeif(data) {
            return
        }
        throw BoardingPassError.UnsupportedImageFormat
    }

    private static func isHeif(_ data: Data) -> Bool {
        guard data.count >= 12 else { return false }
        let ftyp = data.subdata(in: 4..<8)
        guard String(data: ftyp, encoding: .ascii) == "ftyp" else { return false }
        if heifBrand(String(data: data.subdata(in: 8..<12), encoding: .ascii) ?? "") {
            return true
        }
        guard data.count >= 16 else { return false }
        let sizeBytes = [UInt8](data.prefix(4))
        let boxSize = Int(sizeBytes[0]) << 24 | Int(sizeBytes[1]) << 16 | Int(sizeBytes[2]) << 8 | Int(sizeBytes[3])
        let end = min(boxSize, data.count)
        var offset = 16
        while offset + 4 <= end {
            let brand = String(data: data.subdata(in: offset..<(offset + 4)), encoding: .ascii) ?? ""
            if heifBrand(brand) {
                return true
            }
            offset += 4
        }
        return false
    }

    private static func heifBrand(_ brand: String) -> Bool {
        ["heic", "heix", "heif", "hevc", "hevx", "mif1", "msf1"].contains(brand)
    }
}
