use crate::types::{
    BoardingPass, BoardingPassInfo, BoardingPassLeg, BoardingPassLegData, BoardingPassSecurityData,
};
use crate::utils::remove_leading_zeros;
use crate::BoardingPassError;

pub struct BoardingPassDecoder {
    index: usize,
    sub_conditional: i32,
    end_conditional: i32,
    data: Vec<u8>,
    code: String,

    pub debug: bool,
    pub trim_leading_zeroes: bool,
    pub trim_whitespace: bool,
    pub empty_string_is_nil: bool,
}

impl Default for BoardingPassDecoder {
    fn default() -> Self {
        Self::new()
    }
}

impl BoardingPassDecoder {
    pub fn new() -> Self {
        Self {
            index: 0,
            sub_conditional: 0,
            end_conditional: 0,
            data: Vec::new(),
            code: String::new(),
            debug: true,
            trim_leading_zeroes: true,
            trim_whitespace: true,
            empty_string_is_nil: true,
        }
    }

    pub fn decode(&mut self, input: &str) -> Result<BoardingPass, BoardingPassError> {
        self.data = input.as_bytes().to_vec();
        self.code = input.to_string();
        self.breakdown()
    }

    pub fn decode_bytes(&mut self, input: &[u8]) -> Result<BoardingPass, BoardingPassError> {
        self.data = input.to_vec();
        // Latin-1 mapping matches Node's ability to accept non-UTF8 byte payloads.
        self.code = input.iter().map(|&b| b as char).collect();
        self.breakdown()
    }

    fn apply_empty_string_is_nil(&self, value: Option<String>) -> Option<String> {
        match value {
            None => None,
            Some(v) if self.empty_string_is_nil && v.is_empty() => None,
            Some(v) => Some(v),
        }
    }

    fn apply_empty_string_is_nil_str(&self, value: String) -> Option<String> {
        self.apply_empty_string_is_nil(Some(value))
    }

    fn log(&self, message: impl AsRef<str>) {
        if self.debug {
            eprintln!("{}", message.as_ref());
        }
    }

    fn breakdown(&mut self) -> Result<BoardingPass, BoardingPassError> {
        self.log("PARSING BOARDING PASS...");

        self.index = 0;
        self.sub_conditional = 0;
        self.end_conditional = 0;

        let format = self.mandatory(1)?;
        let number_of_legs = self
            .readint(1)?
            .ok_or_else(|| BoardingPassError::data_failed_validation("Number of legs is nil"))?;
        let name = self.mandatory(20)?;
        let ticket_indicator = self.mandatory(1)?;

        let mut legs: Vec<BoardingPassLeg> = Vec::new();

        let mut first_leg = self.repeated_mandatory(0)?;
        self.end_conditional = first_leg.conditional_size;
        self.log(format!("SET endConditional: {}", self.end_conditional));

        let (pass_info, first_leg_conditional) = if self.end_conditional > 0 {
            (self.unique_conditional()?, self.repeated_conditional()?)
        } else {
            self.log("No conditional data available (endConditional = 0)");
            (BoardingPassInfo::empty(), BoardingPassLegData::empty())
        };

        first_leg.conditional_data = Some(first_leg_conditional);
        legs.push(first_leg);

        let legs_remaining = number_of_legs - 1;
        self.log(format!("LEGS REMAINING: {legs_remaining}"));

        if legs_remaining > 0 {
            for i in 1..number_of_legs {
                self.log(format!("Looping for leg: {i}"));
                let mut leg = self.repeated_mandatory(i)?;
                self.end_conditional = leg.conditional_size;
                self.log(format!("SET endConditional: {}", self.end_conditional));

                let leg_conditional = if self.end_conditional > 0 {
                    self.repeated_conditional()?
                } else {
                    self.log(format!(
                        "No conditional data available for leg {i} (endConditional = 0)"
                    ));
                    BoardingPassLegData::empty()
                };
                leg.conditional_data = Some(leg_conditional);
                legs.push(leg);
            }
        }

        self.log("PARSING LEGS COMPLETE");
        legs.sort_by_key(|leg| leg.leg_index);

        let mut security: Option<BoardingPassSecurityData> = None;
        let mut blob: Option<String> = None;

        if self.index < self.data.len() {
            let first_char = self.data[self.index] as char;
            if first_char == '^' {
                let begin_security = self.mandatory(1)?;
                let type_security = self.mandatory(1)?;
                let length_security = self.readhex(2, true)?;
                let security_data = self.mandatory(length_security as usize)?;

                security = Some(BoardingPassSecurityData {
                    begin_security: self.apply_empty_string_is_nil_str(begin_security),
                    security_type: self.apply_empty_string_is_nil_str(type_security),
                    security_length: Some(length_security),
                    security_data: self.apply_empty_string_is_nil_str(security_data),
                });
            }
        }

        if self.index < self.data.len() {
            let mut remaining: String = self.data[self.index..]
                .iter()
                .map(|&b| b as char)
                .collect();
            if self.trim_whitespace {
                remaining = remaining.trim().to_string();
            }
            blob = self.apply_empty_string_is_nil_str(remaining);
            self.index = self.data.len();
        }

        if self.sub_conditional != 0 {
            return Err(BoardingPassError::unexpected(self.sub_conditional));
        }

        if self.debug {
            eprintln!("parsed boarding pass...");
            eprintln!("======================");
            eprintln!("Boarding Pass:");
            eprintln!("{}", self.code);
            eprintln!("======================");
        }

        Ok(BoardingPass {
            format,
            number_of_legs,
            passenger_name: name,
            ticket_indicator,
            boarding_pass_legs: legs,
            pass_info,
            security_data: security,
            airline_blob: blob,
            code: self.code.clone(),
        })
    }

