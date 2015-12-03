import std.format;
import std.array;
import std.string;
import ast;

alias Appender!string Output;

// TODO: start with only a few kinds of expressions
void genExpr(Output* d, ASTExpr expr)
{
}

// TODO: start with this
void genFun(Output* d, FunExpr fun)
{
    // TODO: anonymous closure
    d.put("Value fname()");
    d.put("{");

    genExpr(d, fun.bodyExpr);

    d.put("}");
}

string genUnit(Output* d, FunExpr fun)
{
    // TODO: gen name for unit function
    // could just use a global counter
    string unitName = "unit_";

    d.put(format("void %s()", unitName));
    d.put("{");



    d.put("}");

    // Return the unit function name so it can be called
    return unitName;
}

string indentText(string inStr)
{
    Output o;

    // Current indentation level
    size_t level = 0;

    // TODO




    return o.data;
}

void genProgram(FunExpr[] units, string outFile)
{
    import std.file;

    Output d;

    foreach (unit; units)
        genUnit(&d, unit);

    auto dstr = d.data;

    // TODO: generate a main function, call the unit functions
    d.put("void main()");
    d.put("{");
    d.put("}");

    // Indent the output as a post-pass
    dstr = indentText(dstr);

    // Prepend the runtime code to the output
    auto runtime = readText!(string)("runtime.d");
    dstr = runtime ~ "\n" ~ dstr;

    // Write the output to a file
    write(dstr, "out.d");
}

