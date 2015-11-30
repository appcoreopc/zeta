import std.format;
import std.conv;

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

    this(string file, int line, int col)
    {
        if (file is null)
            file = "";

        this.file = file;
        this.line = line;
        this.col = col;
    }

    override string toString()
    {
        return format("\"%s\"@%d:%d", file, line, col);
    }
}

/**
Base class for all AST nodes
*/
class ASTNode
{
    SrcPos pos;

    // Force subclasses to set the position
    this(SrcPos pos)
    { 
        this.pos = pos; 
    }
}

/**
Base class for AST expressions
*/
class ASTExpr : ASTNode
{
    this(SrcPos pos) 
    {
        super(pos); 
    }

    /// Get the operator precedence for this expression
    int getPrec()
    {
        // By default, maximum precedence (atomic)
        return MAX_PREC;
    }
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

/**
Constant value AST node
Used for integers, floats and booleans
*/
/*
typedef struct
{
    shapeidx_t shape;

    value_t val;

} ast_const_t;
*/

/**
Variable reference node
*/
/*
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
*/

/**
Variable/constant declaration node
*/
/*
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
*/

/**
Operator information structure
*/
/*
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
*/

/**
Unary operator AST node
*/
/*
typedef struct
{
    shapeidx_t shape;

    const opinfo_t* op;

    heapptr_t expr;

} ast_unop_t;
*/

/**
Binary operator AST node
*/
/*
typedef struct
{
    shapeidx_t shape;

    const opinfo_t* op;

    heapptr_t left_expr;
    heapptr_t right_expr;

} ast_binop_t;
*/

/**
Sequence or block of expressions
*/
/*
typedef struct
{
    shapeidx_t shape;

    // List of expressions
    array_t* expr_list;

} ast_seq_t;
*/

/**
If expression AST node
*/
/*
typedef struct
{
    shapeidx_t shape;

    heapptr_t test_expr;

    heapptr_t then_expr;
    heapptr_t else_expr;

} ast_if_t;
*/

/**
Function call AST node
*/
/*
typedef struct
{
    shapeidx_t shape;

    /// Function to be called
    heapptr_t fun_expr;

    /// Argument expressions
    array_t* arg_exprs;

} ast_call_t;
*/

/**
Function expression node
*/
class FunExpr : ASTExpr
{
    this(/*IdentExpr name, IdentExpr[] params, ASTStmt bodyStmt,*/ SrcPos pos = null)
    {
        super(pos);
    }

    /*
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
    */
}

/**
Object literal
*/
/*
typedef struct
{
    shapeidx_t shape;

    /// Prototype object expression (may be null)
    heapptr_t proto_expr;

    /// Property name strings
    array_t* name_strs;

    /// Property value expressions
    array_t* val_exprs;

} ast_obj_t;
*/

// Maximum operator precedence
const int MAX_PREC = 16;

/// Member operator
immutable OpInfo OP_MEMBER = { ".", null, 2, 16, 'l'};

/*
/// Array indexing
const opinfo_t OP_INDEX = { "[", "]", 2, 16, 'l', false };

/// Function call, variable arity
const opinfo_t OP_CALL = { "(", ")", -1, 15, 'l', false };

/// Prefix unary operators
const opinfo_t OP_NEG = { "-", null, 1, 13, 'r', false };
const opinfo_t OP_NOT = { "not", null, 1, 13, 'r', false };

/// Binary arithmetic operators
const opinfo_t OP_MUL = { "*", null, 2, 12, 'l', false };
const opinfo_t OP_DIV = { "/", null, 2, 12, 'l', true };
const opinfo_t OP_MOD = { "mod", null, 2, 12, 'l', true };
const opinfo_t OP_ADD = { "+", null, 2, 11, 'l', false };
const opinfo_t OP_SUB = { "-", null, 2, 11, 'l', true };

/// Relational operators
const opinfo_t OP_LT = { "<", null, 2, 9, 'l', false };
const opinfo_t OP_LE = { "<=", null, 2, 9, 'l', false };
const opinfo_t OP_GT = { ">", null, 2, 9, 'l', false };
const opinfo_t OP_GE = { ">=", null, 2, 9, 'l', false };
const opinfo_t OP_IN = { "in", null, 2, 9, 'l', false };
const opinfo_t OP_INST_OF = { "instanceof", null, 2, 9, 'l', false };

/// Equality comparison
const opinfo_t OP_EQ = { "==", null, 2, 8, 'l', false };
const opinfo_t OP_NE = { "!=", null, 2, 8, 'l', false };

/// Bitwise operators
const opinfo_t OP_BIT_AND = { "&", null, 2, 7, 'l', false };
const opinfo_t OP_BIT_XOR = { "^", null, 2, 6, 'l', false };
const opinfo_t OP_BIT_OR = { "|", null, 2, 5, 'l', false };

/// Logical operators
const opinfo_t OP_AND = { "and", null, 2, 4, 'l', false };
const opinfo_t OP_OR = { "or", null, 2, 3, 'l', false };

// Assignment
const opinfo_t OP_ASSIGN = { "=", null, 2, 1, 'r', false };
*/