    fn mandatory(&mut self, length: usize) -> Result<String, BoardingPassError> {
        if self.data.len() < self.index + length {
            return Err(BoardingPassError::mandatory_item_not_found(self.index));
        }

        let mut string = self.readdata(length)?;
        self.log(format!("MANDATORY: {string}"));

        if self.trim_whitespace {
            string = string.trim().to_string();
        }
        Ok(string)
    }

    fn conditional(&mut self, length: usize) -> Result<String, BoardingPassError> {
        if self.data.len() < self.index + length && self.end_conditional > 0 {
            return Err(BoardingPassError::conditional_index_invalid(
                self.end_conditional,
                self.sub_conditional,
            ));
        }

        if self.sub_conditional != 0 {
            self.sub_conditional -= length as i32;
        }
        if self.end_conditional != 0 {
            self.end_conditional -= length as i32;
        }

        let mut string = self.readdata(length)?;
        self.log(format!("CONDITIONAL: {string}"));
        self.log(format!("SUB-CONDITIONAL: {}", self.sub_conditional));
        self.log(format!("END CONDITIONAL: {}", self.end_conditional));

        if self.trim_whitespace {
            string = string.trim().to_string();
        }
        Ok(string)
    }

    fn readint(&mut self, length: usize) -> Result<Option<i32>, BoardingPassError> {
        let mut raw_string = self.mandatory(length)?;
        self.log(format!("RAW INT: {raw_string}"));

        if self.trim_whitespace {
            raw_string = raw_string.trim().to_string();
        }
        if self.trim_leading_zeroes {
            raw_string = remove_leading_zeros(&raw_string);
        }
        if self.empty_string_is_nil && raw_string.is_empty() {
            return Ok(None);
        }
        if !self.empty_string_is_nil && raw_string.is_empty() {
            return Ok(Some(0));
        }

        let number = raw_string
            .parse::<i32>()
            .map_err(|_| BoardingPassError::field_value_not_required_integer(&raw_string))?;
        Ok(Some(number))
    }

