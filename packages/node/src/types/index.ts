export interface BoardingPassLegData {
  readonly segmentSize: number;
  airlineCode: string;
  ticketNumber: string;
  selectee: string;
  internationalDoc: string;
  ticketingCarrier: string;
  ffAirline: string;
  ffNumber: string;
  idAdIndicator: string | null;
  freeBags: string | null;
  fastTrack: string | null;
  airlineUse: string | null;
}

export interface BoardingPassLeg {
  readonly legIndex: number;
  readonly pnrCode: string;
  readonly origin: string;
  readonly destination: string;
  readonly operatingCarrier: string;
  readonly flightno: string;
  readonly julianDate: number;
  readonly compartment: string;
  readonly seatno: string;
  readonly checkIn: number | null;
  readonly passengerStatus: string;
  readonly conditionalSize: number;
  conditionalData: BoardingPassLegData | null;
  flightDate(options?: FlightDateOptions): Date | null;
}

export interface FlightDateOptions {
  relativeTo?: Date;
  year?: number;
}

export interface BoardingPassInfo {
  readonly beginningChar: string;
  readonly version: string;
  readonly fieldSize: number;
  passengerDescription: string | null;
  checkInSource: string | null;
  passSource: string | null;
  issueDate: string | null;
  documentType: string | null;
  readonly issuingAirline: string;
  bagTags: string[];
}

export interface BoardingPassSecurityData {
  beginSecurity: string | null;
  securityType: string | null;
  securitylength: number | null;
  securityData: string | null;
}

export interface BoardingPass {
  format: string;
  numberOfLegs: number;
  passengerName: string;
  ticketIndicator: string;
  boardingPassLegs: BoardingPassLeg[];
  passInfo: BoardingPassInfo;
  securityData: BoardingPassSecurityData | null;
  airlineBlob: string | null;
  readonly code: string;
}
