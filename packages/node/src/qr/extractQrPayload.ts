import { readFile } from 'node:fs/promises';
import heicDecode from 'heic-decode';
import jpeg from 'jpeg-js';
import jsQR from 'jsqr';
import { PNG } from 'pngjs';
import { BoardingPassError } from '../errors/BoardingPassError.js';

export type ImageInput = Buffer | Uint8Array | ArrayBuffer | string;

type RgbaImage = {
  data: Uint8ClampedArray;
  width: number;
  height: number;
};

const PNG_MAGIC = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

/**
 * Read PNG, JPEG, or HEIC bytes (or a file path) and return the first QR payload.
 */
export async function extractQrPayload(image: ImageInput): Promise<string> {
  const bytes = await toBuffer(image);
  const rgba = await decodeImage(bytes);
  return findQrPayload(rgba);
}

async function toBuffer(image: ImageInput): Promise<Buffer> {
  if (typeof image === 'string') {
    return readFile(image);
  }
  if (Buffer.isBuffer(image)) {
    return image;
  }
  if (image instanceof ArrayBuffer) {
    return Buffer.from(image);
  }
  return Buffer.from(image);
}

async function decodeImage(bytes: Buffer): Promise<RgbaImage> {
  if (bytes.length >= 8 && bytes.subarray(0, 8).equals(PNG_MAGIC)) {
    try {
      const png = PNG.sync.read(bytes);
      return {
        data: new Uint8ClampedArray(png.data),
        width: png.width,
        height: png.height,
      };
    } catch (error) {
      throw BoardingPassError.imageDecodeFailed(error instanceof Error ? error.message : String(error));
    }
  }

  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    try {
      const decoded = jpeg.decode(bytes, { useTArray: true });
      return {
        data: new Uint8ClampedArray(decoded.data),
        width: decoded.width,
        height: decoded.height,
      };
    } catch (error) {
      throw BoardingPassError.imageDecodeFailed(error instanceof Error ? error.message : String(error));
    }
  }

  if (isHeif(bytes)) {
    try {
      const decoded = await heicDecode({ buffer: bytes });
      return {
        data: new Uint8ClampedArray(decoded.data),
        width: decoded.width,
        height: decoded.height,
      };
    } catch (error) {
      throw BoardingPassError.imageDecodeFailed(error instanceof Error ? error.message : String(error));
    }
  }

  throw BoardingPassError.unsupportedImageFormat('expected PNG, JPEG, or HEIC');
}

function isHeif(bytes: Buffer): boolean {
  if (bytes.length < 12 || bytes.subarray(4, 8).toString('ascii') !== 'ftyp') {
    return false;
  }
  if (heifBrand(bytes.subarray(8, 12).toString('ascii'))) {
    return true;
  }
  const boxSize = bytes.readUInt32BE(0);
  const end = Math.min(boxSize, bytes.length);
  for (let offset = 16; offset + 4 <= end; offset += 4) {
    if (heifBrand(bytes.subarray(offset, offset + 4).toString('ascii'))) {
      return true;
    }
  }
  return false;
}

function heifBrand(brand: string): boolean {
  return ['heic', 'heix', 'heif', 'hevc', 'hevx', 'mif1', 'msf1'].includes(brand);
}

function findQrPayload(image: RgbaImage): string {
  let current = image;
  for (let i = 0; i < 4; i += 1) {
    const result = jsQR(current.data, current.width, current.height, {
      inversionAttempts: 'attemptBoth',
    });
    if (result?.data) {
      return result.data;
    }
    current = rotateRgba90(current);
  }
  throw BoardingPassError.qrCodeNotFound();
}

function rotateRgba90(image: RgbaImage): RgbaImage {
  const { width, height, data } = image;
  const rotated = new Uint8ClampedArray(data.length);
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const src = (y * width + x) * 4;
      const dx = height - 1 - y;
      const dy = x;
      const dst = (dy * height + dx) * 4;
      rotated[dst] = data[src]!;
      rotated[dst + 1] = data[src + 1]!;
      rotated[dst + 2] = data[src + 2]!;
      rotated[dst + 3] = data[src + 3]!;
    }
  }
  return { data: rotated, width: height, height: width };
}
