package boardingpasskit

import (
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

func TestGoldenFixtures(t *testing.T) {
	raw, err := os.ReadFile(testdataPath("expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	var expected map[string]any
	if err := json.Unmarshal(raw, &expected); err != nil {
		t.Fatal(err)
	}

	opts := DefaultOptions()
	for _, key := range []string{"Simple", "Historical", "MultiLeg", "International"} {
		got, err := Decode(DemoData[key], opts)
		if err != nil {
			t.Fatalf("%s: %v", key, err)
		}
		wantJSON, _ := json.Marshal(expected[key])
		gotJSON, _ := json.Marshal(got)
		if string(wantJSON) != string(gotJSON) {
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
