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

```bash
cd packages/php
composer install
./vendor/bin/phpunit
```

## Quick start

```php
<?php
use BoardingPassKit\BoardingPassDecoder;
use BoardingPassKit\DemoData;

$decoder = new BoardingPassDecoder();
$pass = $decoder->decode(DemoData::Simple);
echo $pass['passengerName'], PHP_EOL;
```
