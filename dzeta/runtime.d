import std.stdint;
import std.array;
import std.string;
import std.conv;

/// Value tag
alias uint8_t Tag;

/**
Word value type
*/
union Word
{
    int8_t int8;
    int16_t int16;
    int32_t int32;
    int64_t int64;
    double float64;

    /*
    heapptr_t heapptr;

    array_t* array;
    string_t* string;
    shape_t* shape;
    object_t* object;

    ast_fun_t* fun;
    ast_decl_t* decl;

    cell_t* cell;
    clos_t* clos;
    hostfn_t* hostfn;
    */

    Tag tag;
}

/*
Tagged value pair type
*/
struct Value
{
    Word word;

    Tag tag;
}

// TODO
/*
Value add(Value x, Value y)
{

}
*/

