/**
The functions in this file are used to implement the self-hosted
Zeta parser and JIT compiler
*/

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include "util.h"
#include "interp.h"
#include "api_core.h"
#include "vm.h"

bool is_int64(tag_t tag)
{
    return tag == TAG_INT64;
}

bool is_string(tag_t tag)
{
    return tag == TAG_STRING;
}

void print_int64(int64_t value)
{
    printf("%ld", value);
}

void print_string(string_t* string)
{
    printf("%s", string_cstr(string));
}

string_t* core_read_line()
{
    char* buf = read_line();
    string_t* str = vm_get_cstr(buf);
    free(buf);
    return str;
}

string_t* core_read_file(string_t* file_name)
{
    char* buf = read_file(string_cstr(file_name));
    string_t* str = vm_get_cstr(buf);
    free(buf);
    return str;
}

// TODO: function to allocate an executable memory block
// look at Higgs source

void add_fn(array_t* fns, void* fptr, const char* name, const char* sig)
{
    array_append_obj(fns, (heapptr_t)hostfn_alloc(fptr, name, sig));
}

array_t* init_api_core()
{
    array_t* fns = array_alloc(8);

    // Type tests
    add_fn(fns, &is_int64, "is_int64", "bool(tag)");
    add_fn(fns, &is_string, "is_string", "bool(tag)");

    // Basic string I/O
    add_fn(fns, &print_int64, "print_int64", "void(int64)");
    add_fn(fns, &print_string, "print_string", "void(string)");
    add_fn(fns, &core_read_line, "read_line", "string()");
    add_fn(fns, &core_read_file, "read_file", "string(string)");

    // C stdlib
    add_fn(fns, &malloc, "malloc", "void*(size_t)");
    add_fn(fns, &free, "free", "void(void*)");
    add_fn(fns, &exit, "exit", "void(int)");

    return fns;
}

