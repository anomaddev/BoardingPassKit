package boardingpasskit

/*
#cgo CFLAGS: -I${SRCDIR}/../ffi/include
#cgo LDFLAGS: ${SRCDIR}/../../target/release/libboarding_pass_kit_ffi.a -ldl -lm -lpthread

#include "boarding_pass_kit.h"
#include <stdlib.h>
*/
import "C"

import (
	"encoding/json"
	"errors"
	"unsafe"
)

// Options mirrors decoder knobs from the Rust/Node APIs.
type Options struct {
	Debug             bool
	TrimLeadingZeroes bool
	TrimWhitespace    bool
	EmptyStringIsNil  bool
}

// DefaultOptions returns the same defaults as the other language packages.
func DefaultOptions() Options {
	return Options{
		Debug:             false,
		TrimLeadingZeroes: true,
		TrimWhitespace:    true,
		EmptyStringIsNil:  true,
	}
}

// DemoData keys match the Node/Swift fixtures.
var DemoData = map[string]string{
	"Simple":        "M1ACKERMANN/JUSTIN DAVEJKLEAJ MSYPHXAA 2819 014S008F0059 14A>318   0014BAA 00000000000002900174844256573 AA AA 76UXK84             223",
	"Historical":    "M1ACKERMANN/JUSTIN    ETDPUPK TPADFWAA 1189 091R003A0033 14A>318   0091BAA 00000000000002900121232782703 AA AA 76UXK84             2IN",
	"MultiLeg":      "M2ACKERMANN/JUSTIN DAVEWHFPBW TPASEAAS 0635 213L007A0000 148>2181MM    BAS              25             3    AA 76UXK84         1    WHFPBW SEAJNUAS 0555 213L007A0000 13125             3    AA 76UXK84         1    01010^460MEQCICRNjFGBPfJr84Ma6vMjxTQLtZ1z7uB0tUfO+fS/3vvuAiAReH4kY4ZcmXR+vD8Y+KoA1Dn1YKpr8YxCYbREeOYcsA==",
	"International": "M1ACKERMANN/JUSTIN DAVEJPYKJI SINNRTJL 0712 336Y025C0231 348>3180 O9335BJL 01315361700012900174601118720 JL AA 76UXK84             3",
}

// Decode parses a BCBP barcode into a generic JSON map.
func Decode(barcode string, opts Options) (map[string]any, error) {
	cBarcode := C.CString(barcode)
	defer C.free(unsafe.Pointer(cBarcode))

	cOpts := C.BpkOptions{
		debug:              boolToInt(opts.Debug),
		trim_leading_zeroes: boolToInt(opts.TrimLeadingZeroes),
		trim_whitespace:    boolToInt(opts.TrimWhitespace),
		empty_string_is_nil: boolToInt(opts.EmptyStringIsNil),
	}

	result := C.bpk_decode(cBarcode, &cOpts)
	if result == nil {
		errMsg := C.GoString(C.bpk_last_error())
		if errMsg == "" {
			errMsg = "decode failed"
		}
		return nil, errors.New(errMsg)
	}
	defer C.bpk_free_string(result)

	jsonStr := C.GoString(result)
	var out map[string]any
	if err := json.Unmarshal([]byte(jsonStr), &out); err != nil {
		return nil, err
	}
	return out, nil
}

// JulianToDate converts a day-of-year to YYYY-MM-DD.
// Pass year=0 to infer from relativeToMs (0 means now).
func JulianToDate(dayOfYear int, year int, relativeToMs int64) (string, error) {
	result := C.bpk_julian_to_date(C.int(dayOfYear), C.int(year), C.int64_t(relativeToMs))
	if result == nil {
		errMsg := C.GoString(C.bpk_last_error())
		if errMsg == "" {
			errMsg = "julian conversion failed"
		}
		return "", errors.New(errMsg)
	}
	defer C.bpk_free_string(result)
	return C.GoString(result), nil
}

func boolToInt(v bool) C.int {
	if v {
		return 1
	}
	return 0
}
