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

  // AA YUL-PHL: IATA space-pads FF / ID-AD / bags / fast-track. Copy/paste and
  // some scanners strip those trailing spaces, which used to throw
  // ConditionalIndexInvalid (endConditional 23 / subConditional 23).
  const yulPhlVisible =
    'M1ACKERMANN/JUSTIN DAVESWMUYT YULPHLAA 5717 176Y002A0034 147>1180RO4176BAA              29001701407985430   AA 76UXK84';
  const yulPhlPadded = yulPhlVisible.padEnd(60 + 0x47, ' ');

  function expectYulPhl(pass: ReturnType<BoardingPassDecoder['decode']>) {
    expect(pass.format).toBe('M');
    expect(pass.numberOfLegs).toBe(1);
    expect(pass.passengerName).toBe('ACKERMANN/JUSTIN DAV');
    expect(pass.boardingPassLegs).toHaveLength(1);
    const leg = pass.boardingPassLegs[0]!;
    expect(leg.origin).toBe('YUL');
    expect(leg.destination).toBe('PHL');
    expect(leg.operatingCarrier).toBe('AA');
    expect(leg.flightno).toBe('5717');
    expect(leg.julianDate).toBe(176);
    expect(leg.seatno).toBe('2A');
    expect(leg.conditionalData?.ticketNumber).toBe('7014079854');
    expect(leg.conditionalData?.ffAirline).toBe('AA');
    expect(leg.conditionalData?.ffNumber).toBe('76UXK84');
  }

  it('decodes an AA YUL-PHL pass with trailing IATA space padding', () => {
    expect(yulPhlPadded).toHaveLength(131);
    expectYulPhl(decoder.decode(yulPhlPadded));
  });

  it('decodes an AA YUL-PHL pass after trailing spaces are stripped', () => {
    expect(yulPhlVisible).toHaveLength(118);
    expectYulPhl(decoder.decode(yulPhlVisible));
  });
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
