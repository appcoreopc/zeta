import std.stdio;
import std.format;
import std.array;
import std.string;
import std.conv;
import ast;

alias Appender!string Output;

size_t unitNo = 0;

void genExpr(Output* d, ASTExpr expr)
{
    if (auto strExpr = cast(StringExpr)expr)
    {
        d.put("Value(\"" ~ strExpr.val ~ "\")");
        return;
    }

    if (auto refExpr = cast(RefExpr)expr)
    {
        d.put(refExpr.name);
        return;
    }

    if (auto callExpr = cast(CallExpr)expr)
    {
        genExpr(d, callExpr.funExpr);
        d.put("(");

        foreach (idx, argExpr; callExpr.argExprs)
        {
            genExpr(d, argExpr);
            if (idx+1 < callExpr.argExprs.length)
                d.put(", ");
        }

        d.put(")");
        return;
    }

    if (auto seqExpr = cast(SeqExpr)expr)
    {
        foreach (subExpr; seqExpr.exprList)
        {
            genExpr(d, subExpr);
            d.put(";");
        }

        return;
    }

    writeln(expr);

    assert (false);
}

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
    // Generate a name for the unit function
    string unitName = "unit_" ~ to!string(unitNo++);

    d.put(format("void %s()", unitName));
    d.put("{");

    genExpr(d, fun.bodyExpr);

    d.put("}");

    // Return the unit function name so it can be called
    return unitName;
}

string indentText(string inStr)
{
    Output o;

    const indentChars = "    ";

    // Current indentation level
    size_t level = 0;

    void indent()
    {
        for (size_t i = 0; i < level; ++i)
            o.put(indentChars);
    }

    foreach (idx, ch; inStr)
    {
        if (ch == '{')
        {
            level++;
            o.put("\n");
            o.put("{");
            o.put("\n");
            indent();
        }
        else if (ch == ';')
        {
            o.put(";");

            if (idx+1 < inStr.length && inStr[idx+1] != '}')
            {
                o.put("\n");
                indent();
            }
        }
        else if (ch == '}')
        {
            level--;
            o.put("\n");
            o.put("}");
            o.put("\n");
            o.put("\n");
        }
        else
        {
            o.put(ch);
        }
    }

    return o.data;
}

void genProgram(FunExpr[] units, string outFile)
{
    import std.file;

    Output d;

    // Generate a function for each unit
    string[] unitFunNames;
    foreach (unit; units)
        unitFunNames ~= genUnit(&d, unit);

    // Generate a main function calling the unit functions
    d.put("void main()");
    d.put("{");
    foreach (name; unitFunNames)
        d.put(name ~ "();");
    d.put("}");

    auto dstr = d.data;

    // Indent the output as a post-pass
    dstr = indentText(dstr);

    // Prepend the runtime code to the output
    auto runtime = readText!(string)("runtime.d");
    dstr = runtime ~ dstr;

    // Write the output to a file
    write(outFile, dstr);
}

