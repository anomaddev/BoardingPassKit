//
//  BoardingPassParser.swift
//  
//
//  Created by Justin Ackermann on 11/29/22.
//

import UIKit
import AVFoundation

public class BoardingPassParser {
    
    public static func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
    
    var index: Int = 0
    let data: Data
    
    public init(data: Data) {
        self.data = data
    }
    
    public func raw() throws -> String {
        guard let str = String(data: data, encoding: String.Encoding.ascii) else {
            throw NSError() // THROW:
        }
        return str
    }
    
    public func skip(_ length: Int) { index += length }
    
    public func readhex(_ length: Int) throws -> Int {
        do {
            guard let str = try getstring(length, mandatory: true)
            else { throw NSError() } // THROW:
            
            guard let int = Int(str, radix: 16)
            else { throw NSError() } // THROW:
            return int
        } catch { throw error }
    }
    
    public func getstring(_ length: Int, mandatory: Bool! = false) throws -> String? {
        do {
            guard let data = try subsection(length, mandatory: mandatory) else {
                if mandatory { throw NSError() } // THROW:
                else { return nil }
            }
            
            guard let rawString = String(data: data, encoding: String.Encoding.ascii) else {
                throw NSError() // THROW:
            }
            let trimmedString = rawString.trimmingCharacters(in: CharacterSet.whitespaces)
            return trimmedString.count == 0 ? nil : trimmedString
        } catch { throw error }
    }
    
    public func subsection(_ length: Int, mandatory: Bool! = false) throws -> Data? {
        if (data.count < index + length) {
            if mandatory { throw NSError() } // THROW:
            else { return nil }
        }
        let subdata = data.subdata(in: index ..< (index + length))
        index += length
        return subdata
    }
    
    public func subparser(_ length: Int) throws -> BoardingPassParser {
        do { let sub = try subsection(length, mandatory: true); return BoardingPassParser(data: sub!) }
        catch { throw error }
    }
    
    public func securityData(_ flag: String! = "^") throws -> SecurityData? {
        guard let rawString = String(data: data, encoding: String.Encoding.ascii),
              let split = rawString
                .split(separator: " ")
                .last?
                .trimmingCharacters(in: CharacterSet.whitespaces),
              let data = split.data(using: .ascii)
        else { throw NSError() } // THROW:
        return try SecurityData(data: data)
    }
}

public extension String {
    func number() throws -> Int {
        guard let number = Int(self) else {
            throw NSError() // THROW:
        }
        return number
    }
    
    func eTicket() throws -> Bool {
        return self == "E"
    }
    
    func bool() throws -> Bool {
        if self == "Y" { return true }
        else if self == "N" { return false }
        else {
            guard let boolean = Bool(self) else {
                throw NSError() // THROW:
            }
            return boolean
        }
    }
}
