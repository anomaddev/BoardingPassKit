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
}
