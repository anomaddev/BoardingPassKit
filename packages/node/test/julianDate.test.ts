import { describe, expect, it } from 'vitest';
import { julianToCalendarDate } from '../src/utils/julianDate.js';
import { BoardingPassError, BoardingPassErrorCode } from '../src/errors/BoardingPassError.js';

describe('julianToCalendarDate', () => {
  it('converts day 001 to January 1', () => {
    const date = julianToCalendarDate(1, 2024);
    expect(date.getUTCFullYear()).toBe(2024);
    expect(date.getUTCMonth()).toBe(0);
    expect(date.getUTCDate()).toBe(1);
  });

  it('converts day 365 in a non-leap year', () => {
    const date = julianToCalendarDate(365, 2023);
    expect(date.getUTCMonth()).toBe(11);
    expect(date.getUTCDate()).toBe(31);
  });

  it('converts day 366 in a leap year', () => {
    const date = julianToCalendarDate(366, 2024);
    expect(date.getUTCMonth()).toBe(11);
    expect(date.getUTCDate()).toBe(31);
  });

  it('infers next year when reference is late-year and day is early January', () => {
    const reference = new Date(Date.UTC(2024, 7, 1));
    const date = julianToCalendarDate(14, reference);
    expect(date.getUTCFullYear()).toBe(2025);
    expect(date.getUTCMonth()).toBe(0);
    expect(date.getUTCDate()).toBe(14);
  });

  it('infers previous year when reference is early January and day is late December', () => {
    const reference = new Date(Date.UTC(2025, 0, 15));
    const date = julianToCalendarDate(365, reference);
    expect(date.getUTCFullYear()).toBe(2024);
    expect(date.getUTCMonth()).toBe(11);
    expect(date.getUTCDate()).toBe(30);
  });

  it('throws for invalid day 0', () => {
    expect(() => julianToCalendarDate(0, 2024)).toThrow(BoardingPassError);
    try {
      julianToCalendarDate(0, 2024);
    } catch (error) {
      expect((error as BoardingPassError).code).toBe(BoardingPassErrorCode.InvalidJulianDay);
    }
  });

  it('throws for day 367', () => {
    expect(() => julianToCalendarDate(367, 2024)).toThrow(BoardingPassError);
  });

  it('throws for day 366 in non-leap year', () => {
    expect(() => julianToCalendarDate(366, 2023)).toThrow(BoardingPassError);
  });
});
