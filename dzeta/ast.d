import std.format;
import std.conv;
import std.stdint;

/**
Operator information structure
*/
struct OpInfo
{
    /// Operator string (e.g. "+")
    string str;

    /// Closing string (optional)
    string closeStr;

    /// Operator arity
    int arity;

    /// Precedence level
    int prec;

    /// Associativity, left-to-right or right-to-left ('l' or 'r')
    char assoc;

    /// Non-associative flag (e.g.: - and / are not associative)
    bool nonAssoc = false;
}

alias immutable(OpInfo)* Operator;

/**
Source code position
*/
class SrcPos
{
    /// File name
    string file;

    /// Line number
    int line;

    /// Column number
    int col;

    this(string file)
    {
        if (file is null)
            file = "";

        this.file = file;
        this.line = 1;
        this.col = 1;
    }

    override string toString()
    {
        return format("\"%s\"@%d:%d", file, line, col);
    }
}

/**
Base class for all AST nodes/expressions
*/
class ASTExpr
{
    SrcPos pos;

    private this(SrcPos pos) 
    {
        this.pos = pos;
    }

    /// Get the operator precedence for this expression
    int getPrec()
    {
        // By default, maximum precedence (atomic)
        return MAX_PREC;
    }
}

/**
True boolean constant expression
*/
class TrueExpr : ASTExpr
{
    this(SrcPos pos = null)
    {
        super(pos);
    }

    override string toString()
    {
        return "true";
    }
}

/**
False boolean constant expression
*/
class FalseExpr : ASTExpr
{
    this(SrcPos pos = null)
    {
        super(pos);
    }

    override string toString()
    {
        return "false";
    }
}

/**
Integer constant expression
*/
class IntExpr : ASTExpr
{
    long val;

    this(long val, SrcPos pos = null)
    {
        super(pos);
        this.val = val;
    }

    override string toString()
    {
        return to!(string)(val);
    }
}

/**
Floating-point constant expression
*/
class FloatExpr : ASTExpr
{
    double val;

    this(double val, SrcPos pos = null)
    {
        super(pos);
        this.val = val;
    }

    /*
    override string toString()
    {
        if (floor(val) == val)
            return format("%.1f", val);
        else
            return format("%G", val);
    }
    */
}

/**
String-constant expression
*/
class StringExpr : ASTExpr
{
    string val;

    this(string val, SrcPos pos = null)
    {
        super(pos);
        this.val = val;
    }

    /*
    override string toString()
    {
        return "\"" ~ to!string(escapeJSString(val)) ~ "\"";
    }
    */
}

/**
Binary operator expression
*/
class BinOpExpr : ASTExpr
{
    /// Binary operator
    Operator op;

    /// Subexpressions
    ASTExpr lExpr;
    ASTExpr rExpr;

    this(Operator op, ASTExpr lExpr, ASTExpr rExpr, SrcPos pos = null)
    {
        assert (op !is null, "operator is null");
        assert (op.arity == 2, "invalid arity");

        super(pos);
        this.op = op;
        this.lExpr = lExpr;
        this.rExpr = rExpr;
    }

    override int getPrec()
    {
        return op.prec;
    }

    override string toString()
    {
        string opStr;

        if (op.str == ".")
            opStr = ".";
        else if (op.str == ",")
            opStr = ", ";
        else
            opStr = " " ~ to!string(op.str) ~ " ";

        auto lStr = lExpr.toString();
        auto rStr = rExpr.toString();

        string output;

        if ((lExpr.getPrec() < op.prec) ||
            (lExpr.getPrec() == op.prec && op.nonAssoc && op.assoc == 'r') ||
            (cast(FunExpr)lExpr))
            output ~= "(" ~ lStr ~ ")";
        else
            output ~= lStr;

        output ~= opStr;

        if ((rExpr.getPrec() < op.prec) ||
            (rExpr.getPrec() == op.prec && op.nonAssoc && op.assoc == 'l'))
            output ~= "(" ~ rStr ~ ")";
        else
            output ~= rStr;

        return output;
    }
}

/**
Unary operator expression
*/
class UnOpExpr : ASTExpr
{
    /// Unary operator
    Operator op;

    /// Subexpression
    ASTExpr expr;

    this(Operator op, ASTExpr expr, SrcPos pos = null)
    {
        assert (op.arity == 1);

        super(pos);
        this.op = op;
        this.expr = expr;
    }

    override int getPrec()
    {
        return op.prec;
    }

    override string toString()
    {
        string exprStr = expr.toString();
        if (expr.getPrec() < op.prec)
            exprStr = "(" ~ exprStr ~ ")";

        if (op.assoc == 'r')
            return format("%s%s", op.str, exprStr);
        else
            return format("%s%s", exprStr, op.str);
    }
}

// TODO: may want to replace ConstExpr with IntExpr, StringExpr, etc
/**
Constant value AST node
Used for integers, floats and booleans
*/
class ConstExpr : ASTExpr
{
    // TODO: value
    this(SrcPos pos = null)
    {
        super(pos);
    }

    //value_t val;
}

/**
Variable reference node
*/
class RefExpr : ASTExpr
{
    /// Identifier name string
    string name;

    /// Resolved declaration, null if global
    //ast_decl_t* decl;

    this(string name, SrcPos pos = null)
    {
        super(pos);
        this.name = name;
    }
}

/**
Variable/constant declaration node
*/
class DeclExpr : ASTExpr
{
    /// Identifier name string
    string name;

