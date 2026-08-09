//! IATA BCBP (Resolution 792, Version 8) boarding pass decoder.

mod decoder;
mod demo;
mod error;
mod types;
mod utils;

pub use decoder::BoardingPassDecoder;
pub use demo::{demo_data, demo_keys, DemoDataKey, DEMO_DATA};
pub use error::{BoardingPassError, BoardingPassErrorCode};
pub use types::{
    BoardingPass, BoardingPassInfo, BoardingPassLeg, BoardingPassLegData, BoardingPassSecurityData,
    FlightDateOptions,
};
pub use utils::{julian_to_calendar_date, remove_leading_zeros};
