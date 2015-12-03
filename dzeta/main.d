import std.stdio;
import parser;
import vars;
import codegen;

void main(string[] args)
{
    if (args.length == 2)
    {
        auto fileName = args[1];

        writefln("input file: \"%s\"", fileName);

        auto unit = parseFile(fileName);

        genProgram([unit], "out.d");
    }
}

