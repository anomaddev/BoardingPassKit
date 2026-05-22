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