    /// Function the declaration belongs to (resolved later)
    FunExpr fun = null;

    /// Escaping variable (captured by nested function, resolved later)
    bool esc = false;

    /// Constant flag
    bool cst;

    this(string name, bool cst, SrcPos pos = null)
    {
        super(pos);
        this.name = name;
        this.cst = cst;
    }
}

/**
Sequence or block of expressions
*/
class SeqExpr : ASTExpr
{
    // List of expressions
    ASTExpr[] exprList;

    this(ASTExpr[] exprList, SrcPos pos = null)
    {
        super(pos);
        this.exprList = exprList;
    }
}

/**
If expression AST node
*/
class IfExpr : ASTExpr
{
    ASTExpr testExpr;
    ASTExpr thenExpr;
    ASTExpr elseExpr;

    this(
        ASTExpr testExpr,
        ASTExpr thenExpr,
        ASTExpr elseExpr,
        SrcPos pos = null
    )
    {
        super(pos);
        this.testExpr = testExpr;
        this.thenExpr = thenExpr;
        this.elseExpr = elseExpr;
    }
}

/**
Function call AST node
*/
class CallExpr : ASTExpr
{
    /// Function to be called
    ASTExpr funExpr;

    /// Argument expressions
    ASTExpr[] argExprs;

    this(ASTExpr funExpr, ASTExpr[] argExprs, SrcPos pos = null)
    {
        super(pos);
        this.funExpr = funExpr;
        this.argExprs = argExprs;
    }
}

/**
Function expression node
*/
class FunExpr : ASTExpr
{
    /// Parent (outer) function
    FunExpr parent = null;

    /// Ordered list of parameter declarations
    DeclExpr[] paramDecls;

    /// Set of local variable declarations
    /// Note: this list also includes the parameters
    /// Note: Variables captured by nested functions have the capt flag set
    //array_t* local_decls;

    // Set of local variables escaping into inner/nested functions
    //array_t* esc_locals;

    /// Set of variables captured from outer/parent functions
    /// Note: this does not include variables from the global object
    /// Note: the value of these are stored in closure objects
    //array_t* free_vars;

    /// Function body expression
    ASTExpr bodyExpr;

    this(DeclExpr[] paramDecls, ASTExpr bodyExpr, SrcPos pos = null)
    {
        super(pos);
        this.paramDecls = paramDecls;
        this.bodyExpr = bodyExpr;
    }
}

/**
Object literal
*/
class ObjExpr : ASTExpr
{
    /// Prototype object expression (may be null)
    ASTExpr protoExpr;

    /// Property name strings
    string[] nameStrs;

    /// Property value expressions
    ASTExpr[] valExprs;

    this(string[] nameStrs, ASTExpr[] valExprs, SrcPos pos = null)
    {
        super(pos);
        this.nameStrs = nameStrs;
        this.valExprs = valExprs;
    }
}

/**
Array literal
*/
class ArrayExpr : ASTExpr
{
    ASTExpr[] valExprs;

    this(ASTExpr[] valExprs, SrcPos pos = null)
    {
        super(pos);
        this.valExprs = valExprs;
    }
}

// Maximum operator precedence
const int MAX_PREC = 16;

/// Member operator
immutable OpInfo OP_MEMBER = { ".", null, 2, 16, 'l'};

/// Array indexing
immutable OpInfo OP_INDEX = { "[", "]", 2, 16, 'l', false };

/// Function call, variable arity
immutable OpInfo OP_CALL = { "(", ")", -1, 15, 'l', false };

/// Prefix unary operators
immutable OpInfo OP_NEG = { "-", null, 1, 13, 'r', false };
immutable OpInfo OP_NOT = { "not", null, 1, 13, 'r', false };

/// Binary arithmetic operators
immutable OpInfo OP_MUL = { "*", null, 2, 12, 'l', false };
immutable OpInfo OP_DIV = { "/", null, 2, 12, 'l', true };
immutable OpInfo OP_MOD = { "mod", null, 2, 12, 'l', true };
immutable OpInfo OP_ADD = { "+", null, 2, 11, 'l', false };
immutable OpInfo OP_SUB = { "-", null, 2, 11, 'l', true };

/// Relational operators
immutable OpInfo OP_LT = { "<", null, 2, 9, 'l', false };
immutable OpInfo OP_LE = { "<=", null, 2, 9, 'l', false };
immutable OpInfo OP_GT = { ">", null, 2, 9, 'l', false };
immutable OpInfo OP_GE = { ">=", null, 2, 9, 'l', false };
immutable OpInfo OP_IN = { "in", null, 2, 9, 'l', false };
immutable OpInfo OP_ISA = { "isa", null, 2, 9, 'l', false };

/// Equality comparison
immutable OpInfo OP_EQ = { "==", null, 2, 8, 'l', false };
immutable OpInfo OP_NE = { "!=", null, 2, 8, 'l', false };

/// Bitwise operators
immutable OpInfo OP_BIT_AND = { "&", null, 2, 7, 'l', false };
immutable OpInfo OP_BIT_XOR = { "^", null, 2, 6, 'l', false };
immutable OpInfo OP_BIT_OR = { "|", null, 2, 5, 'l', false };

/// Logical operators
immutable OpInfo OP_AND = { "and", null, 2, 4, 'l', false };
immutable OpInfo OP_OR = { "or", null, 2, 3, 'l', false };

// Assignment
immutable OpInfo OP_ASSIGN = { "=", null, 2, 1, 'r', false };

