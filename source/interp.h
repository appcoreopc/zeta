/**
Zeta core interpreter implementation

The core interpreter expects rigid AST node object layouts generated by
the core parser. This interpreter only serves to allow the Zeta JIT compiler
to compile itself, it should never need to be run after that point, hence
I have cut some corners in terms of its implementation. The language
semantics supported are limited.
*/

#ifndef __INTERP_H__
#define __INTERP_H__

#include "vm.h"
#include "parser.h"

/// Shape indices for mutable cells and closures
/// These are initialized in init_interp(), see interp.c
extern shapeidx_t SHAPE_CELL;
extern shapeidx_t SHAPE_CLOS;

/**
Mutable cell object
*/
typedef struct cell
{
    shapeidx_t shape;

    /// Value word
    word_t word;

    /// Value tag
    /// Note: for now the tag is encoded in the object
    /// itself for easier interpreter integration
    tag_t tag;

} cell_t;

/**
Function closure object
*/
typedef struct clos
{
    shapeidx_t shape;

    /// Function this is a closure of
    ast_fun_t* fun;

    /// Mutable cell pointers (for captured closure variables)
    cell_t* cells[];

} clos_t;

cell_t* cell_alloc();

clos_t* clos_alloc(ast_fun_t* fun);

void interp_init();
void runtime_init();

void var_res_pass(ast_fun_t* fun, ast_fun_t* parent);

value_t eval_expr(heapptr_t expr, clos_t* clos, value_t* locals);
value_t eval_string(const char* cstr, const char* src_name);
value_t eval_file(const char* file_name);

void test_interp();
void test_runtime();

#endif

