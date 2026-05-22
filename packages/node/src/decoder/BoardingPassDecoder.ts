import { BoardingPassError } from '../errors/BoardingPassError.js';
import type {
  BoardingPass,
  BoardingPassInfo,
  BoardingPassLeg,
  BoardingPassLegData,
  BoardingPassSecurityData,
  FlightDateOptions,
} from '../types/index.js';
import { julianToCalendarDate } from '../utils/julianDate.js';
import { removeLeadingZeros } from '../utils/removeLeadingZeros.js';

function emptyLegData(): BoardingPassLegData {
  return {
    segmentSize: 0,
    airlineCode: '',
    ticketNumber: '',
    selectee: '',
    internationalDoc: '',
    ticketingCarrier: '',
    ffAirline: '',
    ffNumber: '',
    idAdIndicator: null,
    freeBags: null,
    fastTrack: null,
    airlineUse: null,
  };
}

function emptyPassInfo(): BoardingPassInfo {
  return {
    beginningChar: '',
    version: '',
    fieldSize: 0,
    passengerDescription: null,
    checkInSource: null,
    passSource: null,
    issueDate: null,
    documentType: null,
    issuingAirline: '',
    bagTags: [],
  };
}

function attachFlightDate(leg: Omit<BoardingPassLeg, 'flightDate'>): BoardingPassLeg {
  return {
    ...leg,
    flightDate(options?: FlightDateOptions): Date | null {
      try {
        if (options?.year !== undefined) {
          return julianToCalendarDate(this.julianDate, options.year);
        }
        return julianToCalendarDate(this.julianDate, options?.relativeTo);
      } catch {
        return null;
      }
    },
  };
}

export class BoardingPassDecoder {
  private index = 0;
  private subConditional = 0;
  private endConditional = 0;

  debug = true;
  trimLeadingZeroes = true;
  trimWhitespace = true;
  emptyStringIsNil = true;

  data: Buffer | null = null;
  code: string | null = null;

  decode(input: string | Buffer | Uint8Array): BoardingPass {
    if (typeof input === 'string') {
      this.data = Buffer.from(input, 'ascii');
      this.code = input;
    } else {
      this.data = Buffer.from(input);
      this.code = this.raw(this.data);
    }
    return this.breakdown();
  }

  private raw(data: Buffer): string {
    const str = data.toString('ascii');
    if (str.includes('\uFFFD')) {
      throw BoardingPassError.dataFailedStringDecoding();
    }
    return str;
  }

  private applyEmptyStringIsNil(value: string | null | undefined): string | null {
    if (value == null) return null;
    return this.emptyStringIsNil && value.length === 0 ? null : value;
  }

