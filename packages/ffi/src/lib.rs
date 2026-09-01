//! C ABI for boarding-pass-kit.
//!
//! Decode results and error strings are heap-allocated and must be freed with
//! [`bpk_free_string`]. Do **not** free the pointer from [`bpk_last_error`] —
//! prefer the `error_out` parameter on [`bpk_decode`] / [`bpk_julian_to_date`].

use std::cell::RefCell;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::ptr;

use boarding_pass_kit::{extract_qr_payload, julian_to_calendar_date, BoardingPassDecoder};
use chrono::{TimeZone, Utc};

thread_local! {
    static LAST_ERROR: RefCell<Option<CString>> = const { RefCell::new(None) };
}

fn set_last_error(message: impl Into<String>) {
    let msg = message.into().replace('\0', "");
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
    match CString::new(value.replace('\0', "")) {
        Ok(s) => s.into_raw(),
        Err(_) => {
            set_last_error("Result contained interior null byte");
            ptr::null_mut()
        }
    }
}

unsafe fn write_error_out(error_out: *mut *mut c_char, message: &str) {
    if error_out.is_null() {
        return;
    }
    *error_out = to_c_string(message.to_string());
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
/// On failure, if `error_out` is non-null, it receives a heap-allocated error
/// message that must be freed with [`bpk_free_string`]. Prefer `error_out` over
/// [`bpk_last_error`] (thread-local) in multi-threaded hosts such as Go.
///
/// # Safety
/// `barcode` must be a valid non-null NUL-terminated C string.
/// `options` may be null (defaults are used).
/// `error_out` may be null.
#[no_mangle]
pub unsafe extern "C" fn bpk_decode(
    barcode: *const c_char,
    options: *const BpkOptions,
    error_out: *mut *mut c_char,
) -> *mut c_char {
    clear_last_error();
    if !error_out.is_null() {
        *error_out = ptr::null_mut();
    }

    if barcode.is_null() {
        let msg = "barcode pointer is null";
        set_last_error(msg);
        write_error_out(error_out, msg);
        return ptr::null_mut();
    }

    let barcode = match CStr::from_ptr(barcode).to_str() {
        Ok(s) => s,
        Err(_) => {
            let msg = "barcode is not valid UTF-8";
            set_last_error(msg);
            write_error_out(error_out, msg);
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
                let msg = format!("JSON serialization failed: {e}");
                set_last_error(&msg);
                write_error_out(error_out, &msg);
                ptr::null_mut()
            }
        },
        Err(e) => {
            let msg = e.to_string();
            set_last_error(&msg);
            write_error_out(error_out, &msg);
            ptr::null_mut()
        }
    }
}

/// Extract the first QR, Aztec, or PDF417 payload from PNG/JPEG/HEIC image bytes.
///
/// Returns a heap-allocated UTF-8 C string on success, or null on failure.
/// Same `error_out` ownership rules as [`bpk_decode`].
///
/// # Safety
/// `data` must be valid for `len` bytes when non-null.
/// `error_out` may be null.
#[no_mangle]
pub unsafe extern "C" fn bpk_extract_qr(
    data: *const u8,
    len: usize,
    error_out: *mut *mut c_char,
) -> *mut c_char {
    clear_last_error();
    if !error_out.is_null() {
        *error_out = ptr::null_mut();
    }

    if data.is_null() || len == 0 {
        let msg = "image pointer is null or empty";
        set_last_error(msg);
        write_error_out(error_out, msg);
        return ptr::null_mut();
    }

    let slice = std::slice::from_raw_parts(data, len);
    match extract_qr_payload(slice) {
        Ok(payload) => to_c_string(payload),
        Err(e) => {
            let msg = e.to_string();
            set_last_error(&msg);
            write_error_out(error_out, &msg);
            ptr::null_mut()
        }
    }
}

/// Convert a Julian day-of-year to an ISO date string (`YYYY-MM-DD`).
///
/// Pass `year == 0` to infer the year from `relative_to_ms` (Unix epoch millis;
/// pass `0` to use "now"). On failure, if `error_out` is non-null it receives an
/// owned error string (free with [`bpk_free_string`]).
///
/// # Safety
/// Returned string must be freed with [`bpk_free_string`].
#[no_mangle]
pub unsafe extern "C" fn bpk_julian_to_date(
    day_of_year: c_int,
    year: c_int,
    relative_to_ms: i64,
    error_out: *mut *mut c_char,
) -> *mut c_char {
    clear_last_error();
    if !error_out.is_null() {
        *error_out = ptr::null_mut();
    }

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
            let msg = e.to_string();
            set_last_error(&msg);
            write_error_out(error_out, &msg);
            ptr::null_mut()
        }
    }
}

/// Return the last error message for this thread, or null if none.
///
/// The pointer is borrowed from thread-local storage — do **not** free it with
/// [`bpk_free_string`]. Prefer the `error_out` parameters on decode/julian APIs.
#[no_mangle]
pub unsafe extern "C" fn bpk_last_error() -> *const c_char {
    LAST_ERROR.with(|slot| match slot.borrow().as_ref() {
        Some(s) => s.as_ptr(),
        None => ptr::null(),
    })
}

/// Free a string returned by this library (decode/julian/`error_out`).
///
/// # Safety
/// `ptr` must be null or a pointer previously returned as an owned string by this crate.
#[no_mangle]
pub unsafe extern "C" fn bpk_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        drop(CString::from_raw(ptr));
    }
}
