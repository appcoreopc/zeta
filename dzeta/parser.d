import std.c.stdlib;
import std.stdio;
import std.file;
import std.format;
import std.uni;
import ast;

/**
Parsing error exception
*/
class ParseError : Error
{
    Input input;

    this(Input input, string msg)
    {
        super(msg);
        this.input = input;
    }

    override string toString()
    {
        return input.pos.toString() ~ ": " ~ this.msg;
    }
}

/**
Input stream, character/token stream for parsing functions
*/
class Input
{
    /// Internal source string (hosted heap)
    string str;

    /// Current index
    size_t idx;

    /// Source name string
    string src_name;

    /// Current source position
    SrcPos pos;

    this(string str, string srcName)
    {
        assert (str != null);

        this.str = str;
        this.idx = 0;
        this.pos.file = srcName;
        this.pos.line = 1;
        this.pos.col = 1;
    }

    /// Test if the end of file has been reached
    bool eof()
    {
        return idx >= str.length;
    }

    /// Peek at a character from the input
    char peekCh()
    {
        if (idx >= str.length)
            return '\0';

        return str[idx];
    }

    /// Read a character from the input
    char readCh()
    {
        char ch = peekCh();

        idx++;

        if (ch == '\n')
        {
            pos.line++;
            pos.col = 0;
        }
        else
        {
            pos.col++;
        }

        return ch;
    }

    /// Try and match a given character in the input
    /// The character is consumed if matched
    bool matchCh(char ch)
    {
        if (peekCh() == ch)
        {
            readCh();
            return true;
        }

        return false;
    }

    /// Try and match a given string in the input
    /// The string is consumed if matched
    bool matchStr(string str)
    {
        size_t idx = 0;

        for (; idx < str.length; idx++)
        {
            if (idx >= str.length)
            {
                this.idx += str.length;
                return true;
            }

            if (this.idx + idx > this.str.length)
            {
                return false;
            }

            if (str[idx] != this.str[this.idx + idx])
            {
                return false;
            }
        }

        return true;
    }

    /// Consume whitespace and comments
    void eatWS()
    {
        // Until the end of the whitespace
        for (;;)
        {
            // Consume whitespace characters
            if (isWhite(peekCh()))
            {
                readCh();
                continue;
            }

            // If this is a single-line comment
            if (matchStr("//"))
            {
                // Read until and end of line is reached
                for (;;)
                {
                    char ch = readCh();
                    if (ch == '\n' || ch == '\0')
                        break;
                }

                continue;
            }

            // If this is a multi-line comment
            if (matchStr("/*"))
            {
                // Read until the end of the comment
                for (;;)
                {
                    char ch = readCh();
                    if (ch == '*' && matchCh('/'))
                        break;
                }

                continue;
            }

            // This isn't whitespace, stop
            break;
        }
    }
}

















/**
Parse an identifier
*/
/*
heapptr_t parse_ident(Input input)
{
    size_t startIdx = input->idx;
    size_t len = 0;

    char firstCh = input.peekCh();

    if (firstCh != '_' &&
        firstCh != '$' &&
        !isalpha(firstCh))
        throw new ParseError(input, "invalid identifier start");;

    for (;;)
    {
        char ch = input.peekCh();

        if (!isalnum(ch) && ch != '$' && ch != '_')
            break;

        // Consume this character
        input_read_ch(input);
        len++;
    }

    if (len == 0)
        throw new ParseError(input, "invalid identifier");

    string_t* str = string_alloc(len);

    // Copy the characters
    strncpy(str->data, input->str->data + startIdx, len);
    str->data[len] = '\0';

    return (heapptr_t)vm_get_tbl_str(str);
}
*/

/**
Parse a number (integer or floating-point)
Note: floating-point numbers are not supported by the core parser
*/
/*
heapptr_t parseNumber(Input input)
{
    char* numStart;

    int64_t intVal;

    char* endInt = NULL;

    // Hexadecimal literals
    if (input.matchStr("0x"))
    {
        numStart = input->str->data + input->idx;
        intVal = strtol(numStart, &endInt, 16);
    }

    // Binary literals
    else if (input.matchStr("0b"))
    {
        numStart = input->str->data + input->idx;
        intVal = strtol(numStart, &endInt, 2);
    }

    // Decimal literals
    else
    {
        numStart = input->str->data + input->idx;
        intVal = strtol(numStart, &endInt, 10);
    }

    input->idx += endInt - numStart;
    return (heapptr_t)ast_const_alloc(value_from_int64(intVal));
}
*/

