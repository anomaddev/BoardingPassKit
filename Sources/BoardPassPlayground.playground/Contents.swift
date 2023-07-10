import UIKit
import BoardingPassKit

let scan1 = "M1ACKERMANN/JUSTIN    ETDPUPK TPADFWAA 1189 091R003A0033 14A>318   0091BAA 00000000000002900121232782703 AA AA 76UXK84             2IN"
let scan2 = "M1ACKERMANN/JUSTIN    ELIIBGP CLTTPAAA 1632 136R003A0030 148>218 MM    BAA              29001001212548532AA AA 76UXK84              AKAlfj2mu1aTkVQ5xj83jTf/c5bb+8G61Q==|Wftygjey5EygW2IxQt+9v1+DHuklYFnr"
let scan3 = "M1ACKERMANN/JUSTIN    ELIIBGP STLCLTAA 1990 136R003A0026 148>218 MM    BAA              29001001212548532AA AA 76UXK84              ZulMW9ujSJJInrqdwbpy44gCfsK+lwdE|ALqh3u+QhfCfPINi1TMzFFDhCKM7ydqGDg=="
let scan4 = "M1ACKERMANN/JUSTIN DAVEUXPVFK HKGSINCX 0715 326Y040G0059 34B>6180 O9326BCX              2A00174597371330 AA AA 76UXK84             N3AA"
let scan5 = "M1ACKERMANN/JUSTIN DAVEJKLEAJ MSYPHXAA 2819 014S008F0059 14A>318   0014BAA 00000000000002900174844256573 AA AA 76UXK84             223"
let scan6 = "M1ACKERMANN/JUSTIN DAVEQAEWGY SANDFWAA 1765 157K012A0028 14A>318   2157BAA 00000000000002900177636421733 AA AA 76UXK84             253"
let scan7 = "M1FERRER/JOSE          XYJZ2V TPASJUNK 0538 248Y026F0038 147>1181  0247BNK 000000000000029487000000000000                          ^460MEQCIGJLJLMYXzgkks7Z1jWfkW/cZSPFunmpdfrF/s4m40oYAiBjZH1WLm+3olwz+tMC+uBhr2fuS1EXwDg5qxBhge4RMg=="
let scan8 = "M1PRUETT/KAILEY       E9169f13BLVPIEG4 0769 057Y011C0001 147>3182OO1057BG4              29268000000000000G4                    00PC^160MEUCIFzucrR1+DVpDo0bBTgfSKeynBc0igyZvQ8fLm67nMLdAiEAxNiljXHk9lNdiG4Nd5LYQwMIvWpohaRMp7E7ogYgQy8="
let scan9 = "M1ACKERMANN/JUSTIN DAVEWHNSNI TPAPHXAA 1466 185R005A0056 14A>318   2185BAA 00000000000002900177708173663 AA AA 76UXK84             243"
let scan10 = "M2ACKERMANN/JUSTIN DAVEWHFPBW TPASEAAS 0635 213L007A0000 148>2181MM    BAS              25             3    AA 76UXK84         1    WHFPBW SEAJNUAS 0555 213L007A0000 13125             3    AA 76UXK84         1    01010^460MEQCICRNjFGBPfJr84Ma6vMjxTQLtZ1z7uB0tUfO+fS/3vvuAiAReH4kY4ZcmXR+vD8Y+KoA1Dn1YKpr8YxCYbREeOYcsA=="
let scan11 = "M1ACKERMANN/JUSTIN DAVEJPYKJI SINNRTJL 0712 336Y025C0231 348>3180 O9335BJL 01315361700012900174601118720 JL AA 76UXK84             3"

do {
    let decoder = BoardingPassDecoder()
    
    let pass = try decoder.decode(code: scan10)
    
    decoder.debug = true
    let pass2 = try decoder.decode(code: scan7)
    pass2.printout()
} catch {
    print(error.localizedDescription)
    print()
}