  private breakdown(): BoardingPass {
    if (!this.data || !this.code) {
      throw BoardingPassError.dataFailedStringDecoding();
    }

    if (this.debug) {
      console.log('PARSING BOARDING PASS...');
    }

    this.index = 0;
    this.subConditional = 0;
    this.endConditional = 0;

    const format = this.mandatory(1);
    const numberOfLegs = this.readint(1);
    const name = this.mandatory(20);
    const ticketIndicator = this.mandatory(1);

    if (numberOfLegs == null) {
      throw BoardingPassError.dataFailedValidation('Number of legs is nil');
    }

    const legs: BoardingPassLeg[] = [];

    let firstLeg = this.repeatedMandatory(0);
    this.endConditional = firstLeg.conditionalSize;
    if (this.debug) {
      console.log(`SET endConditional: ${this.endConditional}`);
    }

    let passInfo: BoardingPassInfo;
    let firstLegConditional: BoardingPassLegData;

    if (this.endConditional > 0) {
      passInfo = this.uniqueConditional();
      firstLegConditional = this.repeatedConditional();
    } else {
      if (this.debug) {
        console.log('No conditional data available (endConditional = 0)');
      }
      passInfo = emptyPassInfo();
      firstLegConditional = emptyLegData();
    }

    firstLeg.conditionalData = firstLegConditional;
    legs.push(firstLeg);

    const legsRemaining = numberOfLegs - 1;
    if (this.debug) {
      console.log(`LEGS REMAINING: ${legsRemaining}`);
    }

    if (legsRemaining > 0) {
      for (let i = 1; i < numberOfLegs; i++) {
        if (this.debug) {
          console.log(`Looping for leg: ${i}`);
        }

        let leg = this.repeatedMandatory(i);
        this.endConditional = leg.conditionalSize;
        if (this.debug) {
          console.log(`SET endConditional: ${this.endConditional}`);
        }

        let legConditional: BoardingPassLegData;
        if (this.endConditional > 0) {
          legConditional = this.repeatedConditional();
        } else {
          if (this.debug) {
            console.log(`No conditional data available for leg ${i} (endConditional = 0)`);
          }
          legConditional = emptyLegData();
        }
        leg.conditionalData = legConditional;
        legs.push(leg);
      }
    }

    if (this.debug) {
      console.log('PARSING LEGS COMPLETE');
    }

    legs.sort((a, b) => a.legIndex - b.legIndex);

    let security: BoardingPassSecurityData | null = null;
    let blob: string | null = null;

    if (this.index < this.data.length) {
      const firstChar = this.data.toString('ascii', this.index, this.index + 1);
      if (firstChar === '^') {
        const beginSecurity = this.mandatory(1);
        const typeSecurity = this.mandatory(1);
        const lengthSecurity = this.readhex(2, true);
        const securityData = this.mandatory(lengthSecurity);

        security = {
          beginSecurity: this.applyEmptyStringIsNil(beginSecurity),
          securityType: this.applyEmptyStringIsNil(typeSecurity),
          securitylength: lengthSecurity,
          securityData: this.applyEmptyStringIsNil(securityData),
        };
      }
    }

    if (this.index < this.data.length) {
      let remainingString = this.data.toString('ascii', this.index);
      if (this.trimWhitespace) {
        remainingString = remainingString.trim();
      }
      blob = this.applyEmptyStringIsNil(remainingString);
      this.index = this.data.length;
    }

    if (this.subConditional !== 0) {
      throw BoardingPassError.unexpected(this.subConditional);
    }

    if (this.debug) {
      console.log('parsed boarding pass...');
      console.log('======================');
      console.log('Boarding Pass:');
      console.log(this.code);
      console.log('======================');
    }

    return {
      format,
      numberOfLegs,
      passengerName: name,
      ticketIndicator,
      boardingPassLegs: legs,
      passInfo,
      securityData: security,
      airlineBlob: blob,
      code: this.code,
    };
  }

  private mandatory(length: number): string {
    if (this.data!.length < this.index + length) {
      throw BoardingPassError.mandatoryItemNotFound(this.index);
    }

    let string = this.readdata(length);
    if (this.debug) {
      console.log(`MANDATORY: ${string}`);
    }

    if (this.trimWhitespace) {
      string = string.trim();
    }

    return string;
  }

  private conditional(length: number): string {
    if (this.data!.length < this.index + length && this.endConditional > 0) {
      throw BoardingPassError.conditionalIndexInvalid(this.endConditional, this.subConditional);
    }

    if (this.subConditional !== 0) {
      this.subConditional -= length;
    }

    if (this.endConditional !== 0) {
      this.endConditional -= length;
    }

    let string = this.readdata(length);
    if (this.debug) {
      console.log(`CONDITIONAL: ${string}`);
      console.log(`SUB-CONDITIONAL: ${this.subConditional}`);
      console.log(`END CONDITIONAL: ${this.endConditional}`);
    }

    if (this.trimWhitespace) {
      string = string.trim();
    }

    return string;
  }

  private readint(length: number): number | null {
    let rawString = this.mandatory(length);
    if (this.debug) {
      console.log(`RAW INT: ${rawString}`);
    }

    if (this.trimWhitespace) {
      rawString = rawString.trim();
    }
    if (this.trimLeadingZeroes) {
      rawString = removeLeadingZeros(rawString);
    }
    if (this.emptyStringIsNil && rawString.length === 0) {
      return null;
    }
    if (!this.emptyStringIsNil && rawString.length === 0) {
      return 0;
    }

    const number = Number.parseInt(rawString, 10);
    if (Number.isNaN(number)) {
      throw BoardingPassError.fieldValueNotRequiredInteger(rawString);
    }

    return number;
  }

