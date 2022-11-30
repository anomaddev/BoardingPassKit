//
//  BoardingPass.swift
//  
//
//  Created by Justin Ackermann on 11/29/22.
//

import Foundation
import SwiftDate

public class BoardingPass: Codable {
    
    // Unique
    let imported: Date
    var updated: Date
    var owner: String!
    let scan: String
    
    // Mandatory Items
    let format: String
    let legs: Int
    let name: String
    var eTicket: Bool? = false
    var segments: [BoardingPassLeg] = []
    
    // Conditionals
    var version: Int?
    var uniqueLength: Int?
    
    var passengerDesc: String?
    var checkinSource: String?
    var passSource: String?
    var passDate: Date?
    var passYear: Int?
    var passDay: Int?
    var documentType: String?
    var passIssuer: String?
    
    var bags: [BagTag] = []
    
    // computed
    var first: String? {
        String(
            name.split(separator: "/")[1]
                .split(separator: " ")[0]
        ).localizedCapitalized
    }
    
    var last: String?
    { String(name.split(separator: "/")[0]).localizedCapitalized }
    
//    var ident: String?
//    { segments.first?.ident }
    
//    var origin: Airport!
//    { segments.first?.originAirport ?? Airport.UKWN }
//
//    var destination: Airport!
//    { segments.first?.destinationAirport ?? Airport.UKWN  }
    
    var dayOfYear: Int?
    { segments.first?.dayOfYear ?? passDay }
    
//    var distance: Distance
//    { .init(from: origin.coordinate, to: destination.coordinate) }
    
    public init(_ data: Data?) throws {
        guard let data = data else { throw NSError() } // THROW:
        let parser = BoardingPassParser(data: data)
        imported = Date()
        updated = Date()
        scan = try parser.raw()
        
        do {
            format = try parser.getstring(1, mandatory: true)!
            legs = try parser.getstring(1, mandatory: true)!.number()
            name = try parser.getstring(20, mandatory: true)!
            eTicket = try parser.getstring(1, mandatory: true)?.eTicket()
            
            for i in 1...legs {
                let mandatory = try parser.subparser(35)
                let leg = try BoardingPassLeg(data: mandatory)
                let length = try parser.readhex(2)
                
                if length > 0 {
                    let conditionals = try parser.subparser(length)
                    
                    // parse unique fields in first segment only
                    if i == 1 {
                        let versionNumberIndicator = try conditionals.getstring(1, mandatory: true)
                        guard versionNumberIndicator == ">" else {
                            throw NSError() // THROW:
                        }
                        version = try conditionals.getstring(1, mandatory: true)!.number()
                        
                        let conditionalLength = try conditionals.readhex(2)
                        let conditionalData = try conditionals.subparser(conditionalLength)
                        passengerDesc = try conditionalData.getstring(1)
                        checkinSource = try conditionalData.getstring(1)
                        passSource = try conditionalData.getstring(1)
                        passYear = try conditionalData.getstring(1)?.number()
                        passDay = try conditionalData.getstring(3)?.number()
                        documentType = try conditionalData.getstring(1)
                        passIssuer = try conditionalData.getstring(3)
                        
                        // DEV: Implement later
                        //                        for _ in 1...3 {
                        //                            do {
                        //                                guard let tagData = try parser.subsection(13) else {
                        //                                    break
                        //                                }
                        //                                let tag = try BagTag(data: tagData)
                        //                                bags.append(tag)
                        //                            } catch { throw error }
                        //                        }
                    }
                    
                    let repeatedLength = try conditionals.readhex(2)
                    let repeatedData = try conditionals.subparser(repeatedLength)
                    try leg.addconditionals(data: repeatedData)
                    
                    let remaining = conditionals.data.count - conditionals.index
                    if remaining > 0 {
                        let raw = try conditionals.subparser(remaining)
                            .raw()
                            .trimmingCharacters(in: .whitespaces)
                        if raw != "" { leg.airlineData = raw }
                    }
                }
                
                segments.append(leg)
            }
            
            passDate = try parseDate(with: passYear)
//            atlasId = try? generateAtlasId()
//            print(atlasId)
//            print()
            
            // securityData = try parser.securityData() // TODO: Implement
            
//            guard origin != nil else { return } // THROW:
//            guard destination != nil else { return }
            guard (passDay != nil || segments.first?.dayOfYear != nil) else { return }
        } catch { throw error }
    }
    
