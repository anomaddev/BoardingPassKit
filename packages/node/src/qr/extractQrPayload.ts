import { readFile } from 'node:fs/promises';
import {
  BarcodeFormat,
  BinaryBitmap,
  DecodeHintType,
  GlobalHistogramBinarizer,
  HybridBinarizer,
  MultiFormatReader,
  RGBLuminanceSource,
} from '@zxing/library';
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

const ZXING_FORMATS = [BarcodeFormat.QR_CODE, BarcodeFormat.AZTEC, BarcodeFormat.PDF_417];

const ZXING_HINTS = new Map<DecodeHintType, unknown>();
ZXING_HINTS.set(DecodeHintType.POSSIBLE_FORMATS, ZXING_FORMATS);
ZXING_HINTS.set(DecodeHintType.TRY_HARDER, true);
ZXING_HINTS.set(DecodeHintType.CHARACTER_SET, 'ISO-8859-1');

const ZXING_HINTS_PURE = new Map<DecodeHintType, unknown>(ZXING_HINTS);
ZXING_HINTS_PURE.set(DecodeHintType.PURE_BARCODE, true);

const BRIGHT_LUMA_FLOOR = 180;
const BRIGHT_RANGE_MIN_SPAN = 8;

/**
 * Read PNG, JPEG, or HEIC bytes (or a file path) and return the first
 * QR, Aztec, or PDF417 payload.
 */
export async function extractQrPayload(image: ImageInput): Promise<string> {
  const bytes = await toBuffer(image);
  const rgba = await decodeImage(bytes);
  return findBarcodePayload(rgba);
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

function findBarcodePayload(image: RgbaImage): string {
  // First pass stays hybrid-only so high-contrast QR / Aztec / PDF417 are unchanged.
  const first = scanBarcodePayload(image, { hybridOnly: true });
  if (first) {
    return first;
  }

  const stretched = stretchBrightRange(image);
  if (stretched) {
    const retry = scanBarcodePayload(stretched);
    if (retry) {
      return retry;
    }

    const inverted = invertRgba(stretched);
    const invertedHit = scanBarcodePayload(inverted);
    if (invertedHit) {
      return invertedHit;
    }

    const pure = scanBarcodePayload(stretched, { pureBarcode: true });
    if (pure) {
      return pure;
    }
  }

  throw BoardingPassError.qrCodeNotFound();
}

type ScanOptions = {
  hybridOnly?: boolean;
  pureBarcode?: boolean;
};

function scanBarcodePayload(image: RgbaImage, options?: ScanOptions): string | null {
  let current = image;
  for (let i = 0; i < 4; i += 1) {
    const qr = jsQR(current.data, current.width, current.height, {
      inversionAttempts: 'attemptBoth',
    });
    if (qr?.data) {
      return qr.data;
    }
    const zxing = decodeWithZxing(current, options);
    if (zxing) {
      return zxing;
    }
    current = rotateRgba90(current);
  }
  return null;
}

function decodeWithZxing(image: RgbaImage, options?: ScanOptions): string | null {
  const source = new RGBLuminanceSource(rgbaToLuma(image), image.width, image.height);
  const hints = options?.pureBarcode ? ZXING_HINTS_PURE : ZXING_HINTS;
  const binarizers = options?.hybridOnly
    ? [HybridBinarizer]
    : [HybridBinarizer, GlobalHistogramBinarizer];
  for (const BinarizerType of binarizers) {
    const reader = new MultiFormatReader();
    try {
      const result = reader.decode(new BinaryBitmap(new BinarizerType(source)), hints);
      const text = result.getText();
      if (text) {
        return text;
      }
    } catch {
      // try the next binarizer
    }
  }
  return null;
}

/** Stretch bright pixels so a washed-out barcode on a colored card is readable. */
function stretchBrightRange(image: RgbaImage): RgbaImage | null {
  const luma = rgbaToLuma(image);
  let min = 255;
  let max = 0;
  for (let i = 0; i < luma.length; i += 1) {
    const value = luma[i]!;
    if (value >= BRIGHT_LUMA_FLOOR) {
      if (value < min) {
        min = value;
      }
      if (value > max) {
        max = value;
      }
    }
  }
  if (max - min < BRIGHT_RANGE_MIN_SPAN) {
    return null;
  }

  const range = max - min;
  const { data, width, height } = image;
  const stretched = new Uint8ClampedArray(data.length);
  for (let i = 0; i < luma.length; i += 1) {
    const offset = i * 4;
    const value = luma[i]!;
    const out = value >= BRIGHT_LUMA_FLOOR ? ((value - min) * 255) / range : 0;
    stretched[offset] = out;
    stretched[offset + 1] = out;
    stretched[offset + 2] = out;
    stretched[offset + 3] = data[offset + 3]!;
  }
  return { data: stretched, width, height };
}

function invertRgba(image: RgbaImage): RgbaImage {
  const data = new Uint8ClampedArray(image.data);
  for (let i = 0; i < data.length; i += 4) {
    data[i] = 255 - data[i]!;
    data[i + 1] = 255 - data[i + 1]!;
    data[i + 2] = 255 - data[i + 2]!;
  }
  return { data, width: image.width, height: image.height };
}

function rgbaToLuma(image: RgbaImage): Uint8ClampedArray {
  const { data, width, height } = image;
  const luma = new Uint8ClampedArray(width * height);
  for (let i = 0; i < luma.length; i += 1) {
    const offset = i * 4;
    const r = data[offset]!;
    const g = data[offset + 1]!;
    const b = data[offset + 2]!;
    luma[i] = (r * 77 + g * 150 + b * 29) >> 8;
  }
  return luma;
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