  private readdata(length: number): string {
    const subdata = this.data!.subarray(this.index, this.index + length);
    this.index += length;

    const rawString = subdata.toString('ascii');
    if (rawString.includes('\uFFFD')) {
      throw BoardingPassError.dataFailedStringDecoding();
    }
    return rawString;
  }

  private readhex(length: number, isMandatory = true): number {
    const str = isMandatory ? this.mandatory(length) : this.conditional(length);
    const int = Number.parseInt(str, 16);
    if (Number.isNaN(int)) {
      throw BoardingPassError.hexStringFailedDecoding(str);
    }

    if (this.debug) {
      console.log(`HEX: ${int}`);
    }
    return int;
  }

  private repeatedMandatory(legIndex: number): BoardingPassLeg {
    try {
      if (this.debug) {
        console.log('PARSING REPEATED MANDATORY');
      }

      const pnrCode = this.mandatory(7);
      const origin = this.mandatory(3);
      const destination = this.mandatory(3);
      const opCarrier = this.mandatory(3);
      let flightno = this.mandatory(5);
      const julianDate = this.readint(3);
      const compartment = this.mandatory(1);
      let seatno = this.mandatory(4);
      const checkIn = this.readint(5);
      const passengerStatus = this.mandatory(1);
      const fieldSize = this.readhex(2);

      if (this.trimLeadingZeroes) {
        flightno = removeLeadingZeros(flightno);
        seatno = removeLeadingZeros(seatno);
      }

      if (julianDate == null) {
        throw BoardingPassError.dataFailedValidation('Julian Date is nil');
      }

      return attachFlightDate({
        legIndex,
        pnrCode,
        origin,
        destination,
        operatingCarrier: opCarrier,
        flightno,
        julianDate,
        compartment,
        seatno,
        checkIn,
        passengerStatus,
        conditionalSize: fieldSize,
        conditionalData: null,
      });
    } catch (error) {
      if (error instanceof BoardingPassError) {
        throw error;
      }
      throw BoardingPassError.dataIsNotBoardingPass(error);
    }
  }

  private uniqueConditional(): BoardingPassInfo {
    try {
      if (this.debug) {
        console.log('PARSING UNIQUE CONDITIONAL');
      }

      const beginningChar = this.conditional(1);
      const version = this.conditional(1);
      const fieldSize = this.readhex(2, false);

      this.subConditional = fieldSize;
      if (this.debug) {
        console.log(`SET subConditional: ${this.subConditional}`);
      }

      if (fieldSize === 0) {
        if (this.debug) {
          console.log('Unique conditional field size is 0, returning empty pass info');
        }
        return {
          beginningChar,
          version,
          fieldSize,
          passengerDescription: null,
          checkInSource: null,
          passSource: null,
          issueDate: null,
          documentType: null,
          issuingAirline: '',
          bagTags: [],
        };
      }

      let passDesc: string | null = this.conditional(1);
      let checkSource: string | null = this.conditional(1);
      let passSource: string | null = this.conditional(1);
      let issueDate: string | null = this.conditional(4);
      let docType: string | null = this.conditional(1);
      const airlineCode = this.conditional(3);

      if (this.trimLeadingZeroes && issueDate != null) {
        issueDate = removeLeadingZeros(issueDate);
      }

      passDesc = this.applyEmptyStringIsNil(passDesc);
      checkSource = this.applyEmptyStringIsNil(checkSource);
      passSource = this.applyEmptyStringIsNil(passSource);
      issueDate = this.applyEmptyStringIsNil(issueDate);
      docType = this.applyEmptyStringIsNil(docType);

      const bagTags: string[] = [];
      while (this.subConditional >= 13) {
        const tag = this.conditional(13);
        if (tag.length > 0 && (!this.emptyStringIsNil || tag.trim().length > 0)) {
          bagTags.push(tag);
        }
      }

      if (this.subConditional > 0) {
        try {
          this.conditional(this.subConditional);
        } catch {
          // defensive consume, matching Swift try?
        }
        this.subConditional = 0;
      }

      return {
        beginningChar,
        version,
        fieldSize,
        passengerDescription: passDesc,
        checkInSource: checkSource,
        passSource,
        issueDate,
        documentType: docType,
        issuingAirline: airlineCode,
        bagTags,
      };
    } catch (error) {
      if (error instanceof BoardingPassError) {
        throw error;
      }
      throw BoardingPassError.dataIsNotBoardingPass(error);
    }
  }

