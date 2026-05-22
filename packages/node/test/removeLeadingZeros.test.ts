import { describe, expect, it } from 'vitest';
import { removeLeadingZeros } from '../src/utils/removeLeadingZeros.js';

describe('removeLeadingZeros', () => {
  it('strips leading zeros from numeric strings', () => {
    expect(removeLeadingZeros('00123')).toBe('123');
    expect(removeLeadingZeros('00000')).toBe('');
    expect(removeLeadingZeros('12345')).toBe('12345');
    expect(removeLeadingZeros('0')).toBe('');
    expect(removeLeadingZeros('')).toBe('');
    expect(removeLeadingZeros('01234')).toBe('1234');
    expect(removeLeadingZeros('00001')).toBe('1');
  });

  it('preserves non-numeric strings', () => {
    expect(removeLeadingZeros('ABC')).toBe('ABC');
    expect(removeLeadingZeros('0ABC')).toBe('ABC');
  });
});
