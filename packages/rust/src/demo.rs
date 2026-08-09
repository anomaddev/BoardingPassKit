use std::collections::HashMap;
use std::sync::LazyLock;

pub type DemoDataKey = &'static str;

pub static DEMO_DATA: LazyLock<HashMap<&'static str, &'static str>> = LazyLock::new(|| {
    let mut map = HashMap::new();
    map.insert(
        "Simple",
        "M1ACKERMANN/JUSTIN DAVEJKLEAJ MSYPHXAA 2819 014S008F0059 14A>318   0014BAA 00000000000002900174844256573 AA AA 76UXK84             223",
    );
    map.insert(
        "Historical",
        "M1ACKERMANN/JUSTIN    ETDPUPK TPADFWAA 1189 091R003A0033 14A>318   0091BAA 00000000000002900121232782703 AA AA 76UXK84             2IN",
    );
    map.insert(
        "MultiLeg",
        "M2ACKERMANN/JUSTIN DAVEWHFPBW TPASEAAS 0635 213L007A0000 148>2181MM    BAS              25             3    AA 76UXK84         1    WHFPBW SEAJNUAS 0555 213L007A0000 13125             3    AA 76UXK84         1    01010^460MEQCICRNjFGBPfJr84Ma6vMjxTQLtZ1z7uB0tUfO+fS/3vvuAiAReH4kY4ZcmXR+vD8Y+KoA1Dn1YKpr8YxCYbREeOYcsA==",
    );
    map.insert(
        "International",
        "M1ACKERMANN/JUSTIN DAVEJPYKJI SINNRTJL 0712 336Y025C0231 348>3180 O9335BJL 01315361700012900174601118720 JL AA 76UXK84             3",
    );
    map
});

pub fn demo_data(key: &str) -> Option<&'static str> {
    DEMO_DATA.get(key).copied()
}

pub fn demo_keys() -> Vec<&'static str> {
    let mut keys: Vec<_> = DEMO_DATA.keys().copied().collect();
    keys.sort_unstable();
    keys
}
