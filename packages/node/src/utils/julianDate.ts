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

/**
 * BCBP date of issue is four characters: the last digit of the year, then a
 * three-digit Julian day. The flight field stores only the Julian day.
 *
 * When the flight day is on or after the issue day they share that year.
 * When the flight day is earlier, the pass was issued late in the year for a
 * flight early the next year.
 *
 * Among years ending in that digit, the issue date closest to `relativeTo` wins.
 * Returns null when `issueDate` is not `YDDD`.
 */
export function flightYearFromIssueDate(
  issueDate: string,
  flightDayOfYear: number,
  relativeTo: Date = new Date(),
): number | null {
  const match = /^(\d)(\d{3})$/.exec(issueDate);
  if (!match) return null;

  const yearDigit = Number(match[1]);
  const issueDay = Number(match[2]);
  if (issueDay < 1 || issueDay > 366) return null;

  const refYear = relativeTo.getFullYear();
  const base = Math.floor(refYear / 10) * 10 + yearDigit;
  const refMs = relativeTo.getTime();

  let best: { flightYear: number; distance: number } | null = null;
  for (const issueYear of [base - 10, base, base + 10]) {
    if (issueDay > maxDayOfYear(issueYear)) continue;
    const flightYear = flightDayOfYear >= issueDay ? issueYear : issueYear + 1;
    if (flightDayOfYear < 1 || flightDayOfYear > maxDayOfYear(flightYear)) continue;

    const distance = Math.abs(Date.UTC(issueYear, 0, issueDay) - refMs);
    if (!best || distance < best.distance) {
      best = { flightYear, distance };
    }
  }

  return best?.flightYear ?? null;
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
