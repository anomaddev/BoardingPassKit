import { BoardingPassError } from '../errors/BoardingPassError.js';

const MS_PER_DAY = 86_400_000;

function isLeapYear(year: number): boolean {
  return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
}

function maxDayOfYear(year: number): number {
  return isLeapYear(year) ? 366 : 365;
}

function validateDayOfYear(dayOfYear: number, year: number): void {
  if (!Number.isInteger(dayOfYear) || dayOfYear < 1 || dayOfYear > maxDayOfYear(year)) {
    throw BoardingPassError.invalidJulianDay(dayOfYear);
  }
}

export function julianToCalendarDate(dayOfYear: number, year: number): Date;
export function julianToCalendarDate(dayOfYear: number, relativeTo?: Date): Date;
export function julianToCalendarDate(dayOfYear: number, yearOrRelative?: number | Date): Date {
  if (typeof yearOrRelative === 'number') {
    validateDayOfYear(dayOfYear, yearOrRelative);
    return new Date(Date.UTC(yearOrRelative, 0, dayOfYear));
  }

  const reference = yearOrRelative ?? new Date();
  const refYear = reference.getFullYear();
  validateDayOfYear(dayOfYear, refYear);

  let candidate = new Date(Date.UTC(refYear, 0, dayOfYear));
  const diffDays = Math.round((candidate.getTime() - reference.getTime()) / MS_PER_DAY);

  if (diffDays < -183) {
    const nextYear = refYear + 1;
    validateDayOfYear(dayOfYear, nextYear);
    candidate = new Date(Date.UTC(nextYear, 0, dayOfYear));
  } else if (diffDays > 183) {
    const previousYear = refYear - 1;
    validateDayOfYear(dayOfYear, previousYear);
    candidate = new Date(Date.UTC(previousYear, 0, dayOfYear));
  }

  return candidate;
}
