import { describe, expect, it } from 'vitest';
import { BoardingPassDecoder } from '../src/decoder/BoardingPassDecoder.js';
import { BoardingPassError, BoardingPassErrorCode } from '../src/errors/BoardingPassError.js';
import { DemoData } from '../src/demo/DemoData.js';

describe('BoardingPassDecoder', () => {
  const decoder = new BoardingPassDecoder();
  decoder.debug = false;

  it('decodes Simple demo data', () => {
    const pass = decoder.decode(DemoData.Simple);
    expect(pass.format).toBe('M');
    expect(pass.numberOfLegs).toBe(1);
    expect(pass.passengerName).toBe('ACKERMANN/JUSTIN DAV');
    expect(pass.boardingPassLegs).toHaveLength(1);
    expect(pass.boardingPassLegs[0]!.origin).toBe('MSY');
    expect(pass.boardingPassLegs[0]!.destination).toBe('PHX');
    expect(pass.boardingPassLegs[0]!.operatingCarrier).toBe('AA');
    expect(pass.boardingPassLegs[0]!.flightno).toBe('2819');
    expect(pass.boardingPassLegs[0]!.julianDate).toBe(14);
    expect(pass.code).toBe(DemoData.Simple);
  });

  it('decodes Historical demo data', () => {
    const pass = decoder.decode(DemoData.Historical);
    expect(pass.numberOfLegs).toBe(1);
    expect(pass.boardingPassLegs[0]!.origin).toBe('TPA');
    expect(pass.boardingPassLegs[0]!.destination).toBe('DFW');
    expect(pass.boardingPassLegs[0]!.julianDate).toBe(91);
  });

  it('decodes MultiLeg demo data with security block', () => {
    const pass = decoder.decode(DemoData.MultiLeg);
    expect(pass.numberOfLegs).toBe(2);
    expect(pass.boardingPassLegs).toHaveLength(2);
    expect(pass.boardingPassLegs[0]!.origin).toBe('TPA');
    expect(pass.boardingPassLegs[0]!.destination).toBe('SEA');
    expect(pass.boardingPassLegs[1]!.origin).toBe('SEA');
    expect(pass.boardingPassLegs[1]!.destination).toBe('JNU');
    expect(pass.securityData).not.toBeNull();
    expect(pass.securityData!.securityType).toBe('4');
    expect(pass.securityData!.securityData).toContain('MEQCIC');
  });

  it('decodes International demo data', () => {
    const pass = decoder.decode(DemoData.International);
    expect(pass.boardingPassLegs[0]!.origin).toBe('SIN');
    expect(pass.boardingPassLegs[0]!.destination).toBe('NRT');
    expect(pass.boardingPassLegs[0]!.operatingCarrier).toBe('JL');
    expect(pass.boardingPassLegs[0]!.julianDate).toBe(336);
  });

  it('decodes from Buffer input', () => {
    const pass = decoder.decode(Buffer.from(DemoData.Simple, 'ascii'));
    expect(pass.format).toBe('M');
  });

  // AA version-1 passes space-pad FF / ID-AD / bags / fast-track. Copy/paste
  // and some scanners strip those trailing spaces, which used to throw
  // ConditionalIndexInvalid (endConditional 23 / subConditional 23).
  const strippedConditionalPasses = [
    {
      name: 'YUL-PHL',
      visible:
        'M1ACKERMANN/JUSTIN DAVESWMUYT YULPHLAA 5717 176Y002A0034 147>1180RO4176BAA              29001701407985430   AA 76UXK84',
      origin: 'YUL',
      destination: 'PHL',
      flightno: '5717',
      julianDate: 176,
      seatno: '2A',
      ticketNumber: '7014079854',
    },
    {
      name: 'TPA-DCA',
      visible:
        'M1ACKERMANN/JUSTIN DAVEYALLND TPADCAAA 0374 196Y008A0062 147>1180RO4196BAA              29001707442252231   AA 76UXK84',
      origin: 'TPA',
      destination: 'DCA',
      flightno: '374',
      julianDate: 196,
      seatno: '8A',
      ticketNumber: '7074422522',
    },
  ] as const;

  it.each(strippedConditionalPasses)(
    'decodes an AA $name pass with trailing IATA space padding',
    (fixture) => {
      const padded = fixture.visible.padEnd(60 + 0x47, ' ');
      expect(padded).toHaveLength(131);
      const pass = decoder.decode(padded);
      const leg = pass.boardingPassLegs[0]!;
      expect(leg.origin).toBe(fixture.origin);
      expect(leg.destination).toBe(fixture.destination);
      expect(leg.flightno).toBe(fixture.flightno);
      expect(leg.julianDate).toBe(fixture.julianDate);
      expect(leg.seatno).toBe(fixture.seatno);
      expect(leg.conditionalData?.ticketNumber).toBe(fixture.ticketNumber);
      expect(leg.conditionalData?.ffAirline).toBe('AA');
      expect(leg.conditionalData?.ffNumber).toBe('76UXK84');
    },
  );

  it.each(strippedConditionalPasses)(
    'decodes an AA $name pass after trailing spaces are stripped',
    (fixture) => {
      expect(fixture.visible).toHaveLength(118);
      const pass = decoder.decode(fixture.visible);
      const leg = pass.boardingPassLegs[0]!;
      expect(leg.origin).toBe(fixture.origin);
      expect(leg.destination).toBe(fixture.destination);
      expect(leg.operatingCarrier).toBe('AA');
      expect(leg.flightno).toBe(fixture.flightno);
      expect(leg.julianDate).toBe(fixture.julianDate);
      expect(leg.seatno).toBe(fixture.seatno);
      expect(leg.conditionalData?.ticketNumber).toBe(fixture.ticketNumber);
      expect(leg.conditionalData?.ffAirline).toBe('AA');
      expect(leg.conditionalData?.ffNumber).toBe('76UXK84');
    },
  );
});

describe('BoardingPassDecoder errors', () => {
  const decoder = new BoardingPassDecoder();
  decoder.debug = false;

  it('throws MandatoryItemNotFound for truncated input', () => {
    expect(() => decoder.decode('M1ACKERMANN/JUSTIN')).toThrow(BoardingPassError);
    try {
      decoder.decode('M1ACKERMANN/JUSTIN');
    } catch (error) {
      expect(error).toBeInstanceOf(BoardingPassError);
      expect((error as BoardingPassError).code).toBe(BoardingPassErrorCode.MandatoryItemNotFound);
    }
  });
});