    fn readdata(&mut self, length: usize) -> Result<String, BoardingPassError> {
        // Match Node Buffer.subarray: clamp to available bytes, but always advance
        // the cursor by the requested length (may move past EOF).
        let available_end = self.data.len().min(self.index.saturating_add(length));
        let subdata = if self.index < self.data.len() {
            &self.data[self.index..available_end]
        } else {
            &[][..]
        };
        self.index = self.index.saturating_add(length);

        // Treat input as Latin-1 / raw bytes (Node .toString('ascii') strips the high bit;
        // for BCBP we map each byte to a Unicode scalar 0..=255 so non-UTF8 payloads decode).
        Ok(subdata.iter().map(|&b| b as char).collect())
    }

    fn readhex(&mut self, length: usize, is_mandatory: bool) -> Result<i32, BoardingPassError> {
        let str_val = if is_mandatory {
            self.mandatory(length)?
        } else {
            self.conditional(length)?
        };
        let int = i32::from_str_radix(&str_val, 16)
            .map_err(|_| BoardingPassError::hex_string_failed_decoding(&str_val))?;
        self.log(format!("HEX: {int}"));
        Ok(int)
    }

    fn repeated_mandatory(&mut self, leg_index: i32) -> Result<BoardingPassLeg, BoardingPassError> {
        self.log("PARSING REPEATED MANDATORY");

        let pnr_code = self.mandatory(7)?;
        let origin = self.mandatory(3)?;
        let destination = self.mandatory(3)?;
        let op_carrier = self.mandatory(3)?;
        let mut flightno = self.mandatory(5)?;
        let julian_date = self
            .readint(3)?
            .ok_or_else(|| BoardingPassError::data_failed_validation("Julian Date is nil"))?;
        let compartment = self.mandatory(1)?;
        let mut seatno = self.mandatory(4)?;
        let check_in = self.readint(5)?;
        let passenger_status = self.mandatory(1)?;
        let field_size = self.readhex(2, true)?;

        if self.trim_leading_zeroes {
            flightno = remove_leading_zeros(&flightno);
            seatno = remove_leading_zeros(&seatno);
        }

        Ok(BoardingPassLeg {
            leg_index,
            pnr_code,
            origin,
            destination,
            operating_carrier: op_carrier,
            flightno,
            julian_date,
            compartment,
            seatno,
            check_in,
            passenger_status,
            conditional_size: field_size,
            conditional_data: None,
        })
    }

    fn unique_conditional(&mut self) -> Result<BoardingPassInfo, BoardingPassError> {
        self.log("PARSING UNIQUE CONDITIONAL");

        let beginning_char = self.conditional(1)?;
        let version = self.conditional(1)?;
        let field_size = self.readhex(2, false)?;

        self.sub_conditional = field_size;
        self.log(format!("SET subConditional: {}", self.sub_conditional));

        if field_size == 0 {
            self.log("Unique conditional field size is 0, returning empty pass info");
            return Ok(BoardingPassInfo {
                beginning_char,
                version,
                field_size,
                passenger_description: None,
                check_in_source: None,
                pass_source: None,
                issue_date: None,
                document_type: None,
                issuing_airline: String::new(),
                bag_tags: Vec::new(),
            });
        }

        let mut pass_desc = Some(self.conditional(1)?);
        let mut check_source = Some(self.conditional(1)?);
        let mut pass_source = Some(self.conditional(1)?);
        let mut issue_date = Some(self.conditional(4)?);
        let mut doc_type = Some(self.conditional(1)?);
        let airline_code = self.conditional(3)?;

        if self.trim_leading_zeroes {
            if let Some(ref mut d) = issue_date {
                *d = remove_leading_zeros(d);
            }
        }

        pass_desc = self.apply_empty_string_is_nil(pass_desc);
        check_source = self.apply_empty_string_is_nil(check_source);
        pass_source = self.apply_empty_string_is_nil(pass_source);
        issue_date = self.apply_empty_string_is_nil(issue_date);
        doc_type = self.apply_empty_string_is_nil(doc_type);

        let mut bag_tags = Vec::new();
        while self.sub_conditional >= 13 {
            let tag = self.conditional(13)?;
            if !tag.is_empty() && (!self.empty_string_is_nil || !tag.trim().is_empty()) {
                bag_tags.push(tag);
            }
        }

        if self.sub_conditional > 0 {
            let leftover = self.sub_conditional as usize;
            let _ = self.conditional(leftover);
            self.sub_conditional = 0;
        }

        Ok(BoardingPassInfo {
            beginning_char,
            version,
            field_size,
            passenger_description: pass_desc,
            check_in_source: check_source,
            pass_source,
            issue_date,
            document_type: doc_type,
            issuing_airline: airline_code,
            bag_tags,
        })
    }

