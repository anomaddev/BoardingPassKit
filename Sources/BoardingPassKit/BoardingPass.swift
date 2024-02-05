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
    
    /// The IATA BCBP version number
    public let version: String
    
    /// The parent object contains the information that is shared between all segments of the boarding pass.
    public var info: BoardingPassParent
    
    /// The main segment of the boarding pass.
    public var main: BoardingPassMainSegment
    
    /// The segments of the boarding pass. This will be empty if there is only one segment.
    public var segments: [BoardingPassSegment]
    
    /// The Boarding Pass security data used by the airline
    public var security: BoardingPassSecurityData
    
    /// The original `String` that was used to create the boarding pass
    public var code: String
    
    public var nameSegments: [String] {
        return info.name
            .split(separator: "/")
            .map { $0.split(separator: " ") }
            .reduce([], +)
            .map { String($0).lowercased() }
    }
    
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
    
    public static let scan1 = "M1ACKERMANN/JUSTIN    ETDPUPK TPADFWAA 1189 091R003A0033 14A>318   0091BAA 00000000000002900121232782703 AA AA 76UXK84             2IN"
    public static let scan2 = "M1ACKERMANN/JUSTIN    ELIIBGP CLTTPAAA 1632 136R003A0030 148>218 MM    BAA              29001001212548532AA AA 76UXK84              AKAlfj2mu1aTkVQ5xj83jTf/c5bb+8G61Q==|Wftygjey5EygW2IxQt+9v1+DHuklYFnr"
    public static let scan3 = "M1ACKERMANN/JUSTIN    ELIIBGP STLCLTAA 1990 136R003A0026 148>218 MM    BAA              29001001212548532AA AA 76UXK84              ZulMW9ujSJJInrqdwbpy44gCfsK+lwdE|ALqh3u+QhfCfPINi1TMzFFDhCKM7ydqGDg=="
    public static let scan4 = "M1ACKERMANN/JUSTIN DAVEUXPVFK HKGSINCX 0715 326Y040G0059 34B>6180 O9326BCX              2A00174597371330 AA AA 76UXK84             N3AA"
    public static let scan5 = "M1ACKERMANN/JUSTIN DAVEJKLEAJ MSYPHXAA 2819 014S008F0059 14A>318   0014BAA 00000000000002900174844256573 AA AA 76UXK84             223"
    public static let scan6 = "M1ACKERMANN/JUSTIN DAVEQAEWGY SANDFWAA 1765 157K012A0028 14A>318   2157BAA 00000000000002900177636421733 AA AA 76UXK84             253"
    public static let scan7 = "M1FERRER/JOSE          XYJZ2V TPASJUNK 0538 248Y026F0038 147>1181  0247BNK 000000000000029487000000000000                          ^460MEQCIGJLJLMYXzgkks7Z1jWfkW/cZSPFunmpdfrF/s4m40oYAiBjZH1WLm+3olwz+tMC+uBhr2fuS1EXwDg5qxBhge4RMg=="
    public static let scan8 = "M1PRUETT/KAILEY       E9169f13BLVPIEG4 0769 057Y011C0001 147>3182OO1057BG4              29268000000000000G4                    00PC^160MEUCIFzucrR1+DVpDo0bBTgfSKeynBc0igyZvQ8fLm67nMLdAiEAxNiljXHk9lNdiG4Nd5LYQwMIvWpohaRMp7E7ogYgQy8="
    public static let scan9 = "M1ACKERMANN/JUSTIN DAVEWHNSNI TPAPHXAA 1466 185R005A0056 14A>318   2185BAA 00000000000002900177708173663 AA AA 76UXK84             243"
    public static let scan10 = "M2ACKERMANN/JUSTIN DAVEWHFPBW TPASEAAS 0635 213L007A0000 148>2181MM    BAS              25             3    AA 76UXK84         1    WHFPBW SEAJNUAS 0555 213L007A0000 13125             3    AA 76UXK84         1    01010^460MEQCICRNjFGBPfJr84Ma6vMjxTQLtZ1z7uB0tUfO+fS/3vvuAiAReH4kY4ZcmXR+vD8Y+KoA1Dn1YKpr8YxCYbREeOYcsA=="
    public static let scan11 = "M1ACKERMANN/JUSTIN DAVEJPYKJI SINNRTJL 0712 336Y025C0231 348>3180 O9335BJL 01315361700012900174601118720 JL AA 76UXK84             3"
    
    public static let scan12 = "M2FORHETZ/BETHANY     EP2DJMN CDGLHRAF 1780 117Y017C0130 348>5182 O    BAF              2A93223260324620    VS 1091120160          NP2DJMN LHRTPAVS 0129 117W026H0088 32C2A93223260324620    VS 1091120160          N"
    
    public static let scan13 = "M2ACKERMANN/JUSTIN    EP2DJMN CDGLHRAF 1780 117Y017A0129 348>5181 O    BAF              2A93223260324630    DL 9379805238          NP2DJMN LHRTPAVS 0129 117W026K0087 32C2A93223260324630    DL 9379805238          N"
    
    public static let scan14 = "M1FORHETZ/BETHANY     EJNRBUA TPADFWAA 2529 342C014E0099 147>1180OO3342BAA              29             31                          "
}
