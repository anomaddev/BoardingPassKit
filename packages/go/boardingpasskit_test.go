package boardingpasskit

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
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
