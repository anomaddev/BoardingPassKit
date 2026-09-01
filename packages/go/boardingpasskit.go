package boardingpasskit

/*
#cgo CFLAGS: -I${SRCDIR}/../ffi/include
#cgo linux LDFLAGS: -L${SRCDIR}/../../target/release -L${SRCDIR}/../../target/debug -l:libboarding_pass_kit_ffi.a -ldl -lm -lpthread
#cgo darwin LDFLAGS: ${SRCDIR}/../../target/release/libboarding_pass_kit_ffi.a -ldl -lm -lpthread
#cgo !linux,!darwin LDFLAGS: -L${SRCDIR}/../../target/release -L${SRCDIR}/../../target/debug -lboarding_pass_kit_ffi -ldl -lm -lpthread

#include "boarding_pass_kit.h"
#include <stdlib.h>
*/
import "C"

import (
	"encoding/json"
	"errors"
	"strings"
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
// Numeric fields are decoded as json.Number to avoid float64 golden-test drift.
func Decode(barcode string, opts Options) (map[string]any, error) {
	cBarcode := C.CString(barcode)
	defer C.free(unsafe.Pointer(cBarcode))

	cOpts := C.BpkOptions{
		debug:               boolToInt(opts.Debug),
		trim_leading_zeroes: boolToInt(opts.TrimLeadingZeroes),
		trim_whitespace:     boolToInt(opts.TrimWhitespace),
		empty_string_is_nil: boolToInt(opts.EmptyStringIsNil),
	}

	var errOut *C.char
	result := C.bpk_decode(cBarcode, &cOpts, &errOut)
	if result == nil {
		msg := "decode failed"
		if errOut != nil {
			msg = C.GoString(errOut)
			C.bpk_free_string(errOut)
		}
		return nil, errors.New(msg)
	}
	defer C.bpk_free_string(result)

	dec := json.NewDecoder(strings.NewReader(C.GoString(result)))
	dec.UseNumber()
	var out map[string]any
	if err := dec.Decode(&out); err != nil {
		return nil, err
	}
	return out, nil
}

// ExtractQR returns the first QR, Aztec, or PDF417 payload from PNG, JPEG, or HEIC image bytes.
func ExtractQR(image []byte) (string, error) {
	if len(image) == 0 {
		return "", errors.New("image is empty")
	}

	var errOut *C.char
	result := C.bpk_extract_qr((*C.uint8_t)(unsafe.Pointer(&image[0])), C.size_t(len(image)), &errOut)
	if result == nil {
		msg := "QR extraction failed"
		if errOut != nil {
			msg = C.GoString(errOut)
			C.bpk_free_string(errOut)
		}
		return "", errors.New(msg)
	}
	defer C.bpk_free_string(result)
	return C.GoString(result), nil
}

// DecodeFromImage extracts a QR, Aztec, or PDF417 payload from image bytes and decodes it as BCBP.
func DecodeFromImage(image []byte, opts Options) (map[string]any, error) {
	payload, err := ExtractQR(image)
	if err != nil {
		return nil, err
	}
	return Decode(payload, opts)
}

// JulianToDate converts a day-of-year to YYYY-MM-DD.
// Pass year=0 to infer from relativeToMs (0 means now).
func JulianToDate(dayOfYear int, year int, relativeToMs int64) (string, error) {
	var errOut *C.char
	result := C.bpk_julian_to_date(C.int(dayOfYear), C.int(year), C.int64_t(relativeToMs), &errOut)
	if result == nil {
		msg := "julian conversion failed"
		if errOut != nil {
			msg = C.GoString(errOut)
			C.bpk_free_string(errOut)
		}
		return "", errors.New(msg)
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
