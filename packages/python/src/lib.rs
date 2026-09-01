use ::boarding_pass_kit::{
    demo_data, demo_keys, extract_qr_payload as extract_qr_payload_rs, julian_to_calendar_date,
    BoardingPass, BoardingPassDecoder, BoardingPassError,
};
use chrono::{TimeZone, Utc};
use pyo3::exceptions::{PyRuntimeError, PyValueError};
use pyo3::prelude::*;
use pyo3::types::{PyDict, PyList};

fn to_py_err(err: BoardingPassError) -> PyErr {
    PyValueError::new_err(err.to_string())
}

fn pass_to_dict(py: Python<'_>, pass: &BoardingPass) -> PyResult<PyObject> {
    let json = serde_json::to_string(pass)
        .map_err(|e| PyRuntimeError::new_err(format!("serialize: {e}")))?;
    let json_mod = py.import("json")?;
    let obj = json_mod.call_method1("loads", (json,))?;
    Ok(obj.into())
}

#[pyclass(name = "BoardingPassDecoder")]
struct PyBoardingPassDecoder {
    inner: BoardingPassDecoder,
}

#[pymethods]
impl PyBoardingPassDecoder {
    #[new]
    fn new() -> Self {
        let mut inner = BoardingPassDecoder::new();
        inner.debug = false;
        Self { inner }
    }

    #[getter]
    fn debug(&self) -> bool {
        self.inner.debug
    }

    #[setter]
    fn set_debug(&mut self, value: bool) {
        self.inner.debug = value;
    }

    #[getter]
    fn trim_leading_zeroes(&self) -> bool {
        self.inner.trim_leading_zeroes
    }

    #[setter]
    fn set_trim_leading_zeroes(&mut self, value: bool) {
        self.inner.trim_leading_zeroes = value;
    }

    #[getter]
    fn trim_whitespace(&self) -> bool {
        self.inner.trim_whitespace
    }

    #[setter]
    fn set_trim_whitespace(&mut self, value: bool) {
        self.inner.trim_whitespace = value;
    }

    #[getter]
    fn empty_string_is_nil(&self) -> bool {
        self.inner.empty_string_is_nil
    }

    #[setter]
    fn set_empty_string_is_nil(&mut self, value: bool) {
        self.inner.empty_string_is_nil = value;
    }

    /// Decode a BCBP barcode string into a dict (JSON-compatible).
    fn decode(&mut self, py: Python<'_>, barcode: &str) -> PyResult<PyObject> {
        let pass = self.inner.decode(barcode).map_err(to_py_err)?;
        pass_to_dict(py, &pass)
    }

    /// Extract a QR payload from image bytes, then decode it as BCBP.
    fn decode_from_image(&mut self, py: Python<'_>, image: &[u8]) -> PyResult<PyObject> {
        let pass = self.inner.decode_from_image(image).map_err(to_py_err)?;
        pass_to_dict(py, &pass)
    }
}

/// Extract the first QR payload from PNG, JPEG, or HEIC image bytes.
#[pyfunction]
#[pyo3(name = "extract_qr_payload")]
fn extract_qr_payload(image: &[u8]) -> PyResult<String> {
    extract_qr_payload_rs(image).map_err(to_py_err)
}

#[pyfunction]
#[pyo3(signature = (day_of_year, year=None, relative_to_ms=None))]
fn julian_to_date(
    day_of_year: i32,
    year: Option<i32>,
    relative_to_ms: Option<i64>,
) -> PyResult<String> {
    let relative = relative_to_ms.and_then(|ms| Utc.timestamp_millis_opt(ms).single());
    let date = julian_to_calendar_date(day_of_year, year, relative).map_err(to_py_err)?;
    Ok(date.format("%Y-%m-%d").to_string())
}

#[pyfunction]
fn get_demo_data(key: &str) -> PyResult<String> {
    demo_data(key)
        .map(|s| s.to_string())
        .ok_or_else(|| PyValueError::new_err(format!("Unknown demo data key: {key}")))
}

#[pyfunction]
fn list_demo_keys(py: Python<'_>) -> PyResult<PyObject> {
    let keys = demo_keys();
    let list = PyList::new(py, keys)?;
    Ok(list.into())
}

#[pymodule]
fn boarding_pass_kit(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_class::<PyBoardingPassDecoder>()?;
    m.add_function(wrap_pyfunction!(julian_to_date, m)?)?;
    m.add_function(wrap_pyfunction!(get_demo_data, m)?)?;
    m.add_function(wrap_pyfunction!(list_demo_keys, m)?)?;
    m.add_function(wrap_pyfunction!(extract_qr_payload, m)?)?;

    let demo = PyDict::new(m.py());
    for key in demo_keys() {
        if let Some(value) = demo_data(key) {
            demo.set_item(key, value)?;
        }
    }
    m.add("DemoData", demo)?;
    Ok(())
}
