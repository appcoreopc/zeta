#ifndef __UTIL_H__
#define __UTIL_H__

#include <stdint.h>

/// Macro to get the size of a struct field
#define FIELD_SIZEOF(STRUCT, FIELD) (sizeof(((STRUCT*)0)->FIELD))

uint64_t murmur_hash_64a(const void* key, size_t len, uint64_t seed);

char* read_file(const char* file_name);

char* read_line();

#endif

