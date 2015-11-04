#ifndef __UTIL_H__
#define __UTIL_H__

/// Macro to get the size of a struct field
#define FIELD_SIZEOF(STRUCT, FIELD) (sizeof(((STRUCT*)0)->FIELD))

char* read_file(const char* file_name);

char* read_line();

#endif