/**
Parse a string literal
*/
/*
heapptr_t parse_string_lit(Input input, char endCh)
{
    size_t len = 0;
    size_t cap = 64;

    char* buf = malloc(cap);

    for (;;)
    {
        // If this is the end of the input
        if (input_eof(input))
        {
            free(buf);
            throw new ParseError(
                input,
                "end of input inside string literal"
            );
        }

        // Consume this character
        char ch = input_read_ch(input);

        // If this is the end of the string
        if (ch == endCh)
        {
            break;
        }

        // If this is an escape sequence
        if (ch == '\\')
        {
            char esc = input_read_ch(input);

            switch (esc)
            {
                case 'n': ch = '\n'; break;
                case 'r': ch = '\r'; break;
                case 't': ch = '\t'; break;
                case '0': ch = '\0'; break;

                default:
                free(buf);
                throw new ParseError(input, "invalid escape sequence");
            }
        }

        buf[len] = ch;
        len++;

        if (len == cap)
        {
            cap *= 2;
            char* newBuf = malloc(cap);
            strncpy(newBuf, buf, len);
            free(buf);
        }
    }

    buf[len] = '\0';

    // Get the interned version of this string
    string_t* str = vm_get_cstr(buf);

    free(buf);

    return (heapptr_t)str;
}
*/

/**
Parse an if expression
if <test_expr> then <then_expr> else <else_expr>
*/
ASTExpr parseIfExpr(Input input)
{
    ASTExpr test_expr = parseExpr(input);

    input.eatWS();
    if (!input.matchStr("then"))
    {
        throw new ParseError(input, "expected 'then' keyword");
    }

    ASTExpr then_expr = parseExpr(input);

    ASTExpr else_expr;

    // If these is an else clause
    input.eatWS();
    if (input.matchStr("else"))
    {
       else_expr = parseExpr(input);
    }
    else
    {
        // TODO
        assert (false);
        //else_expr = ast_const_alloc(VAL_FALSE);
    }

    // TODO:
    assert (false);
    //return ast_if_alloc(test_expr, then_expr, else_expr);
}

/**
Parse a list of expressions
*/
/*
ASTExpr parse_expr_list(Input input, char endCh)
{
    // Allocate an array with an initial capacity
    array_t* arr = array_alloc(4);

    // Until the end of the list
    for (;;)
    {
        // Read whitespace
        input.eatWS();

        // If this is the end of the list
        if (input.matchCh(endCh))
        {
            break;
        }

        // Parse an expression
        ASTExpr expr = parseExpr(input);

        // The expression must not fail to parse
        if (ast_error(expr))
        {
            return expr;
        }

        // Write the expression to the array
        array_set_obj(arr, arr->len, expr);

        // Read whitespace
        input.eatWS();

        // If this is the end of the list
        if (input.matchCh(endCh))
        {
            break;
        }

        // If this is not the first element, there must be a separator
        if (!input.matchCh(','))
        {
            throw new ParseError(input, "expected comma separator in list");
        }
    }

    return (heapptr_t)arr;
}
*/

/**
Parse a sequence expression
*/
/*
ASTExpr parse_seq_expr(Input input, char endCh)
{
    // Allocate an array with an initial capacity
    array_t* arr = array_alloc(4);

    // Until the end of the list
    for (;;)
    {
        // Read whitespace
        input.eatWS();

        // If this is the end of the list
        if (input.matchCh(endCh))
        {
            break;
        }

        // Parse an expression
        ASTExpr expr = parseExpr(input);

        // The expression must not fail to parse
        if (ast_error(expr))
        {
            return expr;
        }

        // Write the expression to the array
        array_set_obj(arr, arr->len, expr);

        // Read whitespace
        input.eatWS();

        // If this is the end of the list
        if (input.matchCh(endCh))
        {
            break;
        }

        // Match a semicolon if one is present (optional)
        if (input.matchCh(';'))
        {
        }
    }

    return ast_seq_alloc(arr);
}
*/

