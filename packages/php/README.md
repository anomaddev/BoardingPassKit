# boarding-pass-kit (PHP)

PHP bindings for the Rust `boarding-pass-kit` core via `ext-ffi`.

## Prerequisites

- PHP 8.1+ with the `ffi` extension enabled
- Built FFI library:

```bash
cargo build -p boarding-pass-kit-ffi --release
```

Override the library path with `BPK_FFI_LIB` if needed.

## Install / test

`ffi.enable` is a system INI setting — enable it on the CLI command line:

```bash
cd packages/php
composer install
composer test
# equivalent: php -d ffi.enable=true vendor/bin/phpunit
```

## Quick start

```php
<?php
use BoardingPassKit\BoardingPassDecoder;
use BoardingPassKit\DemoData;

$decoder = new BoardingPassDecoder();
$pass = $decoder->decode(DemoData::Simple);
echo $pass['passengerName'], PHP_EOL;

$image = file_get_contents('pass.png');
$payload = BoardingPassDecoder::extractQR($image);
$passFromImage = $decoder->decodeFromImage($image);
```

`extractQR` reads PNG/JPEG bytes (and HEIC when the FFI library is built with `--features heic`).
