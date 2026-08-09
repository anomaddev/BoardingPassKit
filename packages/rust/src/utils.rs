use chrono::{DateTime, Datelike, NaiveDate, Utc};

use crate::BoardingPassError;

pub fn remove_leading_zeros(value: &str) -> String {
    let trimmed = value.trim_start_matches('0');
    trimmed.to_string()
}

fn is_leap_year(year: i32) -> bool {
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

fn max_day_of_year(year: i32) -> i32 {
    if is_leap_year(year) {
        366
    } else {
        365
    }
}

fn validate_day_of_year(day_of_year: i32, year: i32) -> Result<(), BoardingPassError> {
    if day_of_year < 1 || day_of_year > max_day_of_year(year) {
        return Err(BoardingPassError::invalid_julian_day(day_of_year));
    }
    Ok(())
}

fn date_from_ordinal(year: i32, day_of_year: i32) -> Result<NaiveDate, BoardingPassError> {
    validate_day_of_year(day_of_year, year)?;
    NaiveDate::from_yo_opt(year, day_of_year as u32)
        .ok_or_else(|| BoardingPassError::invalid_julian_day(day_of_year))
}

/// Round a day delta the same way JavaScript `Math.round` does
/// (half away from zero / half towards +inf for positive values via floor(x+0.5)).
fn round_diff_days(ms: i64) -> i64 {
    let days = ms as f64 / 86_400_000.0;
    days.round() as i64
}

/// Convert a BCBP Julian day-of-year to a calendar date.
///
/// Provide either an explicit `year`, or omit it to infer from `relative_to`
/// (defaulting to now) using ±183 day year-boundary logic.
///
/// Year inference uses the **UTC** year of `relative_to` (unlike Node's
/// `Date#getFullYear()`, which is local-timezone dependent). Pass an explicit
/// `year` when local-civil-year behavior is required.
pub fn julian_to_calendar_date(
    day_of_year: i32,
    year: Option<i32>,
    relative_to: Option<DateTime<Utc>>,
) -> Result<NaiveDate, BoardingPassError> {
    if let Some(year) = year {
        return date_from_ordinal(year, day_of_year);
    }

    let reference = relative_to.unwrap_or_else(Utc::now);
    let ref_year = reference.year();
    validate_day_of_year(day_of_year, ref_year)?;

    let mut candidate = date_from_ordinal(ref_year, day_of_year)?;
    let candidate_dt = candidate
        .and_hms_opt(0, 0, 0)
        .map(|ndt| DateTime::<Utc>::from_naive_utc_and_offset(ndt, Utc))
        .ok_or_else(|| BoardingPassError::invalid_julian_day(day_of_year))?;

    let diff_days = round_diff_days((candidate_dt - reference).num_milliseconds());

    if diff_days < -183 {
        let next_year = ref_year + 1;
        candidate = date_from_ordinal(next_year, day_of_year)?;
    } else if diff_days > 183 {
        let previous_year = ref_year - 1;
        candidate = date_from_ordinal(previous_year, day_of_year)?;
    }

    Ok(candidate)
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::{Duration, TimeZone};

    #[test]
    fn remove_leading_zeros_basic() {
        assert_eq!(remove_leading_zeros("008F"), "8F");
        assert_eq!(remove_leading_zeros("0000"), "");
        assert_eq!(remove_leading_zeros("2819"), "2819");
        assert_eq!(remove_leading_zeros("0"), "");
        assert_eq!(remove_leading_zeros("0ABC"), "ABC");
    }

    #[test]
    fn julian_explicit_year() {
        let date = julian_to_calendar_date(14, Some(2025), None).unwrap();
        assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 14).unwrap());
    }

    #[test]
    fn julian_year_inference_forward() {
        let relative = Utc.with_ymd_and_hms(2025, 12, 20, 0, 0, 0).unwrap();
        let date = julian_to_calendar_date(14, None, Some(relative)).unwrap();
        assert_eq!(date, NaiveDate::from_ymd_opt(2026, 1, 14).unwrap());
    }

    #[test]
    fn julian_round_boundary_matches_js_math_round() {
        // Node: Math.round((candidate - reference) / MS_PER_DAY)
        // At -183.6 days, JS rounds to -184 (< -183) → next year.
        let relative = Utc
            .with_ymd_and_hms(2024, 1, 1, 0, 0, 0)
            .unwrap()
            + Duration::milliseconds((183.6 * 86_400_000.0) as i64);
        let date = julian_to_calendar_date(1, None, Some(relative)).unwrap();
        assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 1).unwrap());
    }

    #[test]
    fn julian_invalid_day() {
        let err = julian_to_calendar_date(400, Some(2025), None).unwrap_err();
        assert!(matches!(
            err.code,
            crate::BoardingPassErrorCode::InvalidJulianDay
        ));
    }
}
