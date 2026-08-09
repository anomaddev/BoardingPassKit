use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};

use crate::utils::julian_to_calendar_date;
use crate::BoardingPassError;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BoardingPassLegData {
    pub segment_size: i32,
    pub airline_code: String,
    pub ticket_number: String,
    pub selectee: String,
    pub international_doc: String,
    pub ticketing_carrier: String,
    pub ff_airline: String,
    pub ff_number: String,
    pub id_ad_indicator: Option<String>,
    pub free_bags: Option<String>,
    pub fast_track: Option<String>,
    pub airline_use: Option<String>,
}

impl BoardingPassLegData {
    pub fn empty() -> Self {
        Self {
            segment_size: 0,
            airline_code: String::new(),
            ticket_number: String::new(),
            selectee: String::new(),
            international_doc: String::new(),
            ticketing_carrier: String::new(),
            ff_airline: String::new(),
            ff_number: String::new(),
            id_ad_indicator: None,
            free_bags: None,
            fast_track: None,
            airline_use: None,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BoardingPassLeg {
    pub leg_index: i32,
    pub pnr_code: String,
    pub origin: String,
    pub destination: String,
    pub operating_carrier: String,
    pub flightno: String,
    pub julian_date: i32,
    pub compartment: String,
    pub seatno: String,
    pub check_in: Option<i32>,
    pub passenger_status: String,
    pub conditional_size: i32,
    pub conditional_data: Option<BoardingPassLegData>,
}

#[derive(Debug, Clone, Copy, Default)]
pub struct FlightDateOptions {
    pub relative_to: Option<DateTime<Utc>>,
    pub year: Option<i32>,
}

impl BoardingPassLeg {
    pub fn flight_date(
        &self,
        options: FlightDateOptions,
    ) -> Result<NaiveDate, BoardingPassError> {
        if let Some(year) = options.year {
            julian_to_calendar_date(self.julian_date, Some(year), None)
        } else {
            julian_to_calendar_date(self.julian_date, None, options.relative_to)
        }
    }

    /// Node/Swift-style helper that returns `None` instead of an error on invalid days.
    pub fn flight_date_opt(&self, options: FlightDateOptions) -> Option<NaiveDate> {
        self.flight_date(options).ok()
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BoardingPassInfo {
    pub beginning_char: String,
    pub version: String,
    pub field_size: i32,
    pub passenger_description: Option<String>,
    pub check_in_source: Option<String>,
    pub pass_source: Option<String>,
    pub issue_date: Option<String>,
    pub document_type: Option<String>,
    pub issuing_airline: String,
    pub bag_tags: Vec<String>,
}

impl BoardingPassInfo {
    pub fn empty() -> Self {
        Self {
            beginning_char: String::new(),
            version: String::new(),
            field_size: 0,
            passenger_description: None,
            check_in_source: None,
            pass_source: None,
            issue_date: None,
            document_type: None,
            issuing_airline: String::new(),
            bag_tags: Vec::new(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BoardingPassSecurityData {
    pub begin_security: Option<String>,
    pub security_type: Option<String>,
    #[serde(rename = "securitylength")]
    pub security_length: Option<i32>,
    pub security_data: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BoardingPass {
    pub format: String,
    pub number_of_legs: i32,
    pub passenger_name: String,
    pub ticket_indicator: String,
    pub boarding_pass_legs: Vec<BoardingPassLeg>,
    pub pass_info: BoardingPassInfo,
    pub security_data: Option<BoardingPassSecurityData>,
    pub airline_blob: Option<String>,
    pub code: String,
}
