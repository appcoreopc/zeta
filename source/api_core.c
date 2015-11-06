/**
The functions in this file are used to implement the self-hosted
Zeta parser and JIT compiler
*/

#include <stdlib.h>
#include <stdio.h>
#include "util.h"
#include "interp.h"
#include "api_core.h"

void add_fn(array_t* fns, void* fptr, const char* name, const char* sig)
{
    array_append_obj(fns, (heapptr_t)hostfn_alloc(fptr, name, sig));
}

array_t* init_api_core()
{
    array_t* fns = array_alloc(8);

    // Basic string I/O
    add_fn(fns, &print_cstr, "print_cstr", "void(char*)");
    add_fn(fns, &read_line, "read_line", "char*()");
    add_fn(fns, &read_file, "read_file", "char*(char*)");

    // C stdlib
    add_fn(fns, &malloc, "malloc", "void*(size_t)");
    add_fn(fns, &free, "free", "void(void*)");
    add_fn(fns, &exit, "exit", "void(int)");

    return fns;
}

void print_cstr(const char* cstr)
{
    printf("%s", cstr);
}

// TODO: function to allocate an executable memory block
// look at Higgs source

