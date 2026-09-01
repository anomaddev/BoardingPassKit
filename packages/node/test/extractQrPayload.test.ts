import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { BoardingPassDecoder } from '../src/decoder/BoardingPassDecoder.js';
import { DemoData } from '../src/demo/DemoData.js';
import { BoardingPassError, BoardingPassErrorCode } from '../src/errors/BoardingPassError.js';
import { extractQrPayload } from '../src/qr/extractQrPayload.js';

const imagesDir = join(dirname(fileURLToPath(import.meta.url)), '../../../testdata/images');

function readImage(name: string): Buffer {
  return readFileSync(join(imagesDir, name));
}

describe('extractQrPayload', () => {
  it('reads a QR payload from PNG bytes', async () => {
    const payload = await extractQrPayload(readImage('simple.png'));
    expect(payload).toBe(DemoData.Simple);
  });

  it('reads a QR payload from a JPEG file path', async () => {
    const payload = await extractQrPayload(join(imagesDir, 'simple.jpg'));
    expect(payload).toBe(DemoData.Simple);
  });

  it('reads a QR payload from HEIC bytes', async () => {
    const payload = await extractQrPayload(readImage('simple.heic'));
    expect(payload).toBe(DemoData.Simple);
  });

  it('throws QRCodeNotFound when the image has no QR', async () => {
    await expect(extractQrPayload(readImage('no_qr.png'))).rejects.toMatchObject({
      code: BoardingPassErrorCode.QRCodeNotFound,
    });
  });

  it('throws UnsupportedImageFormat for non-image bytes', async () => {
    await expect(extractQrPayload(readImage('not_an_image.bin'))).rejects.toBeInstanceOf(
      BoardingPassError,
    );
    await expect(extractQrPayload(readImage('not_an_image.bin'))).rejects.toMatchObject({
      code: BoardingPassErrorCode.UnsupportedImageFormat,
    });
  });
});

describe('BoardingPassDecoder.decodeFromImage', () => {
  it('decodes a boarding pass from a PNG QR image', async () => {
    const decoder = new BoardingPassDecoder();
    decoder.debug = false;
    const pass = await decoder.decodeFromImage(readImage('simple.png'));
    expect(pass.passengerName).toBe('ACKERMANN/JUSTIN DAV');
    expect(pass.boardingPassLegs[0]!.origin).toBe('MSY');
    expect(pass.code).toBe(DemoData.Simple);
  });
});
