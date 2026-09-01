package boardingpasskit

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func testdataPath(name string) string {
	_, file, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(file), "..", "..", "testdata", name)
}

func canonicalJSON(raw []byte) (string, error) {
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.UseNumber()
	var normalized any
	if err := dec.Decode(&normalized); err != nil {
		return "", err
	}
	out, err := json.Marshal(normalized)
	if err != nil {
		return "", err
	}
	return string(out), nil
}

func TestGoldenFixtures(t *testing.T) {
	raw, err := os.ReadFile(testdataPath("expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	var expected map[string]json.RawMessage
	if err := json.Unmarshal(raw, &expected); err != nil {
		t.Fatal(err)
	}

	opts := DefaultOptions()
	for _, key := range []string{"Simple", "Historical", "MultiLeg", "International"} {
		got, err := Decode(DemoData[key], opts)
		if err != nil {
			t.Fatalf("%s: %v", key, err)
		}
		gotBytes, err := json.Marshal(got)
		if err != nil {
			t.Fatal(err)
		}
		gotJSON, err := canonicalJSON(gotBytes)
		if err != nil {
			t.Fatal(err)
		}
		wantJSON, err := canonicalJSON(expected[key])
		if err != nil {
			t.Fatal(err)
		}
		if gotJSON != wantJSON {
			t.Fatalf("%s mismatch\ngot:  %s\nwant: %s", key, gotJSON, wantJSON)
		}
	}
}

func TestTruncated(t *testing.T) {
	_, err := Decode("M1ACKERMANN/JUSTIN", DefaultOptions())
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestJulian(t *testing.T) {
	date, err := JulianToDate(14, 2025, 0)
	if err != nil {
		t.Fatal(err)
	}
	if date != "2025-01-14" {
		t.Fatalf("got %s", date)
	}
}

func readImage(t *testing.T, name string) []byte {
	t.Helper()
	data, err := os.ReadFile(testdataPath(filepath.Join("images", name)))
	if err != nil {
		t.Fatal(err)
	}
	return data
}

func TestExtractQRPng(t *testing.T) {
	payload, err := ExtractQR(readImage(t, "simple.png"))
	if err != nil {
		t.Fatal(err)
	}
	if payload != DemoData["Simple"] {
		t.Fatalf("got %q", payload)
	}
}

func TestExtractQRJpeg(t *testing.T) {
	payload, err := ExtractQR(readImage(t, "simple.jpg"))
	if err != nil {
		t.Fatal(err)
	}
	if payload != DemoData["Simple"] {
		t.Fatalf("got %q", payload)
	}
}

func TestDecodeFromImagePng(t *testing.T) {
	pass, err := DecodeFromImage(readImage(t, "simple.png"), DefaultOptions())
	if err != nil {
		t.Fatal(err)
	}
	if pass["code"] != DemoData["Simple"] {
		t.Fatalf("unexpected code %v", pass["code"])
	}
}

func TestExtractAztecPng(t *testing.T) {
	payload, err := ExtractQR(readImage(t, "simple_aztec.png"))
	if err != nil {
		t.Fatal(err)
	}
	if payload != DemoData["Simple"] {
		t.Fatalf("got %q", payload)
	}
}

func TestExtractPDF417Png(t *testing.T) {
	payload, err := ExtractQR(readImage(t, "simple_pdf417.png"))
	if err != nil {
		t.Fatal(err)
	}
	if payload != DemoData["Simple"] {
		t.Fatalf("got %q", payload)
	}
}

func TestExtractQRNoCode(t *testing.T) {
	_, err := ExtractQR(readImage(t, "no_qr.png"))
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestExtractQRNotAnImage(t *testing.T) {
	_, err := ExtractQR(readImage(t, "not_an_image.bin"))
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestExtractQRHeic(t *testing.T) {
	payload, err := ExtractQR(readImage(t, "simple.heic"))
	if err != nil {
		if strings.Contains(strings.ToLower(err.Error()), "heic") {
			t.Skip(err.Error())
		}
		t.Fatal(err)
	}
	if payload != DemoData["Simple"] {
		t.Fatalf("got %q", payload)
	}
}
