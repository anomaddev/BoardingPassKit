//! C ABI for boarding-pass-kit.
//!
//! Decode results are returned as heap-allocated JSON strings that the caller
//! must free with [`bpk_free_string`].

use std::cell::RefCell;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::ptr;

use boarding_pass_kit::{julian_to_calendar_date, BoardingPassDecoder};
use chrono::{TimeZone, Utc};

thread_local! {
    static LAST_ERROR: RefCell<Option<CString>> = const { RefCell::new(None) };
}

fn set_last_error(message: impl Into<String>) {
    let msg = message.into();
    LAST_ERROR.with(|slot| {
        *slot.borrow_mut() = CString::new(msg).ok();
    });
}

fn clear_last_error() {
    LAST_ERROR.with(|slot| {
        *slot.borrow_mut() = None;
    });
}

fn to_c_string(value: String) -> *mut c_char {
    match CString::new(value) {
        Ok(s) => s.into_raw(),
        Err(_) => {
            set_last_error("Result contained interior null byte");
            ptr::null_mut()
        }
    }
}

/// Decoder options matching the Node/Swift/Rust knobs.
#[repr(C)]
#[derive(Clone, Copy)]
pub struct BpkOptions {
    pub debug: c_int,
    pub trim_leading_zeroes: c_int,
    pub trim_whitespace: c_int,
    pub empty_string_is_nil: c_int,
}

impl Default for BpkOptions {
    fn default() -> Self {
        Self {
            debug: 0,
            trim_leading_zeroes: 1,
            trim_whitespace: 1,
            empty_string_is_nil: 1,
        }
    }
}

/// Decode a BCBP barcode string into a JSON object.
///
/// Returns a heap-allocated UTF-8 C string on success, or null on failure.
/// On failure, call [`bpk_last_error`] for a message.
///
/// # Safety
/// `barcode` must be a valid non-null NUL-terminated C string.
/// `options` may be null (defaults are used).
#[no_mangle]
pub unsafe extern "C" fn bpk_decode(
    barcode: *const c_char,
    options: *const BpkOptions,
) -> *mut c_char {
    clear_last_error();

    if barcode.is_null() {
        set_last_error("barcode pointer is null");
        return ptr::null_mut();
    }

    let barcode = match CStr::from_ptr(barcode).to_str() {
        Ok(s) => s,
        Err(_) => {
            set_last_error("barcode is not valid UTF-8");
            return ptr::null_mut();
        }
    };

    let opts = if options.is_null() {
        BpkOptions::default()
    } else {
        *options
    };

    let mut decoder = BoardingPassDecoder::new();
    decoder.debug = opts.debug != 0;
    decoder.trim_leading_zeroes = opts.trim_leading_zeroes != 0;
    decoder.trim_whitespace = opts.trim_whitespace != 0;
    decoder.empty_string_is_nil = opts.empty_string_is_nil != 0;

    match decoder.decode(barcode) {
        Ok(pass) => match serde_json::to_string(&pass) {
            Ok(json) => to_c_string(json),
            Err(e) => {
                set_last_error(format!("JSON serialization failed: {e}"));
                ptr::null_mut()
            }
        },
        Err(e) => {
            set_last_error(e.to_string());
            ptr::null_mut()
        }
    }
}

/// Convert a Julian day-of-year to an ISO date string (`YYYY-MM-DD`).
///
/// Pass `year == 0` to infer the year from `relative_to_ms` (Unix epoch millis;
/// pass `0` to use "now").
///
/// # Safety
/// Returned string must be freed with [`bpk_free_string`].
#[no_mangle]
pub unsafe extern "C" fn bpk_julian_to_date(
    day_of_year: c_int,
    year: c_int,
    relative_to_ms: i64,
) -> *mut c_char {
    clear_last_error();

    let year_opt = if year == 0 { None } else { Some(year) };
    let relative = if year != 0 {
        None
    } else if relative_to_ms == 0 {
        None
    } else {
        Utc.timestamp_millis_opt(relative_to_ms).single()
    };

    match julian_to_calendar_date(day_of_year, year_opt, relative) {
        Ok(date) => to_c_string(date.format("%Y-%m-%d").to_string()),
        Err(e) => {
            set_last_error(e.to_string());
            ptr::null_mut()
        }
    }
}

/// Return the last error message for this thread, or null if none.
#[no_mangle]
pub unsafe extern "C" fn bpk_last_error() -> *const c_char {
    LAST_ERROR.with(|slot| match slot.borrow().as_ref() {
        Some(s) => s.as_ptr(),
        None => ptr::null(),
    })
}

/// Free a string returned by this library.
///
/// # Safety
/// `ptr` must be null or a pointer previously returned by this crate.
#[no_mangle]
pub unsafe extern "C" fn bpk_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        drop(CString::from_raw(ptr));
    }
}
