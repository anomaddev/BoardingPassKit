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

/* Decode barcode to JSON string. Caller must free with bpk_free_string. */
char *bpk_decode(const char *barcode, const BpkOptions *options);

/* ISO date YYYY-MM-DD. year==0 infers from relative_to_ms (0 => now). */
char *bpk_julian_to_date(int day_of_year, int year, int64_t relative_to_ms);

const char *bpk_last_error(void);

void bpk_free_string(char *ptr);

#ifdef __cplusplus
}
#endif

#endif /* BOARDING_PASS_KIT_H */
