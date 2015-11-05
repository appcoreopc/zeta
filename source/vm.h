#ifndef __VM_H__
#define __VM_H__

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

/// Heap object pointer
typedef uint8_t* heapptr_t;

/// Value tag
typedef uint8_t tag_t;

/// Shape index (object header)
typedef uint32_t shapeidx_t;

// Forward declarations
typedef struct array array_t;
typedef struct string string_t;
typedef struct shape shape_t;
typedef struct object object_t;
typedef struct ast_decl ast_decl_t;
typedef struct ast_fun ast_fun_t;
typedef struct cell cell_t;
typedef struct clos clos_t;

/**
Word value type
*/
typedef union
{
    int8_t int8;
    int16_t int16;
    int32_t int32;
    int64_t int64;
    double float64;

    heapptr_t heapptr;

    array_t* array;
    string_t* string;
    shape_t* shape;
    object_t* object;

    ast_fun_t* fun;
    ast_decl_t* decl;

    cell_t* cell;
    clos_t* clos;

    shapeidx_t shapeidx;
    tag_t tag;

} word_t;

/*
Tagged value pair type
*/
typedef struct
{
    word_t word;

    tag_t tag;

} value_t;

/**
Virtual machine
*/
typedef struct
{
    uint8_t* heapstart;

    uint8_t* heaplimit;

    uint8_t* allocptr;

    array_t* shapetbl;

    /// String table, for string interning
    array_t* stringtbl;

    /// Number of strings allocated
    uint32_t num_strings;

    /// Empty object shape
    shape_t* empty_shape;

    /// Array shape
    shape_t* array_shape;

    /// String shape
    shape_t* string_shape;

    /// Global scope closure
    clos_t* global_clos;

} vm_t;

/**
String (heap object)
*/
typedef struct string
{
    shapeidx_t shape;

    /// String hash
    uint32_t hash;

    /// String length (excluding null terminator)
    uint32_t len;

    /// Character data, variable length
    /// UTF-8 formatting, with null-terminator character
    char data[];

} string_t;

/**
Array (list) heap object
*/
typedef struct array
{
    shapeidx_t shape;

    /// Allocated capacity
    uint32_t cap;

    /// Array length
    uint32_t len;

    /// Array element table (initially points to this object)
    array_t* tbl;

    /// Array elements, variable length
    /// Note: each value is tagged
    value_t elems[];

} array_t;

/*
Shape node descriptor
*/
typedef struct shape
{
    /// Shape of this object
    shapeidx_t shape;

    /// Index of this shape node in the shape table
    shapeidx_t idx;

    /// Parent shape node
    shape_t* parent;

    /// Property name
    string_t* prop_name;

    /// Constant property word, if known constant
    word_t cst_word;

    /// Offset in bytes for this property
    uint32_t offset;

    /// Property and object attributes
    uint8_t attrs;

    /// Property/field size in bytes
    uint8_t field_size;

    /// Property type tag, always encoded in the shape
    tag_t prop_tag;

    /// Child shapes
    /// KISS for now, just an array
    array_t* children;

} shape_t;

/**
Object
Note: for now, all object tags are encoded directly in shapes
*/
typedef struct object
{
    shapeidx_t shape;

    /// Storae/payload capacity in bytes
    uint32_t cap;

    /// Object extension, used if capacity exceeded
    object_t* ext_obj;

    uint8_t payload[];

} object_t;

/// Value type tags
/// Note: the value false is (0, 0)
#define TAG_BOOL        0
#define TAG_INT64       1
#define TAG_FLOAT64     2
#define TAG_STRING      3
#define TAG_ARRAY       4
#define TAG_RAW_PTR     5
#define TAG_OBJECT      6
#define TAG_CLOS        7

/// Initial VM heap size
#define HEAP_SIZE (1 << 24)

/// String table parameters
#define STR_TBL_INIT_SIZE       16384
#define STR_TBL_MAX_LOAD_NUM    3
#define STR_TBL_MAX_LOAD_DEN    5

/// Guaranteed minimum object capacity, in bytes
/// This is the total object size
#define OBJ_MIN_CAP 128

/// Constant property value attribute
#define ATTR_CST_VAL (1 << 0)

/// Read-only property attribute
#define ATTR_READ_ONLY (1 << 1)

/// Object frozen attribute
/// Frozen means shape cannot change, read-only and no new properties
#define ATTR_OBJ_FROZEN (1 << 2)

/// Fixed object layout
/// Shape cannot change, no capacity or next pointer or type tags
#define ATTR_FIXED_LAYOUT (1 << 3)

/// Default property attributes
#define ATTR_DEFAULT 0

/// Global VM instance
extern vm_t vm;

/// Shape of array objects
extern shapeidx_t SHAPE_ARRAY;

/// Shape of string objects
extern shapeidx_t SHAPE_STRING;

/// Boolean constant values
const value_t VAL_FALSE;
const value_t VAL_TRUE;

value_t value_from_heapptr(heapptr_t v, tag_t tag);
value_t value_from_obj(heapptr_t v);
value_t value_from_int64(int64_t v);
void value_print(value_t value);
bool value_equals(value_t this, value_t that);

shapeidx_t get_shape(heapptr_t obj);

void vm_init();
heapptr_t vm_alloc(uint32_t size, shapeidx_t shape);
string_t* vm_get_tbl_str(string_t* str);
string_t* vm_get_cstr(const char* cstr);

string_t* string_alloc(uint32_t len);
char* string_cstr(string_t* str);

array_t* array_alloc(uint32_t cap);
void array_set(array_t* array, uint32_t idx, value_t val);
void array_set_obj(array_t* array, uint32_t idx, heapptr_t val);
value_t array_get(array_t* array, uint32_t idx);
void array_append_obj(array_t* array, heapptr_t ptr);
heapptr_t array_get_ptr(array_t* array, uint32_t idx);
uint32_t array_indexof_ptr(array_t* array, heapptr_t ptr);

shape_t* shape_alloc(
    shape_t* parent,
    string_t* prop_name,
    tag_t prop_tag,
    uint8_t numBytes,
    uint8_t attrs
);
shape_t* shape_alloc_empty();
shape_t* shape_def_prop(
    shape_t* this,
    string_t* prop_name,
    tag_t tag,
    uint8_t attrs,
    uint8_t field_size,
    shape_t* defShape
);

void test_vm();

#endif

