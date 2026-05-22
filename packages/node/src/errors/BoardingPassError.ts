export enum BoardingPassErrorCode {
  InvalidPassFormat = 'InvalidPassFormat',
  InvalidSegments = 'InvalidSegments',
  DataFailedValidation = 'DataFailedValidation',
  DataIsNotBoardingPass = 'DataIsNotBoardingPass',
  CIQRCodeGeneratorNotFound = 'CIQRCodeGeneratorNotFound',
  CIQRCodeGeneratorOutputFailed = 'CIQRCodeGeneratorOutputFailed',
  MandatoryItemNotFound = 'MandatoryItemNotFound',
  DataFailedStringDecoding = 'DataFailedStringDecoding',
  FieldValueNotRequiredInteger = 'FieldValueNotRequiredInteger',
  HexStringFailedDecoding = 'HexStringFailedDecoding',
  ConditionalIndexInvalid = 'ConditionalIndexInvalid',
  MainSegmentBagConditionalInvalid = 'MainSegmentBagConditionalInvalid',
  BoardingPassLegConditionalMismatch = 'BoardingPassLegConditionalMismatch',
  SegmentSubConditionalInvalid = 'SegmentSubConditionalInvalid',
  InvalidJulianDay = 'InvalidJulianDay',
  Unexpected = 'unexpected',
}

export interface BoardingPassErrorDetails {
  format?: string;
  legs?: number;
  code?: string;
  index?: number;
  value?: string;
  string?: string;
  endConditional?: number;
  subConditional?: number;
  innerError?: unknown;
  dayOfYear?: number;
  unexpectedCode?: number;
}

export class BoardingPassError extends Error {
  readonly code: BoardingPassErrorCode;
  readonly details: BoardingPassErrorDetails;

  constructor(code: BoardingPassErrorCode, message: string, details: BoardingPassErrorDetails = {}) {
    super(message);
    this.name = 'BoardingPassError';
    this.code = code;
    this.details = details;
  }

  static invalidPassFormat(format: string): BoardingPassError {
    return new BoardingPassError(
      BoardingPassErrorCode.InvalidPassFormat,
      `Invalid boarding pass format: ${format}`,
      { format },
    );
  }

  static invalidSegments(legs: number): BoardingPassError {
    return new BoardingPassError(
      BoardingPassErrorCode.InvalidSegments,
      `Invalid number of boarding pass segments ${legs}`,
      { legs },
    );
  }

  static dataFailedValidation(code: string): BoardingPassError {
    return new BoardingPassError(
      BoardingPassErrorCode.DataFailedValidation,
      `Data provided failed boarding pass validation: ${code}`,
      { code },
    );
  }

  static dataIsNotBoardingPass(error: unknown): BoardingPassError {
    const message =
      error instanceof Error
        ? error.message
        : String(error);
    return new BoardingPassError(
      BoardingPassErrorCode.DataIsNotBoardingPass,
      `Data provided is not a boarding pass: ${message}`,
      { innerError: error },
    );
  }

  static mandatoryItemNotFound(index: number): BoardingPassError {
    return new BoardingPassError(
      BoardingPassErrorCode.MandatoryItemNotFound,
      `Mandatory field value is not found at index ${index}`,
      { index },
    );
  }

  static dataFailedStringDecoding(): BoardingPassError {
    return new BoardingPassError(
      BoardingPassErrorCode.DataFailedStringDecoding,
      'Data fail .ascii String decoding',
    );
  }

  static fieldValueNotRequiredInteger(value: string): BoardingPassError {
    return new BoardingPassError(
      BoardingPassErrorCode.FieldValueNotRequiredInteger,
      `Field value ${value} is supposed to be an integer and is not`,
      { value },
    );
  }

  static hexStringFailedDecoding(string: string): BoardingPassError {
    return new BoardingPassError(
      BoardingPassErrorCode.HexStringFailedDecoding,
      `String ${string} failed to decode as hexidecimal`,
      { string },
    );
  }

  static conditionalIndexInvalid(endConditional: number, subConditional: number): BoardingPassError {
    return new BoardingPassError(
      BoardingPassErrorCode.ConditionalIndexInvalid,
      `Conditional parsing failed due to endConditional ${endConditional} or subConditional ${subConditional}`,
      { endConditional, subConditional },
    );
  }

  static boardingPassLegConditionalMismatch(): BoardingPassError {
    return new BoardingPassError(
      BoardingPassErrorCode.BoardingPassLegConditionalMismatch,
      'Boarding pass leg conditional mismatches parsing index',
    );
  }

  static invalidJulianDay(dayOfYear: number): BoardingPassError {
    return new BoardingPassError(
      BoardingPassErrorCode.InvalidJulianDay,
      `Invalid Julian day of year: ${dayOfYear}`,
      { dayOfYear },
    );
  }

  static unexpected(code: number): BoardingPassError {
    return new BoardingPassError(
      BoardingPassErrorCode.Unexpected,
      `Error code ${code} occured.`,
      { unexpectedCode: code },
    );
  }
}
