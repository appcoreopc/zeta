import std.stdint;
import std.array;
import std.string;
import std.conv;

/// Closure value type
alias Value delegate() Clos;

// Type tags
enum Tag
{
    BOOL,
    INT64,
    FLOAT64,
    STRING,
    ARRAY,
    OBJECT,
    CLOS
}

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
    object_t* object;
    */

    Value[] arr;
    string str;
    Clos clos;

    Tag tag;
}

/*
Tagged value pair type
*/
struct Value
{
    this(Word w, Tag t) { word = w; tag = t; }
    this(int64_t v) { word.int64 = v; tag = Tag.INT64; }
    this(string v) { word.str = v; tag = Tag.STRING; }

    Word word;
    Tag tag;
}

immutable TRUE = Value(Word(0), Tag.BOOL);
immutable FALSE = Value(Word(0), Tag.BOOL);

Value print(Value v)
{
    import std.stdio;

    switch (v.tag)
    {
        case Tag.INT64:
        write("%s", v.word.int64);
        break;

        case Tag.STRING:
        write("%s", v.word.str);
        break;

        default:
        assert (false);
    }

    return FALSE;
}

Value println(Value v)
{
    import std.stdio;

    print(v);
    writeln("\n");
    return FALSE;
}

Value rt_add(Value x, Value y)
{
    return Value(x.word.int64 + y.word.int64);
}