    // MARK: - Modifiers
    func parseDate(with year: Int! = nil) throws -> Date? {
        guard let day = segments.first?.dayOfYear ?? passDay
        else { return nil }
        
        if let year = year, year > 1000 {
            var dateComponents = DateComponents();
            dateComponents.year = year
            dateComponents.day = day
            let calendar = Calendar.current
            let date = calendar.date(from: dateComponents)
            
            guard let date = date
            else { return nil } // THROW:
            
            return date
        }
        
        let current = Date()
        let min = (current - 3.years).year
        let max = (current + 1.years).year
        let check = Array(min...max).first
        { $0.string.last == passYear?.string.last ?? Character("l") }
        
        guard let check = check
        else { return nil }
        
        var dateComponents = DateComponents();
        dateComponents.year = check
        dateComponents.day = day
        dateComponents.hour = 1
//        dateComponents.timeZone = TimezoneMapper.latLngToTimezone(origin.coordinate)!
        
        var calendar = Calendar.current
        let timezone = TimeZone(abbreviation: "GMT")!
        calendar.timeZone = timezone
        
        let date = calendar.date(from: dateComponents)
        
        guard let date = date
        else { return nil } // THROW:
        
        return date
    }
    
    // MARK: - Test Scans
    enum Test: String, CaseIterable {
        case empty = ""
        case random = "asDFADFAKL asdlfjk ads;aDFJ  la'lsdjkf aASDFA"
        case upgraded = "M1ACKERMANN/JUSTIN    ETDPUPK TPADFWAA 1189 091R003A0033 14A>318   0091BAA 00000000000002900121232782703 AA AA 76UXK84             2IN"
        
        case scan = "M1ACKERMANN/JUSTIN    ELIIBGP CLTTPAAA 1632 136R003A0030 148>218 MM    BAA              29001001212548532AA AA 76UXK84              AKAlfj2mu1aTkVQ5xj83jTf/c5bb+8G61Q==|Wftygjey5EygW2IxQt+9v1+DHuklYFnr"
        case scan1 = "M1ACKERMANN/JUSTIN    ELIIBGP STLCLTAA 1990 136R003A0026 148>218 MM    BAA              29001001212548532AA AA 76UXK84              ZulMW9ujSJJInrqdwbpy44gCfsK+lwdE|ALqh3u+QhfCfPINi1TMzFFDhCKM7ydqGDg=="
        case scan2 = "M1ACKERMANN/JUSTIN DAVEUXPVFK HKGSINCX 0715 326Y040G0059 34B>6180 O9326BCX              2A00174597371330 AA AA 76UXK84             N3AA"
        case scan3 = "M1ACKERMANN/JUSTIN DAVEJKLEAJ MSYPHXAA 2819 014S008F0059 14A>318   0014BAA 00000000000002900174844256573 AA AA 76UXK84             223"
        case scan4 = "M1ACKERMANN/JUSTIN DAVEQAEWGY SANDFWAA 1765 157K012A0028 14A>318   2157BAA 00000000000002900177636421733 AA AA 76UXK84             253"
        
        case other1 = "M1FERRER/JOSE          XYJZ2V TPASJUNK 0538 248Y026F0038 147>1181  0247BNK 000000000000029487000000000000                          ^460MEQCIGJLJLMYXzgkks7Z1jWfkW/cZSPFunmpdfrF/s4m40oYAiBjZH1WLm+3olwz+tMC+uBhr2fuS1EXwDg5qxBhge4RMg=="
        case other2 = "M1PRUETT/KAILEY       E9169f13BLVPIEG4 0769 057Y011C0001 147>3182OO1057BG4              29268000000000000G4                    00PC^160MEUCIFzucrR1+DVpDo0bBTgfSKeynBc0igyZvQ8fLm67nMLdAiEAxNiljXHk9lNdiG4Nd5LYQwMIvWpohaRMp7E7ogYgQy8="
        
        case scan22 = "M1ACKERMANN/JUSTIN DAVEWHNSNI TPAPHXAA 1466 185R005A0056 14A>318   2185BAA 00000000000002900177708173663 AA AA 76UXK84             243"
        
        case dual = "M2ACKERMANN/JUSTIN DAVEWHFPBW TPASEAAS 0635 213L007A0000 148>2181MM    BAS              25             3    AA 76UXK84         1    WHFPBW SEAJNUAS 0555 213L007A0000 13125             3    AA 76UXK84         1    01010^460MEQCICRNjFGBPfJr84Ma6vMjxTQLtZ1z7uB0tUfO+fS/3vvuAiAReH4kY4ZcmXR+vD8Y+KoA1Dn1YKpr8YxCYbREeOYcsA=="
        
        case japan = "M1ACKERMANN/JUSTIN DAVEJPYKJI SINNRTJL 0712 336Y025C0231 348>3180 O9335BJL 01315361700012900174601118720 JL AA 76UXK84             3"
    }
}

extension Int {
    var string: String
    { "\(self)" }
}