/**
Parse a function (closure) expression
fun (x,y,z) <body_expr>
*/
/*
ASTExpr parse_fun_expr(Input input)
{
    input.eatWS();
    if (!input.matchCh('('))
    {
        throw new ParseError(input, "expected parameter list");
    }

    // Allocate an array for the parameter declarations
    array_t* param_decls = array_alloc(4);

    // Until the end of the list
    for (;;)
    {
        // Read whitespace
        input.eatWS();

        // If this is the end of the list
        if (input.matchCh(')'))
            break;

        // Parse an identifier
        ASTExpr ident = parse_ident(input);

        if (ast_error(ident))
            return ident;

        ASTExpr decl = ast_decl_alloc(ident, false);

        // Write the expression to the array
        array_set_obj(param_decls, param_decls->len, decl);

        // Read whitespace
        input.eatWS();

        // If this is the end of the list
        if (input.matchCh(')'))
            break;

        // If this is not the first element, there must be a separator
        if (!input.matchCh(','))
        {
            throw new ParseError(input, "expected comma separator in parameter list");
        }
    }

    // Parse the function body
    ASTExpr body_expr = parseExpr(input);

    if (ast_error(body_expr))
    {
        return body_expr;
    }

    return (heapptr_t)ast_fun_alloc(param_decls, body_expr);
}
*/

/**
Parse an object literal expression
fun (x,y,z) <body_expr>
*/
/*
ASTExpr parseObjExpr(Input input)
{
    array_t* name_strs = array_alloc(4);
    array_t* val_exprs = array_alloc(4);

    // Until the end of the list
    for (;;)
    {
        // Read whitespace
        input.eatWS();

        // If this is the end of the list
        if (input.matchCh('}'))
        {
            break;
        }

        // Parse the property name
        ASTExpr ident = parse_ident(input);

        if (ast_error(ident))
        {
            return ident;
        }

        input.eatWS();
        if (!input.matchCh(':'))
        {
            throw new ParseError(input, "expected : separator");
        }

        // Parse an expression
        ASTExpr expr = parseExpr(input);

        array_set(name_strs, name_strs->len, value_from_heapptr(ident, TAG_STRING));
        array_set_obj(val_exprs, val_exprs->len, expr);

        // If this is the end of the list
        input.eatWS();
        if (input.matchCh('}'))
        {
            break;
        }

        // If this is not the first element, there must be a separator
        if (!input.matchCh(','))
        {
            throw new ParseError(input, "expected comma separator in list");
        }
    }

    return ast_obj_alloc(NULL, name_strs, val_exprs);
}
*/

/**
Try to match an operator in the input
*/
Operator matchOp(Input input, int minPrec, bool preUnary)
{
    // TODO
    //input_t beforeOp = *input;

    char ch = input.peekCh();

    Operator op = null;

    // Switch on the first character of the operator
    // We do this to avoid a long cascade of match tests
    switch (ch)
    {
        case '.':
        if (input.matchCh('.'))     op = &OP_MEMBER;
        break;

        case '[':
        if (input.matchCh('['))     op = &OP_INDEX;
        break;

        case '(':
        if (input.matchCh('('))     op = &OP_CALL;
        break;

        case 'n':
        if (input.matchStr("not"))  op = &OP_NOT;
        break;

        case '*':
        if (input.matchCh('*'))     op = &OP_MUL;
        break;

        case '/':
        if (input.matchCh('/'))     op = &OP_DIV;
        break;

        case 'm':
        if (input.matchStr("mod"))  op = &OP_MOD;
        break;

        case '+':
        if (input.matchCh('+'))     op = &OP_ADD;
        break;

        case '-':
        if (input.matchCh('-'))
            op = preUnary? &OP_NEG:&OP_SUB;
        break;

        case '<':
        if (input.matchStr("<="))   op = &OP_LE;
        if (input.matchCh('<'))     op = &OP_LT;
        break;

        case '>':
        if (input.matchStr(">="))   op = &OP_GE;
        if (input.matchCh('>'))     op = &OP_GT;
        break;

        case 'i':
        if (input.matchStr("instanceof")) op = &OP_INST_OF;
        if (input.matchStr("in")) op = &OP_IN;
        break;

        case '=':
        if (input.matchStr("=="))   op = &OP_EQ;
        if (input.matchCh('='))     op = &OP_ASSIGN;
        break;

        case '!':
        if (input.matchStr("!="))   op = &OP_NE;
        break;

        case 'a':
        if (input.matchStr("and"))  op = &OP_AND;
        break;

        case 'o':
        if (input.matchStr("or"))   op = &OP_OR;
        break;

        default:
    }

    // TODO
    /*
    // If any operator was found
    if (op)
    {
        // If its precedence isn't high enough or it doesn't meet
        // the arity and associativity requirements
        if ((op->prec < minPrec) ||
            (preUnary && op->arity != 1) || 
            (preUnary && op->assoc != 'r'))
        {
            // Backtrack to avoid consuming the operator
            *input = beforeOp;
            op = NULL;
        }
    }
   */

    // Return the matched operator, if any
    return op;
}

