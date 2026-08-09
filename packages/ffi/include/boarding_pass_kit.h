#ifndef BOARDING_PASS_KIT_H
#define BOARDING_PASS_KIT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct BpkOptions {
    int debug;
    int trim_leading_zeroes;
    int trim_whitespace;
    int empty_string_is_nil;
} BpkOptions;

/*
 * Decode barcode to JSON string. Caller must free the return value with
 * bpk_free_string. On failure returns NULL and, if error_out is non-NULL,
 * writes an owned error string into *error_out (also free with bpk_free_string).
 */
char *bpk_decode(const char *barcode, const BpkOptions *options, char **error_out);

/*
 * ISO date YYYY-MM-DD. year==0 infers from relative_to_ms (0 => now).
 * Same error_out ownership rules as bpk_decode.
 */
char *bpk_julian_to_date(int day_of_year, int year, int64_t relative_to_ms, char **error_out);

/*
 * Thread-local last error (borrowed; do NOT free). Prefer error_out above.
 */
const char *bpk_last_error(void);

void bpk_free_string(char *ptr);

#ifdef __cplusplus
}
#endif

#endif /* BOARDING_PASS_KIT_H */
