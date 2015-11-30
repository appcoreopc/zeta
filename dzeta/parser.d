import std.stdio;
import std.file;
import std.format;
import ast;

/**
Parsing error exception
*/
class ParseError : Error
{
    /// Source position
    SrcPos pos;

    this(string msg, SrcPos pos)
    {
        assert (pos !is null, "source position is null");

        super(msg);
        this.pos = pos;
    }

    override string toString()
    {
        return pos.toString() ~ ": " ~ this.msg;
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

    /*
    /// Try and match a given string in the input
    /// The string is consumed if matched
    bool input_match_str(input_t* input, char* str)
    {
        input_t sub = *input;

        for (;;)
        {
            if (*str == '\0')
            {
                *input = sub;
                return true;
            }

            if (input_eof(&sub))
            {
                return false;
            }

            if (!input_match_ch(&sub, *str))
            {
                return false;
            }

            str++;
        }
    }

    /// Consume whitespace and comments
    void input_eat_ws(input_t* input)
    {
        // Until the end of the whitespace
        for (;;)
        {
            // Consume whitespace characters
            if (isspace(input_peek_ch(input)))
            {
                input_read_ch(input);
                continue;
            }

            // If this is a single-line comment
            if (input_match_str(input, "//"))
            {
                // Read until and end of line is reached
                for (;;)
                {
                    char ch = input_read_ch(input);
                    if (ch == '\n' || ch == '\0')
                        break;
                }

                continue;
            }

            // If this is a multi-line comment
            if (input_match_str(input, "/*"))
            {
                // Read until the end of the comment
                for (;;)
                {
                    char ch = input_read_ch(input);
                    if (ch == '*' && input_match_ch(input, '/'))
                        break;
                }

                continue;
            }

            // This isn't whitespace, stop
            break;
        }
    }
    */
}

















/**
Parse an identifier
*/
/*
heapptr_t parse_ident(input_t* input)
{
    size_t startIdx = input->idx;
    size_t len = 0;

    char firstCh = input_peek_ch(input);

    if (firstCh != '_' &&
        firstCh != '$' &&
        !isalpha(firstCh))
        return ast_error_alloc(input, "invalid identifier start");;

    for (;;)
    {
        char ch = input_peek_ch(input);

        if (!isalnum(ch) && ch != '$' && ch != '_')
            break;

        // Consume this character
        input_read_ch(input);
        len++;
    }

    if (len == 0)
        return ast_error_alloc(input, "invalid identifier");

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
heapptr_t parse_number(input_t* input)
{
    char* numStart;

    int64_t intVal;

    char* endInt = NULL;

    // Hexadecimal literals
    if (input_match_str(input, "0x"))
    {
        numStart = input->str->data + input->idx;
        intVal = strtol(numStart, &endInt, 16);
    }

    // Binary literals
    else if (input_match_str(input, "0b"))
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
heapptr_t parse_string_lit(input_t* input, char endCh)
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
            return ast_error_alloc(
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
                return ast_error_alloc(input, "invalid escape sequence");
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
/*
heapptr_t parse_if_expr(input_t* input)
{
    heapptr_t test_expr = parse_expr(input);

    input_eat_ws(input);
    if (!input_match_str(input, "then"))
    {
        return ast_error_alloc(input, "expected 'then' keyword");
    }

    heapptr_t then_expr = parse_expr(input);

    // There must be a then clause
    if (ast_error(then_expr))
    {
        return then_expr;
    }

    heapptr_t else_expr;

    // If these is an else clause
    input_eat_ws(input);
    if (input_match_str(input, "else"))
    {
       else_expr = parse_expr(input);
    }
    else
    {
        else_expr = (heapptr_t)ast_const_alloc(VAL_FALSE);
    }

    return ast_if_alloc(test_expr, then_expr, else_expr);
}
*/

/**
Parse a list of expressions
*/
/*
heapptr_t parse_expr_list(input_t* input, char endCh)
{
    // Allocate an array with an initial capacity
    array_t* arr = array_alloc(4);

    // Until the end of the list
    for (;;)
    {
        // Read whitespace
        input_eat_ws(input);

        // If this is the end of the list
        if (input_match_ch(input, endCh))
        {
            break;
        }

        // Parse an expression
        heapptr_t expr = parse_expr(input);

        // The expression must not fail to parse
        if (ast_error(expr))
        {
            return expr;
        }

        // Write the expression to the array
        array_set_obj(arr, arr->len, expr);

        // Read whitespace
        input_eat_ws(input);

        // If this is the end of the list
        if (input_match_ch(input, endCh))
        {
            break;
        }

        // If this is not the first element, there must be a separator
        if (!input_match_ch(input, ','))
        {
            return ast_error_alloc(input, "expected comma separator in list");
        }
    }

    return (heapptr_t)arr;
}
*/

/**
Parse a sequence expression
*/
/*
heapptr_t parse_seq_expr(input_t* input, char endCh)
{
    // Allocate an array with an initial capacity
    array_t* arr = array_alloc(4);

    // Until the end of the list
    for (;;)
    {
        // Read whitespace
        input_eat_ws(input);

        // If this is the end of the list
        if (input_match_ch(input, endCh))
        {
            break;
        }

        // Parse an expression
        heapptr_t expr = parse_expr(input);

        // The expression must not fail to parse
        if (ast_error(expr))
        {
            return expr;
        }

        // Write the expression to the array
        array_set_obj(arr, arr->len, expr);

        // Read whitespace
        input_eat_ws(input);

        // If this is the end of the list
        if (input_match_ch(input, endCh))
        {
            break;
        }

        // Match a semicolon if one is present (optional)
        if (input_match_ch(input, ';'))
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
heapptr_t parse_fun_expr(input_t* input)
{
    input_eat_ws(input);
    if (!input_match_ch(input, '('))
    {
        return ast_error_alloc(input, "expected parameter list");
    }

    // Allocate an array for the parameter declarations
    array_t* param_decls = array_alloc(4);

    // Until the end of the list
    for (;;)
    {
        // Read whitespace
        input_eat_ws(input);

        // If this is the end of the list
        if (input_match_ch(input, ')'))
            break;

        // Parse an identifier
        heapptr_t ident = parse_ident(input);

        if (ast_error(ident))
            return ident;

        heapptr_t decl = ast_decl_alloc(ident, false);

        // Write the expression to the array
        array_set_obj(param_decls, param_decls->len, decl);

        // Read whitespace
        input_eat_ws(input);

        // If this is the end of the list
        if (input_match_ch(input, ')'))
            break;

        // If this is not the first element, there must be a separator
        if (!input_match_ch(input, ','))
        {
            return ast_error_alloc(input, "expected comma separator in parameter list");
        }
    }

    // Parse the function body
    heapptr_t body_expr = parse_expr(input);

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
heapptr_t parse_obj_expr(input_t* input)
{
    array_t* name_strs = array_alloc(4);
    array_t* val_exprs = array_alloc(4);

    // Until the end of the list
    for (;;)
    {
        // Read whitespace
        input_eat_ws(input);

        // If this is the end of the list
        if (input_match_ch(input, '}'))
        {
            break;
        }

        // Parse the property name
        heapptr_t ident = parse_ident(input);

        if (ast_error(ident))
        {
            return ident;
        }

        input_eat_ws(input);
        if (!input_match_ch(input, ':'))
        {
            return ast_error_alloc(input, "expected : separator");
        }

        // Parse an expression
        heapptr_t expr = parse_expr(input);

        if (ast_error(expr))
        {
            return expr;
        }

        array_set(name_strs, name_strs->len, value_from_heapptr(ident, TAG_STRING));
        array_set_obj(val_exprs, val_exprs->len, expr);

        // If this is the end of the list
        input_eat_ws(input);
        if (input_match_ch(input, '}'))
        {
            break;
        }

        // If this is not the first element, there must be a separator
        if (!input_match_ch(input, ','))
        {
            return ast_error_alloc(input, "expected comma separator in list");
        }
    }

    return ast_obj_alloc(NULL, name_strs, val_exprs);
}
*/

/**
Try to match an operator in the input
*/
/*
const opinfo_t* input_match_op(input_t* input, int minPrec, bool preUnary)
{
    input_t beforeOp = *input;

    char ch = input_peek_ch(input);

    const opinfo_t* op = NULL;

    // Switch on the first character of the operator
    // We do this to avoid a long cascade of match tests
    switch (ch)
    {
        case '.':
        if (input_match_ch(input, '.'))     op = &OP_MEMBER;
        break;

        case '[':
        if (input_match_ch(input, '['))     op = &OP_INDEX;
        break;

        case '(':
        if (input_match_ch(input, '('))     op = &OP_CALL;
        break;

        case 'n':
        if (input_match_str(input, "not"))  op = &OP_NOT;
        break;

        case '*':
        if (input_match_ch(input, '*'))     op = &OP_MUL;
        break;

        case '/':
        if (input_match_ch(input, '/'))     op = &OP_DIV;
        break;

        case 'm':
        if (input_match_str(input, "mod"))  op = &OP_MOD;
        break;

        case '+':
        if (input_match_ch(input, '+'))     op = &OP_ADD;
        break;

        case '-':
        if (input_match_ch(input, '-'))
            op = preUnary? &OP_NEG:&OP_SUB;
        break;

        case '<':
        if (input_match_str(input, "<="))   op = &OP_LE;
        if (input_match_ch(input, '<'))     op = &OP_LT;
        break;

        case '>':
        if (input_match_str(input, ">="))   op = &OP_GE;
        if (input_match_ch(input, '>'))     op = &OP_GT;
        break;

        case 'i':
        if (input_match_str(input, "instanceof")) op = &OP_INST_OF;
        if (input_match_str(input, "in")) op = &OP_IN;
        break;

        case '=':
        if (input_match_str(input, "=="))   op = &OP_EQ;
        if (input_match_ch(input, '='))     op = &OP_ASSIGN;
        break;

        case '!':
        if (input_match_str(input, "!="))   op = &OP_NE;
        break;

        case 'a':
        if (input_match_str(input, "and"))  op = &OP_AND;
        break;

        case 'o':
        if (input_match_str(input, "or"))   op = &OP_OR;
        break;
    }

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

    // Return the matched operator, if any
    return op;
}
*/

/**
Parse a variable declaration
Note: assumes that the "var" keyword has already been matched
*/
/*
heapptr_t parse_var_decl(input_t* input)
{
    input_eat_ws(input);

    heapptr_t ident = parse_ident(input);

    if (ast_error(ident))
    {
        return ast_error_alloc(input, "expected identifier in variable expression");
    }

    return ast_decl_alloc(ident, false);
}
*/

// TODO: rename to parse_let_decl
/**
Parse a constant declaration
Note: assumes that the "let" keyword has already been matched
*/
/*
heapptr_t parse_cst_decl(input_t* input)
{
    input_eat_ws(input);

    heapptr_t ident = parse_ident(input);

    if (ast_error(ident))
    {
        return ast_error_alloc(input, "expected identifier in variable expression");
    }

    input_eat_ws(input);

    // A value must be assigned to the constant declared
    if (!input_match_str(input, "="))
    {
        return ast_error_alloc(input, "expected value assignment in let declaration");
    }

    heapptr_t val = parse_expr(input);

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
/*
heapptr_t parse_atom(input_t* input)
{
    //printf("parse_atom\n");

    // Consume whitespace
    input_eat_ws(input);

    // Numerical constant
    if (isdigit(input_peek_ch(input)))
    {
        return parse_number(input);
    }

    // String literal
    if (input_match_ch(input, '\''))
    {
        return parse_string_lit(input, '\'');
    }
    if (input_match_ch(input, '"'))
    {
        return parse_string_lit(input, '"');
    }

    // Array literal
    if (input_match_ch(input, '['))
    {
        return parse_expr_list(input, ']');
    }

    // Object literal
    if (input_match_str(input, ":{"))
    {
        return parse_obj_expr(input);
    }

    // Parenthesized expression
    if (input_match_ch(input, '('))
    {
        heapptr_t expr = parse_expr(input);
        if (ast_error(expr))
        {
            return ast_error_alloc(input, "expected expression after '('");
        }

        if (!input_match_ch(input, ')'))
        {
            return ast_error_alloc(input, "expected closing parenthesis");
        }

        return expr;
    }

    // Sequence/block expression (i.e { a; b; c }
    if (input_match_ch(input, '{'))
    {
        return parse_seq_expr(input, '}');
    }

    // Try matching a right-associative (prefix) unary operators
    const opinfo_t* op = input_match_op(input, 0, true);

    // If a matching operator was found
    if (op)
    {
        heapptr_t expr = parse_atom(input);
        if (ast_error(expr))
        {
            return expr;
        }

        return (heapptr_t)ast_unop_alloc(op, expr);
    }

    // Identifier
    if (isalnum(input_peek_ch(input)))
    {
        // Variable declaration
        if (input_match_str(input, "var"))
            return parse_var_decl(input);

        // Constant declaration
        if (input_match_str(input, "let"))
            return parse_cst_decl(input);

        // If expression
        if (input_match_str(input, "if"))
            return parse_if_expr(input);

        // Function expression
        if (input_match_str(input, "fun"))
            return parse_fun_expr(input);

        // true and false boolean constants
        if (input_match_str(input, "true"))
            return (heapptr_t)ast_const_alloc(VAL_TRUE);
        if (input_match_str(input, "false"))
            return (heapptr_t)ast_const_alloc(VAL_FALSE);
    }

    // Identifiers beginning with non-alphanumeric characters
    if (input_peek_ch(input) == '_' ||
        input_peek_ch(input) == '$' ||
        isalpha(input_peek_ch(input)))
    {
        return ast_ref_alloc(parse_ident(input));
    }

    // Parsing failed
    return ast_error_alloc(input, "invalid expression");
}
*/

/**
Parse an expression using the precedence climbing algorithm
*/
/*
heapptr_t parse_expr_prec(input_t* input, int minPrec)
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
    heapptr_t lhs_expr = parse_atom(input);

    if (ast_error(lhs_expr))
    {
        return lhs_expr;
    }

    for (;;)
    {
        // Consume whitespace
        input_eat_ws(input);

        //printf("looking for op, minPrec=%d\n", minPrec);

        // Attempt to match an operator in the input
        // with sufficient precedence
        const opinfo_t* op = input_match_op(input, minPrec, false);

        // If no operator matches, break out
        if (op == NULL)
            break;

        //printf("found op: %s\n", op->str);
        //printf("op->prec=%d, minPrec=%d\n", op->prec, minPrec);

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

            if (ast_error(arg_exprs))
                return arg_exprs;

            lhs_expr = ast_call_alloc(lhs_expr, (array_t*)arg_exprs);
        }

        // If this is a member expression
        else if (op == &OP_MEMBER)
        {
            // Parse the identifier string
            heapptr_t ident = parse_ident(input);

            if (ast_error(ident))
            {
                return ast_error_alloc(input, "expected identifier in member expression");
            }

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

            // The rhs expression must parse correctly
            if (ast_error(rhs_expr))
                return rhs_expr;

            // Create a new parent node for the expressions
            lhs_expr = ast_binop_alloc(
                op,
                lhs_expr,
                rhs_expr//, lhs_expr.pos
            );

            // If specified, match the operator closing string
            if (op->close_str && !input_match_str(input, op->close_str))
                return ast_error_alloc(input, "expected operator closing");
        }

        // If this is a unary operator
        else if (op->arity == 1)
        {
            if (op->assoc != 'l')
            {
                return ast_error_alloc(input, "invalid operator");
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
    }

    // Return the parsed expression
    return lhs_expr;
}

/// Parse an expression
heapptr_t parse_expr(input_t* input)
{
    return parse_expr_prec(input, 0);
}
*/

/**
Parse a source unit from an input object
*/
/*
heapptr_t parse_unit(input_t* input)
{
    // Create a sequence expression from the expression list
    heapptr_t seq_expr = parse_seq_expr(input, '\0');

    if (ast_error(seq_expr))
    {
        return seq_expr;
    }

    // Create an empty array for the parameter list
    array_t* param_list = array_alloc(0);

    return ast_fun_alloc(param_list, seq_expr);
}
*/

/**
Parse a source string as a unit
*/
/*
heapptr_t parse_string(const char* cstr, const char* src_name)
{
    input_t input = input_from_string(
        vm_get_cstr(cstr),
        vm_get_cstr("parser_test")
    );

    return parse_unit(&input);
}
*/

/**
Parse a source file
*/
/*
heapptr_t parse_file(const char* file_name)
{
    char* src_text = read_file(file_name);

    heapptr_t unit_fun = parse_string(src_text, file_name);
    
    free(src_text);

    return unit_fun;
}
*/

/**
Check that the parsing of unit was successful
*/
/*
ast_fun_t* parse_check_error(heapptr_t node)
{
    if (ast_error(node))
    {
        ast_error_t* error = (ast_error_t*)node;

        //printf("parsing failed \"%s\"\n", string_cstr(error->src_name));

        char buf[64];
        printf(
            "parsing failed %s - %s\n",
            srcpos_to_str(error->src_pos, buf),
            string_cstr(error->error_str)
        );

        exit(-1);
    }

    assert (get_shape(node) == SHAPE_AST_FUN);
    return (ast_fun_t*)node;
}
*/

/*
/// Test that the parsing of a source unit succeeds
void test_parse(char* cstr)
{
    printf("%s\n", cstr);

    heapptr_t unit = parse_string(cstr, "parser_test");
    assert (unit != NULL);

    if (ast_error(unit))
    {
        parse_check_error(unit);
    }
}

/// Test that the parsing of a source unit fails
void test_parse_fail(char* cstr)
{
    printf("%s\n", cstr);

    heapptr_t unit = parse_string(cstr, "parser_fail_test");
    assert (unit != NULL);

    if (!ast_error(unit))
    {
        printf("parsing did not fail for:\n\"%s\"\n", cstr);
        exit(-1);
    }
}
*/

/// Test the functionality of the parser
void test_parser()
{
    /*
    printf("core parser tests\n");

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
    */

    // Comments
    //test_parse("1 // comment");
    //test_parse("[ 1//comment\n,a ]");
    //test_parse("1 /* comment */ + x");
    //test_parse("1 /* // comment */ + x");
    //test_parse_fail("1 // comment\n#1");
    //test_parse_fail("1 /* */ */");

    /*
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

    parse_check_error(parse_file("global.zeta"));
    parse_check_error(parse_file("parser.zeta"));

    parse_check_error(parse_file("tests/beer.zeta"));
    parse_check_error(parse_file("tests/list-sum.zeta"));
    */
}