/**
Parse a variable declaration
Note: assumes that the "var" keyword has already been matched
*/
/*
ASTExpr parse_var_decl(Input input)
{
    input.eatWS();

    auto ident = parse_ident(input);

    return ast_decl_alloc(ident, false);
}
*/

// TODO: rename to parse_let_decl
/**
Parse a constant declaration
Note: assumes that the "let" keyword has already been matched
*/
/*
ASTExpr parse_cst_decl(Input input)
{
    input.eatWS();

    ASTExpr ident = parse_ident(input);

    if (ast_error(ident))
    {
        throw new ParseError(input, "expected identifier in variable expression");
    }

    input.eatWS();

    // A value must be assigned to the constant declared
    if (!input.matchStr("="))
    {
        throw new ParseError(input, "expected value assignment in let declaration");
    }

    ASTExpr val = parseExpr(input);

    if (ast_error(val))
    {
        return val;
    }

    // Create and return an assignment expression
    return ast_binop_alloc(
        &OP_ASSIGN,
        ast_decl_alloc(ident, true),
        val
    );
}
*/

/**
Parse an atomic expression
*/
ASTExpr parseAtom(Input input)
{
    // Consume whitespace
    input.eatWS();

    // TODO: bring isDigit from Higgs lexer
    /*
    // Numerical constant
    if (isDigit(input.peekCh()))
    {
        return parseNumber(input);
    }
    */

    /*
    // String literal
    if (input.matchCh('\''))
    {
        return parse_string_lit(input, '\'');
    }
    if (input.matchCh('"'))
    {
        return parse_string_lit(input, '"');
    }

    // Array literal
    if (input.matchCh('['))
    {
        return parse_expr_list(input, ']');
    }

    // Object literal
    if (input.matchStr(":{"))
    {
        return parseObjExpr(input);
    }

    // Parenthesized expression
    if (input.matchCh('('))
    {
        ASTExpr expr = parseExpr(input);
        if (ast_error(expr))
        {
            throw new ParseError(input, "expected expression after '('");
        }

        if (!input.matchCh(')'))
        {
            throw new ParseError(input, "expected closing parenthesis");
        }

        return expr;
    }

    // Sequence/block expression (i.e { a; b; c }
    if (input.matchCh('{'))
    {
        return parse_seq_expr(input, '}');
    }

    // Try matching a right-associative (prefix) unary operators
    const opinfo_t* op = matchOp(input, 0, true);

    // If a matching operator was found
    if (op)
    {
        ASTExpr expr = parseAtom(input);
        if (ast_error(expr))
        {
            return expr;
        }

        return (heapptr_t)ast_unop_alloc(op, expr);
    }

    // Identifier
    if (isalnum(input.peekCh()))
    {
        // Variable declaration
        if (input.matchStr("var"))
            return parse_var_decl(input);

        // Constant declaration
        if (input.matchStr("let"))
            return parse_cst_decl(input);

        // If expression
        if (input.matchStr("if"))
            return parseIfExpr(input);

        // Function expression
        if (input.matchStr("fun"))
            return parse_fun_expr(input);

        // true and false boolean constants
        if (input.matchStr("true"))
            return (heapptr_t)ast_const_alloc(VAL_TRUE);
        if (input.matchStr("false"))
            return (heapptr_t)ast_const_alloc(VAL_FALSE);
    }

    // Identifiers beginning with non-alphanumeric characters
    if (input.peekCh() == '_' ||
        input.peekCh() == '$' ||
        isalpha(input.peekCh()))
    {
        return ast_ref_alloc(parse_ident(input));
    }
    */

    // Parsing failed
    throw new ParseError(input, "invalid expression");
}

