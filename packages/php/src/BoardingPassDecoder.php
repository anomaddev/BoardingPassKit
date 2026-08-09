<?php

declare(strict_types=1);

namespace BoardingPassKit;

use FFI;
use RuntimeException;

final class BoardingPassDecoder
{
    public bool $debug = false;
    public bool $trimLeadingZeroes = true;
    public bool $trimWhitespace = true;
    public bool $emptyStringIsNil = true;

    private static ?FFI $ffi = null;

    private const CDEF = <<<'CDEF'
typedef struct BpkOptions {
    int debug;
    int trim_leading_zeroes;
    int trim_whitespace;
    int empty_string_is_nil;
} BpkOptions;

char *bpk_decode(const char *barcode, const BpkOptions *options);
char *bpk_julian_to_date(int day_of_year, int year, int64_t relative_to_ms);
const char *bpk_last_error(void);
void bpk_free_string(char *ptr);
CDEF;

    public static function libraryPath(?string $override = null): string
    {
        if ($override !== null) {
            return $override;
        }
        if ($env = getenv('BPK_FFI_LIB')) {
            return $env;
        }

        $root = dirname(__DIR__, 3);
        $candidates = [
            $root . '/target/release/libboarding_pass_kit_ffi.so',
            $root . '/target/debug/libboarding_pass_kit_ffi.so',
            $root . '/target/release/libboarding_pass_kit_ffi.dylib',
            $root . '/target/debug/libboarding_pass_kit_ffi.dylib',
        ];
        foreach ($candidates as $path) {
            if (is_file($path)) {
                return $path;
            }
        }

        throw new RuntimeException(
            'libboarding_pass_kit_ffi not found. Build with: cargo build -p boarding-pass-kit-ffi --release'
        );
    }

    private static function ffi(): FFI
    {
        if (self::$ffi !== null) {
            return self::$ffi;
        }

        self::$ffi = FFI::cdef(self::CDEF, self::libraryPath());
        return self::$ffi;
    }

    /**
     * @return array<string, mixed>
     */
    public function decode(string $barcode): array
    {
        $ffi = self::ffi();
        $opts = $ffi->new('BpkOptions');
        $opts->debug = $this->debug ? 1 : 0;
        $opts->trim_leading_zeroes = $this->trimLeadingZeroes ? 1 : 0;
        $opts->trim_whitespace = $this->trimWhitespace ? 1 : 0;
        $opts->empty_string_is_nil = $this->emptyStringIsNil ? 1 : 0;

        $result = $ffi->bpk_decode($barcode, FFI::addr($opts));
        if ($result === null) {
            $err = $ffi->bpk_last_error();
            $message = is_string($err) ? $err : 'decode failed';
            throw new RuntimeException($message !== '' ? $message : 'decode failed');
        }

        try {
            $json = FFI::string($result);
        } finally {
            $ffi->bpk_free_string($result);
        }

        $decoded = json_decode($json, true, 512, JSON_THROW_ON_ERROR);
        if (!is_array($decoded)) {
            throw new RuntimeException('Unexpected decode JSON shape');
        }
        return $decoded;
    }

    public static function julianToDate(int $dayOfYear, ?int $year = null, int $relativeToMs = 0): string
    {
        $ffi = self::ffi();
        $result = $ffi->bpk_julian_to_date($dayOfYear, $year ?? 0, $relativeToMs);
        if ($result === null) {
            $err = $ffi->bpk_last_error();
            $message = is_string($err) ? $err : 'julian conversion failed';
            throw new RuntimeException($message !== '' ? $message : 'julian conversion failed');
        }
        try {
            return FFI::string($result);
        } finally {
            $ffi->bpk_free_string($result);
        }
    }
}
