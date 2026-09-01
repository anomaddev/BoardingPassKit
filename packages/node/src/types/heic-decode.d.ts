declare module 'heic-decode' {
  interface HeicDecodeInput {
    buffer: Buffer | ArrayBuffer | Uint8Array;
  }

  interface HeicDecodeResult {
    width: number;
    height: number;
    data: Uint8ClampedArray;
  }

  function heicDecode(input: HeicDecodeInput): Promise<HeicDecodeResult>;
  export default heicDecode;
}