/**
Parse an expression using the precedence climbing algorithm
*/
ASTExpr parseExpr(Input input, int minPrec = 0)
{
    // The first call has min precedence 0
    //
    // Each call loops to grab everything of the current precedence or
    // greater and builds a left-sided subtree out of it, associating
    // operators to their left operand
    //
    // If an operator has less than the current precedence, the loop
    // breaks, returning us to the previous loop level, this will attach
    // the atom to the previous operator (on the right)
    //
    // If an operator has the mininum precedence or greater, it will
    // associate the current atom to its left and then parse the rhs

    // Parse the first atom
    ASTExpr lhs_expr = parseAtom(input);

    for (;;)
    {
        // Consume whitespace
        input.eatWS();

        //printf("looking for op, minPrec=%d\n", minPrec);

        // Attempt to match an operator in the input
        // with sufficient precedence
        Operator op = matchOp(input, minPrec, false);

        // If no operator matches, break out
        if (op == null)
            break;

        /*
        // Compute the minimal precedence for the recursive call (if any)
        int nextMinPrec;
        if (op->assoc == 'l')
        {
            if (op->close_str)
                nextMinPrec = 0;
            else
                nextMinPrec = (op->prec + 1);
        }
        else
        {
            nextMinPrec = op->prec;
        }

        // If this is a function call expression
        if (op == &OP_CALL)
        {
            // Parse the argument list and create the call expression
            heapptr_t arg_exprs = parse_expr_list(input, ')');

            lhs_expr = ast_call_alloc(lhs_expr, (array_t*)arg_exprs);
        }

        // If this is a member expression
        else if (op == &OP_MEMBER)
        {
            // Parse the identifier string
            heapptr_t ident = parse_ident(input);

            // Produce an indexing expression
            lhs_expr = ast_binop_alloc(
                op,
                lhs_expr,
                ident//, lhs_expr.pos
            );
        }

        // If this is a binary operator
        else if (op->arity == 2)
        {
            // Recursively parse the rhs
            heapptr_t rhs_expr = parse_expr_prec(input, nextMinPrec);

            // Create a new parent node for the expressions
            lhs_expr = ast_binop_alloc(
                op,
                lhs_expr,
                rhs_expr//, lhs_expr.pos
            );

            // If specified, match the operator closing string
            if (op->close_str && !input.matchStr(op->close_str))
                throw new ParseError(input, "expected operator closing");
        }

        // If this is a unary operator
        else if (op->arity == 1)
        {
            if (op->assoc != 'l')
            {
                throw new ParseError(input, "invalid operator");
            }

            printf("postfix unary operator\n");
            assert (false);

            // Update lhs with the new value
            //lhs_expr = new UnOpExpr(op, lhs_expr, lhs_expr.pos);
        }

        else
        {
            // Unhandled operator
            printf("operator not handled correctly: %s\n", op->str);
            assert (false);
        }
        */
    }

    // Return the parsed expression
    return lhs_expr;
}

/**
Parse a source unit from an input object
*/
ASTExpr parseUnit(Input input)
{
    assert (false);

    /*
    // Create a sequence expression from the expression list
    heapptr_t seq_expr = parse_seq_expr(input, '\0');

    // Create an empty array for the parameter list
    array_t* param_list = array_alloc(0);

    return ast_fun_alloc(param_list, seq_expr);
    */
}

/**
Parse a source string as a unit
*/
ASTExpr parseString(string str, string srcName)
{
    auto input = new Input(
        str,
        srcName
    );

    return parseUnit(input);
}

/**
Parse a source file
*/
ASTExpr parseFile(const char* file_name)
{
    // TODO
    return null;

    /*
    string src_text = read_file(file_name);

    auto unit_fun = parseString(src_text, file_name);

    return unit_fun;
    */
}

/// Test that the parsing of a source unit succeeds
void test_parse(string str)
{
    writefln("%s", str);

    parseString(str, "parser_test");
}

/// Test that the parsing of a source unit fails
void test_parse_fail(string str)
{
    writefln("%s", str);

    try
    {
        parseString(str, "parser_fail_test");
    }
    catch (Error e)
    {
        return;
    }

    writefln("parsing did not fail for:\n\"%s\"", str);
    exit(-1);
}

