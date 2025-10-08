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

public struct BoardingPass: Codable {
    
    /// The IATA BCBP format (single character at the start of the Boarding Pass)
    /// This is either M or S. S was deprecated in 2007 and is no longer used.
    public var format: String
    
    /// Number of legs in Boarding Pass
    public var numberOfLegs: Int
    
    /// Passenger Name (20 chars long always)
    public var passengerName: String
    
    /// Electronic ticket Indicator. This is typically E or blank.
    ///
    /// If this field is blank, we have a non-standard ticket.
    public var ticketIndicator: String
    
    /// Boarding Pass Legs
    public var boardingPassLegs: [BoardingPassLeg]
    
    /// Information about the Boarding Pass
    public var passInfo: BoardingPassInfo
    
    /// Boarding Pass security data
    public var securityData: BoardingPassSecurityData?
    
    /// Airline Blob Data
    public var airlineBlob: String?
    
    /// The original string of the scanned Boarding Pass
    public let code: String
    
    #if os(iOS)
    /// Generates a QR representation of the boarding pass code
    ///
    /// - returns: QR code in the format of a `UIImage`
    /// - throws: Throws a `BoardingPassError` if the `UIImage` creation fails
    ///
    public func qrCode() throws -> UIImage {
        let data = code.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            } else { throw NSError() }
        } else { throw NSError() }
    }
    #endif
    
    /// A text representation of the entire `BoardingPass` object printed to the console
    public func printout() {
        print("""
        🛫 Boarding Pass 
        =======HEADER DATA======
        Format:             \(format)
        Number of Legs:     \(numberOfLegs)
        Passenger:          \(passengerName)
        Ticket Indicator:   \(ticketIndicator)
        
        """)
        
        passInfo.printout()
        for leg in boardingPassLegs { leg.printout() }
        
        print("🛫 Boarding Security Data & Airline Blobs")
        securityData?.printout()
        print("Airline Blob:       \(airlineBlob ?? "N/A")")
        print()
    }
    
    /// Demo Data used for testing
    public enum DemoData: String, CaseIterable {
        
        /// A simple example of a boarding pass scan
        case Simple
        
        /// An example of a boarding pass from a really old flight
        case Historical
        
        /// An example of a Multi-Leg Boarding Pass
        case MultiLeg
        
        /// Github Issues
        case GithubIssue
        
        /// A `String` representation of the selected DemoData
        public var string: String {
            switch self {
            case .Simple:
                return "M1ACKERMANN/JUSTIN DAVEJKLEAJ MSYPHXAA 2819 014S008F0059 14A>318   0014BAA 00000000000002900174844256573 AA AA 76UXK84             223"
                
            case .Historical:
                return "M1ACKERMANN/JUSTIN    ETDPUPK TPADFWAA 1189 091R003A0033 14A>318   0091BAA 00000000000002900121232782703 AA AA 76UXK84             2IN"
                
            case .MultiLeg:
                return "M2ACKERMANN/JUSTIN DAVEWHFPBW TPASEAAS 0635 213L007A0000 148>2181MM    BAS              25             3    AA 76UXK84         1    WHFPBW SEAJNUAS 0555 213L007A0000 13125             3    AA 76UXK84         1    01010^460MEQCICRNjFGBPfJr84Ma6vMjxTQLtZ1z7uB0tUfO+fS/3vvuAiAReH4kY4ZcmXR+vD8Y+KoA1Dn1YKpr8YxCYbREeOYcsA=="
                
            case .GithubIssue:
                return "M2DOEDOED/JOHNJOH     ENBVZS7 ORYMRSAF 6000 151Y021A0106 336>60B        KL 2505760840335640    KL 5193929192      NBVZS7 MRSORYAF 6009 151Y021F0040 3272505760840335640    KL 5193929192      "
            
            }
        }
        
        /// A `Data` representation of the selected DemoData
        public var data: Data?
        { return self.string.data(using: .utf8) }
    }
}