    fn repeated_conditional(&mut self) -> Result<BoardingPassLegData, BoardingPassError> {
        self.log("PARSING REPEATED CONDITIONAL");

        let field_size = self.readhex(2, false)?;
        self.sub_conditional = field_size;
        self.log(format!("SET subConditional: {}", self.sub_conditional));

        if field_size == 0 {
            self.log("Field size is 0, returning empty leg data");
            return Ok(BoardingPassLegData::empty());
        }

        if self.sub_conditional > self.end_conditional {
            return Err(BoardingPassError::boarding_pass_leg_conditional_mismatch());
        }

        self.log("");
        self.log(format!("Sub Conditional Check Passed: {field_size}"));
        self.log("");

        let airline_numeric = self.conditional(3)?;
        let document_number = self.conditional(10)?;
        let selectee = self.conditional(1)?;
        let international_doc = self.conditional(1)?;
        let marketing_carrier = self.conditional(3)?;

        let ff_field_size = (field_size - 23).max(0);

        self.log(format!("Conditional chars left: {}", self.sub_conditional));
        self.log(format!("Freq Flyer size: {ff_field_size}"));

        let ff_info = if ff_field_size > 0 {
            self.conditional(ff_field_size as usize)?
        } else {
            String::new()
        };

        // Match JS string slicing (UTF-16 code units ≈ ASCII bytes for BCBP).
        let parsed_ff_airline = {
            let slice = if ff_info.len() >= 3 {
                &ff_info[..3]
            } else {
                &ff_info[..]
            };
            if self.trim_whitespace {
                slice.trim().to_string()
            } else {
                slice.to_string()
            }
        };
        let parsed_ff_number = if ff_info.len() > 3 {
            let rest = &ff_info[3..];
            if self.trim_whitespace {
                rest.trim().to_string()
            } else {
                rest.to_string()
            }
        } else {
            String::new()
        };

        self.log(format!("FF Airline: {parsed_ff_airline}"));
        self.log(format!("FF Number: {parsed_ff_number}"));
        self.log("");
        self.log(format!("Parsed Freq Flyer Info: {ff_info}"));
        self.log(format!("Conditional chars left: {}", self.sub_conditional));

        let mut id_ad_indicator = Some(self.conditional(1)?);
        let mut free_bags = Some(self.conditional(3)?);
        let mut fast_track = Some(self.conditional(1)?);

        let mut airline_use = None;
        let left_over = self.end_conditional - self.sub_conditional;
        if left_over > 0 {
            airline_use = Some(self.conditional(left_over as usize)?);
        }

        id_ad_indicator = self.apply_empty_string_is_nil(id_ad_indicator);
        free_bags = self.apply_empty_string_is_nil(free_bags);
        fast_track = self.apply_empty_string_is_nil(fast_track);
        airline_use = self.apply_empty_string_is_nil(airline_use);

        if self.end_conditional != self.sub_conditional {
            return Err(BoardingPassError::boarding_pass_leg_conditional_mismatch());
        }

        self.log("");
        self.log("Sub Conditional Parsing Complete!");
        self.log("");

        Ok(BoardingPassLegData {
            segment_size: field_size,
            airline_code: airline_numeric,
            ticket_number: document_number,
            selectee,
            international_doc,
            ticketing_carrier: marketing_carrier,
            ff_airline: parsed_ff_airline,
            ff_number: parsed_ff_number,
            id_ad_indicator,
            free_bags,
            fast_track,
            airline_use,
        })
    }
}
