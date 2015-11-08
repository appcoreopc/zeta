/**
Zeta core parser implementation

This parser is used to parse the runtime library, the self-hosted Zeta parser
and the Zeta JIT compiler.

The AST node structs are mapped onto objects accessible from the Zeta
language.
*/

#ifndef __PARSER_H__
#define __PARSER_H__

#include <stdbool.h>
#include "vm.h"

/**
Source position information
*/
typedef struct
{
    uint32_t lineNo;

    uint32_t colNo;

} srcpos_t;

/**
Input stream, character/token stream for parsing functions
*/
typedef struct
{
    /// Internal source string (hosted heap)
    string_t* str;

    /// Current index
    uint32_t idx;

    /// Source name string
    string_t* src_name;

    /// Current source position
    srcpos_t pos;

} input_t;

/**
Parse error
*/
typedef struct
{
    shapeidx_t shape;

    // Error description
    string_t* error_str;

    /// Source position
    srcpos_t src_pos;

} ast_error_t;

/**
Constant value AST node
Used for integers, floats and booleans
*/
typedef struct
{
    shapeidx_t shape;

    value_t val;

} ast_const_t;

/**
Variable reference node
*/
typedef struct
{
    shapeidx_t shape;

    /// Stack or mutable cell index
    uint32_t idx;

    /// Identifier name string
    string_t* name;

    /// Resolved declaration, null if global
    ast_decl_t* decl;

} ast_ref_t;

/**
Variable/constant declaration node
*/
typedef struct ast_decl
{
    shapeidx_t shape;

    /// Local (stack) index
    uint32_t idx;

    /// Constant flag
    bool cst;

    /// Escaping variable (captured by a nested function)
    bool esc;

    /// Identifier name string
    string_t* name;

    /// Function the declaration belongs to
    ast_fun_t* fun;

} ast_decl_t;

/**
Operator information structure
TODO: map this as a Zeta object also?
*/
typedef struct
{
    /// Operator string (e.g. "+")
    char* str;

    /// Closing string (optional)
    char* close_str;

    /// Operator arity
    int arity;

    /// Precedence level
    int prec;

    /// Associativity, left-to-right or right-to-left ('l' or 'r')
    char assoc;

    /// Non-associative flag (e.g.: - and / are not associative)
    bool nonassoc;

} opinfo_t;

/**
Unary operator AST node
*/
typedef struct
{
    shapeidx_t shape;

    const opinfo_t* op;

    heapptr_t expr;

} ast_unop_t;

/**
Binary operator AST node
*/
typedef struct
{
    shapeidx_t shape;

    const opinfo_t* op;

    heapptr_t left_expr;
    heapptr_t right_expr;

} ast_binop_t;

/**
Sequence or block of expressions
*/
typedef struct
{
    shapeidx_t shape;

    // List of expressions
    array_t* expr_list;

} ast_seq_t;

/**
If expression AST node
*/
typedef struct
{
    shapeidx_t shape;

    heapptr_t test_expr;

    heapptr_t then_expr;
    heapptr_t else_expr;

} ast_if_t;

/**
Function call AST node
*/
typedef struct
{
    shapeidx_t shape;

    /// Function to be called
    heapptr_t fun_expr;

    /// Argument expressions
    array_t* arg_exprs;

} ast_call_t;

/**
Function expression node
*/
typedef struct ast_fun
{
    shapeidx_t shape;

    /// Parent (outer) function
    struct ast_fun* parent;

    /// Ordered list of parameter declarations
    array_t* param_decls;

    /// Set of local variable declarations
    /// Note: this list also includes the parameters
    /// Note: Variables captured by nested functions have the capt flag set
    array_t* local_decls;

    // Set of local variables escaping into inner/nested functions
    array_t* esc_locals;

    /// Set of variables captured from outer/parent functions
    /// Note: this does not include variables from the global object
    /// Note: the value of these are stored in closure objects
    array_t* free_vars;

    /// Function body expression
    heapptr_t body_expr;

} ast_fun_t;

/// Shape indices for AST nodes
extern shapeidx_t SHAPE_AST_ERROR;
extern shapeidx_t SHAPE_AST_CONST;
extern shapeidx_t SHAPE_AST_REF;
extern shapeidx_t SHAPE_AST_DECL;
extern shapeidx_t SHAPE_AST_BINOP;
extern shapeidx_t SHAPE_AST_UNOP;
extern shapeidx_t SHAPE_AST_SEQ;
extern shapeidx_t SHAPE_AST_IF;
extern shapeidx_t SHAPE_AST_CALL;
extern shapeidx_t SHAPE_AST_FUN;


/// Operator definitions
const opinfo_t OP_MEMBER;
const opinfo_t OP_INDEX;
const opinfo_t OP_NEG;
const opinfo_t OP_NOT;
const opinfo_t OP_ADD;
const opinfo_t OP_SUB;
const opinfo_t OP_MUL;
const opinfo_t OP_DIV;
const opinfo_t OP_MOD;
const opinfo_t OP_LT;
const opinfo_t OP_LE;
const opinfo_t OP_GT;
const opinfo_t OP_GE;
const opinfo_t OP_IN;
const opinfo_t OP_INST_OF;
const opinfo_t OP_EQ;
const opinfo_t OP_NE;
const opinfo_t OP_BIT_AND;
const opinfo_t OP_BIT_XOR;
const opinfo_t OP_BIT_OR;
const opinfo_t OP_AND;
const opinfo_t OP_OR;
const opinfo_t OP_ASSIGN;

char* srcpos_to_str(srcpos_t pos, char* buf);

void init_parser();

bool ast_error(heapptr_t node);

heapptr_t ast_const_alloc(value_t val);
heapptr_t ast_decl_alloc(heapptr_t name_str, bool cst);
heapptr_t ast_binop_alloc(
    const opinfo_t* op,
    heapptr_t left_expr,
    heapptr_t right_expr
);

heapptr_t parse_expr(input_t* input);
heapptr_t parse_string(const char* cstr, const char* src_name);
heapptr_t parse_file(const char* file_name);
ast_fun_t* parse_check_error(heapptr_t node);

void test_parser();

#endif

