<?php

declare(strict_types=1);

namespace BoardingPassKit\Tests;

use BoardingPassKit\BoardingPassDecoder;
use BoardingPassKit\DemoData;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class DecoderTest extends TestCase
{
    public function testGoldenFixtures(): void
    {
        $expectedPath = dirname(__DIR__, 3) . '/testdata/expected.json';
        $expected = json_decode(file_get_contents($expectedPath), true, 512, JSON_THROW_ON_ERROR);

        $decoder = new BoardingPassDecoder();
        $decoder->debug = false;

        foreach (['Simple', 'Historical', 'MultiLeg', 'International'] as $key) {
            $pass = $decoder->decode(DemoData::all()[$key]);
            $this->assertSame($expected[$key], $pass, "Fixture {$key}");
        }
    }

    public function testTruncatedThrows(): void
    {
        $decoder = new BoardingPassDecoder();
        $this->expectException(RuntimeException::class);
        $decoder->decode('M1ACKERMANN/JUSTIN');
    }

    public function testJulianToDate(): void
    {
        $this->assertSame('2025-01-14', BoardingPassDecoder::julianToDate(14, 2025));
    }

    public function testExtractQRPng(): void
    {
        $image = file_get_contents(dirname(__DIR__, 3) . '/testdata/images/simple.png');
        $this->assertSame(DemoData::Simple, BoardingPassDecoder::extractQR($image));
    }

    public function testExtractQRJpeg(): void
    {
        $image = file_get_contents(dirname(__DIR__, 3) . '/testdata/images/simple.jpg');
        $this->assertSame(DemoData::Simple, BoardingPassDecoder::extractQR($image));
    }

    public function testDecodeFromImagePng(): void
    {
        $image = file_get_contents(dirname(__DIR__, 3) . '/testdata/images/simple.png');
        $decoder = new BoardingPassDecoder();
        $pass = $decoder->decodeFromImage($image);
        $this->assertSame(DemoData::Simple, $pass['code']);
        $this->assertSame('MSY', $pass['boardingPassLegs'][0]['origin']);
    }

    public function testExtractQRNoCode(): void
    {
        $image = file_get_contents(dirname(__DIR__, 3) . '/testdata/images/no_qr.png');
        $this->expectException(RuntimeException::class);
        BoardingPassDecoder::extractQR($image);
    }

    public function testExtractQRHeic(): void
    {
        $image = file_get_contents(dirname(__DIR__, 3) . '/testdata/images/simple.heic');
        try {
            $payload = BoardingPassDecoder::extractQR($image);
        } catch (RuntimeException $e) {
            if (stripos($e->getMessage(), 'heic') !== false) {
                $this->markTestSkipped($e->getMessage());
            }
            throw $e;
        }
        $this->assertSame(DemoData::Simple, $payload);
    }
}