/// Test the functionality of the parser
void test_parser()
{
    writeln("core parser tests");

    // Identifiers
    test_parse("foobar");
    test_parse("  foo_bar  ");
    test_parse("  foo_bar  ");
    test_parse("_foo");
    test_parse("$foo");
    test_parse("$foo52");

    // Literals
    test_parse("123");
    test_parse("0xFF");
    test_parse("0b101");
    test_parse("'abc'");
    test_parse("\"double-quoted string!\"");
    test_parse("\"double-quoted string, 'hi'!\"");
    test_parse("'hi' // comment");
    test_parse("'hi'");
    test_parse("'new\\nline'");
    test_parse("true");
    test_parse("false");
    test_parse_fail("'invalid\\iesc'");
    test_parse_fail("'str' []");

    // Array literals
    test_parse("[]");
    test_parse("[1]");
    test_parse("[1,a]");
    test_parse("[1 , a]");
    test_parse("[1,a, ]");
    test_parse("[ 1,\na ]");
    test_parse_fail("[,]");

    // Object literals
    test_parse(":{}");
    test_parse(":{x:3}");
    test_parse(":{x:3,y:2}");
    test_parse(":{x:3,y:2+z}");
    test_parse(":{x:3,y:2+z,}");
    test_parse_fail(":{,}");

    // Comments
    test_parse("1 // comment");
    test_parse("[ 1//comment\n,a ]");
    test_parse("1 /* comment */ + x");
    test_parse("1 /* // comment */ + x");
    test_parse_fail("1 // comment\n#1");
    test_parse_fail("1 /* */ */");

    // Arithmetic expressions
    test_parse("a + b");
    test_parse("a + b + c");
    test_parse("a + b - c");
    test_parse("a + b * c + d");
    test_parse("a or b or c");
    test_parse("(a)");
    test_parse("(a + b)");
    test_parse("(a + (b + c))");
    test_parse("((a + b) + c)");
    test_parse("(a + b) * (c + d)");
    test_parse_fail("*a");
    test_parse_fail("a*");
    test_parse_fail("a # b");
    test_parse_fail("a +");
    test_parse_fail("a + b # c");
    test_parse_fail("(a");
    test_parse_fail("(a + b))");
    test_parse_fail("((a + b)");

    // Member expression
    test_parse("a.b");
    test_parse("a.b + c");
    test_parse("$runtime.v0.add");
    test_parse("$api.file.v2.fopen");
    test_parse_fail("a.'b'");

    // Array indexing
    test_parse("a[0]");
    test_parse("a[b]");
    test_parse("a[b+2]");
    test_parse("a[2*b+1]");
    test_parse_fail("a[]");
    test_parse_fail("a[0 1]");

    // If expression
    test_parse("if x then y");
    test_parse("if x then y + 1");
    test_parse("if x then y else z");
    test_parse("if x then a+c else d");
    test_parse("if x then a else b");
    test_parse("if a instanceof b then true");
    test_parse("if 'a' in b or 'c' in b then y");
    test_parse("if not x then y else z");
    test_parse("if x and not x then true else false");
    test_parse("if x <= 2 then y else z");
    test_parse("if x == 1 then y+z else z+d");
    test_parse("if true then y else z");
    test_parse("if true or false then y else z");
    test_parse_fail("if x");
    test_parse_fail("if x then");
    test_parse_fail("if x then a if");

    // Assignment
    test_parse("x = 1");
    test_parse("x = -1");
    test_parse("a.b = x + y");
    test_parse("x = y = 1");
    test_parse("var x");
    test_parse("var x = 3");
    test_parse("let x=3");
    test_parse("let x= 3+y");
    test_parse_fail("var");
    test_parse_fail("let");
    test_parse_fail("let x");
    test_parse_fail("let x=");
    test_parse_fail("var +");
    test_parse_fail("var 3");

    // Call expressions
    test_parse("a()");
    test_parse("a(b)");
    test_parse("a(b,c)");
    test_parse("a(b,c+1)");
    test_parse("a(b,c+1,)");
    test_parse("x + a(b,c+1)");
    test_parse("x + a(b,c+1) + y");
    test_parse("a() b()");
    test_parse_fail("a(b c+1)");

    // Function expression
    test_parse("fun () 0");
    test_parse("fun (x) x");
    test_parse("fun (x,y) x");
    test_parse("fun (x,y,) x");
    test_parse("fun (x,y) x+y");
    test_parse("fun (x,y) if x then y else 0");
    test_parse("obj.method = fun (this, x) this.x = x");
    test_parse("let f = fun () 0\nf()");
    test_parse_fail("fun (x,y)");
    test_parse_fail("fun ('x') x");
    test_parse_fail("fun (x+y) y");

    // Fibonacci
    test_parse("let fib = fun (n) if n < 2 then n else fib(n-1) + fib(n-2)");

    // Sequence/block expression
    test_parse("{ a b }");
    test_parse("fun (x) { println(x) println(y) }");
    test_parse("fun (x) { var y = x + 1 print(y) }");
    test_parse("if (x) then { println(x) } else { println(y) z }");
    test_parse_fail("{ a, }");
    test_parse_fail("{ a, b }");
    test_parse_fail("fun foo () { a, }");

    // Regressions
    test_parse_fail("'a' <'");

    //parse_check_error(parse_file("global.zeta"));
    //parse_check_error(parse_file("parser.zeta"));

    parseFile("tests/beer.zeta");
    parseFile("tests/list-sum.zeta");
}