  private repeatedConditional(): BoardingPassLegData {
    try {
      if (this.debug) {
        console.log('PARSING REPEATED CONDITIONAL');
      }

      const fieldSize = this.readhex(2, false);
      this.subConditional = fieldSize;
      if (this.debug) {
        console.log(`SET subConditional: ${this.subConditional}`);
      }

      if (fieldSize === 0) {
        if (this.debug) {
          console.log('Field size is 0, returning empty leg data');
        }
        return emptyLegData();
      }

      if (this.subConditional > this.endConditional) {
        throw BoardingPassError.boardingPassLegConditionalMismatch();
      }

      if (this.debug) {
        console.log('');
        console.log(`Sub Conditional Check Passed: ${fieldSize}`);
        console.log('');
      }

      const airlineNumeric = this.conditional(3);
      const documentNumber = this.conditional(10);
      const selectee = this.conditional(1);
      const internationalDoc = this.conditional(1);
      const marketingCarrier = this.conditional(3);

      const ffFieldSize = Math.max(0, fieldSize - 23);

      if (this.debug) {
        console.log(`Conditional chars left: ${this.subConditional}`);
        console.log(`Freq Flyer size: ${ffFieldSize}`);
      }

      const ffInfo = ffFieldSize > 0 ? this.conditional(ffFieldSize) : '';
      const parsedFFAirline = this.trimWhitespace ? ffInfo.slice(0, 3).trim() : ffInfo.slice(0, 3);
      const parsedFFNumber =
        ffInfo.length > 3
          ? this.trimWhitespace
            ? ffInfo.slice(3).trim()
            : ffInfo.slice(3)
          : '';

      if (this.debug) {
        console.log(`FF Airline: ${parsedFFAirline}`);
        console.log(`FF Number: ${parsedFFNumber}`);
        console.log('');
        console.log(`Parsed Freq Flyer Info: ${ffInfo}`);
        console.log(`Conditional chars left: ${this.subConditional}`);
      }

      let idAdIndicator: string | null = this.conditional(1);
      let freeBags: string | null = this.conditional(3);
      let fastTrack: string | null = this.conditional(1);

      let airlineUse: string | null = null;
      const leftOver = this.endConditional - this.subConditional;
      if (leftOver > 0) {
        airlineUse = this.conditional(leftOver);
      }

      idAdIndicator = this.applyEmptyStringIsNil(idAdIndicator);
      freeBags = this.applyEmptyStringIsNil(freeBags);
      fastTrack = this.applyEmptyStringIsNil(fastTrack);
      airlineUse = this.applyEmptyStringIsNil(airlineUse);

      if (this.endConditional !== this.subConditional) {
        throw BoardingPassError.boardingPassLegConditionalMismatch();
      }

      if (this.debug) {
        console.log('');
        console.log('Sub Conditional Parsing Complete!');
        console.log('');
      }

      return {
        segmentSize: fieldSize,
        airlineCode: airlineNumeric,
        ticketNumber: documentNumber,
        selectee,
        internationalDoc,
        ticketingCarrier: marketingCarrier,
        ffAirline: parsedFFAirline,
        ffNumber: parsedFFNumber,
        idAdIndicator,
        freeBags,
        fastTrack,
        airlineUse,
      };
    } catch (error) {
      if (error instanceof BoardingPassError) {
        throw error;
      }
      throw BoardingPassError.dataIsNotBoardingPass(error);
    }
  }
}
