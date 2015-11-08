#include <stdio.h>
#include <sys/param.h>
#include <string.h>
#include <assert.h>
#ifdef BSD4_4
    #include <stdlib.h>
#else
    #include <alloca.h>
#endif
#include "util.h"
#include "interp.h"
#include "parser.h"
#include "api_core.h"

/// Shape indices for mutable cells, closures and host function wrappers
/// These are initialized in init_interp(), see interp.c
shapeidx_t SHAPE_CELL;
shapeidx_t SHAPE_CLOS;
shapeidx_t SHAPE_HOSTFN;

/**
Initialize the interpreter
*/
void interp_init()
{
    SHAPE_CELL = shape_alloc_empty()->idx;
    SHAPE_CLOS = shape_alloc_empty()->idx;
    SHAPE_HOSTFN = shape_alloc_empty()->idx;
}

/**
Initialize the runtime
*/
void runtime_init()
{
    // Parse the global unit
    ast_fun_t* unit_fun = parse_check_error(parse_file("global.zeta"));

    // Get the list of expressions in the function body
    assert (get_shape(unit_fun->body_expr) == SHAPE_AST_SEQ);
    array_t* exprs = ((ast_seq_t*)unit_fun->body_expr)->expr_list;

    // Initialize the host function wrappers
    array_t* host_fns = init_api_core();

    // Prepend wrapper function definitions to the unit
    for (size_t i = 0; i < host_fns->len; ++i)
    {
        hostfn_t* fn = array_get(host_fns, i).word.hostfn;

        value_t fn_val;
        fn_val.word.hostfn = fn;
        fn_val.tag = TAG_HOSTFN;

        // Prepend a $ character to the function name
        char name[64];
        sprintf(name, "$%s", string_cstr(fn->name));

        heapptr_t decl = ast_decl_alloc((heapptr_t)vm_get_cstr(name), true);
        heapptr_t cst = ast_const_alloc(fn_val);
        heapptr_t assg = ast_binop_alloc(&OP_ASSIGN, decl, cst);
        array_prepend_obj(exprs, assg);
    }

    // Resolve all variables in the global unit
    var_res_pass(unit_fun, NULL);

    // Initialize the global unit
    // This returns a closure which captures all global variables
    value_t global_clos = eval_unit(unit_fun);
    assert (global_clos.tag == TAG_CLOS);

    // Store a pointer to the global unit closure in the VM object
    vm.global_clos = global_clos.word.clos;
}

cell_t* cell_alloc()
{
    cell_t* cell = (cell_t*)vm_alloc(sizeof(cell_t), SHAPE_CELL);

    return cell;
}

clos_t* clos_alloc(ast_fun_t* fun)
{
    clos_t* clos = (clos_t*)vm_alloc(
        sizeof(clos_t) + sizeof(cell_t*) * fun->free_vars->len,
        SHAPE_STRING
    );

    clos->fun = fun;

    return clos;
}

hostfn_t* hostfn_alloc(void* fptr, const char* name, const char* sig_str)
{
    hostfn_t* fn = (hostfn_t*)vm_alloc(
        sizeof(hostfn_t),
        SHAPE_HOSTFN
    );

    fn->fptr = fptr;
    fn->name = vm_get_cstr(name);
    fn->sig_str = vm_get_cstr(sig_str);

    return fn;
}

/**
Find all declarations within an AST subtree
*/
void find_decls(heapptr_t expr, ast_fun_t* fun)
{
    // Get the shape of the AST node
    shapeidx_t shape = get_shape(expr);

    // Constants and strings, do nothing
    if (shape == SHAPE_AST_CONST ||
        shape == SHAPE_STRING)
    {
        return;
    }

    // Array literal expression
    if (shape == SHAPE_ARRAY)
    {
        array_t* array_expr = (array_t*)expr;
        for (size_t i = 0; i < array_expr->len; ++i)
            find_decls(array_get(array_expr, i).word.heapptr, fun);

        return;
    }

    // Variable or constant declaration (let/var)
    if (shape == SHAPE_AST_DECL)
    {
        ast_decl_t* decl = (ast_decl_t*)expr;

        // Mark the declaration as belonging to this function
        assert (fun != NULL);
        decl->fun = fun;

        // If this variable is already declared, do nothing
        for (size_t i = 0; i < fun->local_decls->len; ++i)
        {
            ast_decl_t* local = array_get(fun->local_decls, i).word.decl;
            if (local->name == decl->name)
                return;
        }

        decl->idx = fun->local_decls->len;
        array_set_obj(fun->local_decls, decl->idx, (heapptr_t)decl);

        return;
    }

    // Variable reference
    if (shape == SHAPE_AST_REF)
    {
        return;
    }

    // Sequence/block expression
    if (shape == SHAPE_AST_SEQ)
    {
        ast_seq_t* seqexpr = (ast_seq_t*)expr;
        array_t* expr_list = seqexpr->expr_list;

        for (size_t i = 0; i < expr_list->len; ++i)
            find_decls(array_get(expr_list, i).word.heapptr, fun);

        return;
    }

    // Binary operator (e.g. a + b)
    if (shape == SHAPE_AST_BINOP)
    {
        ast_binop_t* binop = (ast_binop_t*)expr;
        find_decls(binop->left_expr, fun);
        find_decls(binop->right_expr, fun);
        return;
    }

    // Unary operator (e.g. -1)
    if (shape == SHAPE_AST_UNOP)
    {
        ast_unop_t* unop = (ast_unop_t*)expr;
        find_decls(unop->expr, fun);
        return;
    }

    // If expression
    if (shape == SHAPE_AST_IF)
    {
        ast_if_t* ifexpr = (ast_if_t*)expr;
        find_decls(ifexpr->test_expr, fun);
        find_decls(ifexpr->then_expr, fun);
        find_decls(ifexpr->else_expr, fun);
        return;
    }

    // Function/closure expression
    if (shape == SHAPE_AST_FUN)
    {
        // Do nothing. Variables declared in the nested
        // function are not of this scope
        return;
    }

    // Function call
    if (shape == SHAPE_AST_CALL)
    {
        ast_call_t* callexpr = (ast_call_t*)expr;
        array_t* arg_exprs = callexpr->arg_exprs;

        find_decls(callexpr->fun_expr, fun);

        for (size_t i = 0; i < arg_exprs->len; ++i)
            find_decls(array_get_ptr(arg_exprs, i), fun);

        return;
    }

    // Unsupported AST node type
    assert (false);
}

/**
Find the declaration corresponding to a reference,
possibly from outer (nested) scope levels
*/
ast_decl_t* find_decl(ast_ref_t* ref, ast_fun_t* cur_fun)
{
    // For each local declaration
    for (size_t i = 0; i < cur_fun->local_decls->len; ++i)
    {
        ast_decl_t* decl = array_get(cur_fun->local_decls, i).word.decl;

        if (decl->name == ref->name)
            return decl;
    }

    if (cur_fun->parent == NULL)
        return NULL;

    return find_decl(ref, cur_fun->parent);
}

/**
Thread an escaping variable through nested functions
*/
void thread_esc_var(ast_ref_t* ref, ast_fun_t* ref_fun, ast_fun_t* cur_fun)
{
    assert (ref->decl && ref->decl->fun);

    // If the variable is an escaping local of this function
    if (ref->decl->fun == cur_fun && ref_fun != cur_fun)
    {
        // If the variable is already marked escaping here, stop
        uint32_t idx = array_indexof_ptr(cur_fun->esc_locals, (heapptr_t)ref->decl);
        if (idx < cur_fun->esc_locals->len)
            return;

        // Add the variable to the escaping variable set
        array_append_obj(cur_fun->esc_locals, (heapptr_t)ref->decl);
    }

    // If the variable comes from an inner function
    if (ref->decl->fun != cur_fun)
    {
        // If the variable is already marked as free here, stop
        uint32_t idx = array_indexof_ptr(cur_fun->free_vars, (heapptr_t)ref->decl);
        if (idx < cur_fun->free_vars->len)
            return;

        // Add the variable to the free variable set
        array_append_obj(cur_fun->free_vars, (heapptr_t)ref->decl);

        assert (ref->decl->fun != NULL);
        assert (cur_fun->parent != NULL);
        thread_esc_var(ref, ref_fun, cur_fun->parent);
    }
}

void var_res(heapptr_t expr, ast_fun_t* fun)
{
    // Get the shape of the AST node
    shapeidx_t shape = get_shape(expr);

    // Constants and strings, do nothing
    if (shape == SHAPE_AST_CONST ||
        shape == SHAPE_STRING)
    {
        return;
    }

    // Array literal expression
    if (shape == SHAPE_ARRAY)
    {
        array_t* array_expr = (array_t*)expr;
        for (size_t i = 0; i < array_expr->len; ++i)
            var_res(array_get(array_expr, i).word.heapptr, fun);

        return;
    }

    // Variable declaration, do nothing
    if (shape == SHAPE_AST_DECL)
    {
        return;
    }

    // Variable reference
    if (shape == SHAPE_AST_REF)
    {
        ast_ref_t* ref = (ast_ref_t*)expr;

        // Find the declaration for this reference
        ast_decl_t* decl = find_decl(ref, fun);

        if (decl == NULL)
        {
            printf("unresolved reference to \"%s\"\n", string_cstr(ref->name));
            exit(-1);
        }

        // Store the declaration on the reference
        assert (decl->fun != NULL);
        ref->decl = decl;

        // If the variable is from this scope
        if (decl->fun == fun)
        {
            // Store the index of this local
            assert (decl->idx < fun->local_decls->len);
            ref->idx = decl->idx;
        }
        else
        {
            // Mark the variable as escaping
            decl->esc = true;

            // Thread the escaping variable through nested functions
            thread_esc_var(ref, fun, fun);

            // Find the mutable cell index for the variable
            ref->idx = array_indexof_ptr(fun->free_vars, (heapptr_t)ref->decl);
            assert (ref->idx < fun->free_vars->len);
        }

        return;
    }

    // Sequence/block expression
    if (shape == SHAPE_AST_SEQ)
    {
        ast_seq_t* seqexpr = (ast_seq_t*)expr;
        array_t* expr_list = seqexpr->expr_list;

        for (size_t i = 0; i < expr_list->len; ++i)
            var_res(array_get_ptr(expr_list, i), fun);

        return;
    }

    // Binary operator (e.g. a + b)
    if (shape == SHAPE_AST_BINOP)
    {
        ast_binop_t* binop = (ast_binop_t*)expr;

        var_res(binop->left_expr, fun);
        var_res(binop->right_expr, fun);
        return;
    }

    // Unary operator (e.g. -a)
    if (shape == SHAPE_AST_UNOP)
    {
        ast_unop_t* unop = (ast_unop_t*)expr;
        var_res(unop->expr, fun);
        return;
    }

    // If expression
    if (shape == SHAPE_AST_IF)
    {
        ast_if_t* ifexpr = (ast_if_t*)expr;
        var_res(ifexpr->test_expr, fun);
        var_res(ifexpr->then_expr, fun);
        var_res(ifexpr->else_expr, fun);
        return;
    }

    // Function/closure expression
    if (shape == SHAPE_AST_FUN)
    {
        ast_fun_t* child_fun = (ast_fun_t*)expr;

        // Resolve variable references in the nested child function
        var_res_pass(child_fun, fun);

        return;
    }

    // Function call
    if (shape == SHAPE_AST_CALL)
    {
        ast_call_t* callexpr = (ast_call_t*)expr;
        array_t* arg_exprs = callexpr->arg_exprs;

        var_res(callexpr->fun_expr, fun);

        for (size_t i = 0; i < arg_exprs->len; ++i)
            var_res(array_get_ptr(arg_exprs, i), fun);

        return;
    }

    // Unsupported AST node type
    assert (false);
}

/**
Resolve variables in a given function
*/
void var_res_pass(ast_fun_t* fun, ast_fun_t* parent)
{
    fun->parent = parent;

    // Add the function parameters to the local scope
    for (size_t i = 0; i < fun->param_decls->len; ++i)
    {
        find_decls(
            array_get_ptr(fun->param_decls, i),
            fun
        );
        assert (array_get(fun->param_decls, i).word.decl->fun == fun);
    }

    // Find declarations in the function body
    find_decls(fun->body_expr, fun);

    // Resolve variable references
    var_res(fun->body_expr, fun);
}

/**
Evaluate the boolean value of a value
Note: the semantics of boolean evaluation are intentionally
kept strict in the core language.
*/
bool eval_truth(value_t value)
{
    switch (value.tag)
    {
        case TAG_BOOL:
        return value.word.int8 != 0;

        default:
        printf("cannot use value as boolean\n");
        exit(-1);
    }
}

/**
Evaluate an assignment of a value to an expression
*/
value_t eval_assign(
    heapptr_t lhs_expr,
    value_t val,
    clos_t* clos,
    value_t* locals
)
{
    shapeidx_t shape = get_shape(lhs_expr);

    // Assignment to variable declaration
    if (shape == SHAPE_AST_DECL)
    {
        ast_decl_t* decl = (ast_decl_t*)lhs_expr;

        // If this an escaping variable
        if (decl->esc)
        {
            // Escaping variables are stored in mutable cells
            // Pointers to the cells are found on the closure object
            cell_t* cell = locals[decl->idx].word.cell;
            cell->word = val.word;
            cell->tag = val.tag;
            return val;
        }

        // Assign to the stack frame slot directly
        locals[decl->idx] = val;

        return val;
    }

    // Assignment to a variable
    if (shape == SHAPE_AST_REF)
    {
        ast_ref_t* ref = (ast_ref_t*)lhs_expr;
        assert (ref->decl != NULL);

        // If this is a variable from an outer function
        if (ref->decl->fun != clos->fun)
        {
            assert (ref->idx < clos->fun->free_vars->len);
            cell_t* cell = clos->cells[ref->idx];

            cell->word = val.word;
            cell->tag = val.tag;

            return val;
        }

        // Check that the ref index is valid
        if (ref->idx > clos->fun->local_decls->len)
        {
            printf("assignment to invalid index\n");
            exit(-1);
        }

        // If this an escaping variable (captured by a closure)
        if (ref->decl->esc)
        {
            // Escaping variables are stored in mutable cells
            // Pointers to the cells are found on the closure object
            cell_t* cell = locals[ref->idx].word.cell;
            cell->word = val.word;
            cell->tag = val.tag;
            return val;
        }

        // Assign to the stack frame slot directly
        locals[ref->idx] = val;

        return val;
    }

    printf("\n");
    exit(-1);
}

/**
Evaluate a function call
*/
value_t eval_call(
    clos_t* callee,
    array_t* arg_exprs,
    clos_t* caller,
    value_t* caller_locals
)
{
    ast_fun_t* fptr = callee->fun;
    assert (fptr != NULL);

    if (arg_exprs->len != fptr->param_decls->len)
    {
        printf("argument count mismatch\n");
        exit(-1);
    }

    // Allocate space for the local variables
    value_t* callee_locals = alloca(
        sizeof(value_t) * fptr->local_decls->len
    );

    // Allocate mutable cells for the escaping variables
    for (size_t i = 0; i < fptr->esc_locals->len; ++i)
    {
        ast_decl_t* decl = array_get(fptr->esc_locals, i).word.decl;
        assert (decl->esc);
        assert (decl->idx < fptr->local_decls->len);
        callee_locals[decl->idx] = value_from_obj((heapptr_t)cell_alloc());
    }

    // Evaluate the argument values
    for (size_t i = 0; i < arg_exprs->len; ++i)
    {
        //printf("evaluating arg %ld\n", i);

        heapptr_t param_decl = array_get_ptr(fptr->param_decls, i);

        // Evaluate the parameter value
        value_t arg_val = eval_expr(
            array_get_ptr(arg_exprs, i),
            caller,
            caller_locals
        );

        // Assign the value to the parameter
        eval_assign(
            param_decl,
            arg_val,
            callee,
            callee_locals
        );
    }

    // Evaluate the unit function body in the local frame
    return eval_expr(fptr->body_expr, callee, callee_locals);
}

/**
Evaluate a host function call
*/
value_t eval_host_call(
    hostfn_t* callee,
    array_t* arg_exprs,
    clos_t* caller,
    value_t* caller_locals
)
{
    value_t* arg_vals = alloca(sizeof(value_t) * arg_exprs->len);

    // Evaluate the argument values
    for (size_t i = 0; i < arg_exprs->len; ++i)
    {
        //printf("evaluating arg %ld\n", i);

        // Evaluate the parameter value
        arg_vals[i] = eval_expr(
            array_get_ptr(arg_exprs, i),
            caller,
            caller_locals
        );
    }

    // Type test signature
    if (callee->sig_str == vm_get_cstr("bool(tag)"))
    {
        bool (*fptr)(tag_t) = callee->fptr;
        return fptr(arg_vals[0].tag)? VAL_TRUE:VAL_FALSE;
    }

    if (callee->sig_str == vm_get_cstr("void(int)"))
    {
        void (*fptr)(int) = callee->fptr;
        fptr(arg_vals[0].word.int32);
        return VAL_TRUE;
    }

    if (callee->sig_str == vm_get_cstr("void(int64)"))
    {
        void (*fptr)(int64_t) = callee->fptr;
        fptr(arg_vals[0].word.int64);
        return VAL_TRUE;
    }

    if (callee->sig_str == vm_get_cstr("void(string)"))
    {
        void (*fptr)(string_t*) = callee->fptr;
        fptr(arg_vals[0].word.string);
        return VAL_TRUE;
    }

    printf("unsupported host function signature\n");
    exit(-1);
}

/**
Evaluate an expression in a given frame
*/
value_t eval_expr(
    heapptr_t expr, 
    clos_t* clos,
    value_t* locals
)
{
    //printf("eval_expr\n");

    // Get the shape of the AST node
    // Note: AST nodes must match the shapes defined in init_parser,
    // otherwise this interpreter can't handle it
    shapeidx_t shape = get_shape(expr);

    // Variable reference (read)
    if (shape == SHAPE_AST_REF)
    {
        ast_ref_t* ref = (ast_ref_t*)expr;
        assert (ref->decl != NULL);

        //printf("evaluating ref to %s\n", string_cstr(ref->name));

        // If this is a variable from an outer function
        if (ref->decl->fun != clos->fun)
        {
            //printf("ref from outer fun\n");

            assert (ref->idx < clos->fun->free_vars->len);
            cell_t* cell = clos->cells[ref->idx];
            assert (cell != NULL);

            value_t value;
            value.word = cell->word;
            value.tag = cell->tag;

            return value;
        }

        // Check that the ref index is valid
        if (ref->idx > clos->fun->local_decls->len)
        {
            printf("invalid variable reference\n");
            printf("ref->name=%s\n", string_cstr(ref->name));
            printf("ref->idx=%d\n", ref->idx);
            printf("local_decls->len=%d\n", clos->fun->local_decls->len);
            exit(-1);
        }

        // If this an escaping variable (captured by a closure)
        if (ref->decl->esc)
        {
            // Free variables are stored in mutable cells
            // Pointers to the cells are found on the closure object
            cell_t* cell = locals[ref->idx].word.cell;
            value_t value;
            value.word = cell->word;
            value.tag = cell->tag;

            //printf("read value from cell\n");

            return value;
        }

        /*
        printf("reading normal local\n");
        string_print(ref->name);
        printf("\n");
        */

        // Read directly from the stack frame
        return locals[ref->idx];
    }

    if (shape == SHAPE_AST_CONST)
    {
        //printf("constant\n");

        ast_const_t* cst = (ast_const_t*)expr;
        return cst->val;
    }

    if (shape == SHAPE_STRING)
    {
        return value_from_heapptr(expr, TAG_STRING);
    }

    // Array literal expression
    if (shape == SHAPE_ARRAY)
    {
        array_t* array_expr = (array_t*)expr;

        // Array of values to be produced
        array_t* val_array = array_alloc(array_expr->len);

        for (size_t i = 0; i < array_expr->len; ++i)
        {
            heapptr_t expr = array_get(array_expr, i).word.heapptr;
            value_t value = eval_expr(expr, clos, locals);
            array_set(val_array, i, value);
        }

        return value_from_heapptr((heapptr_t)val_array, TAG_ARRAY);
    }

    // Binary operator (e.g. a + b)
    if (shape == SHAPE_AST_BINOP)
    {
        //printf("binop\n");

        ast_binop_t* binop = (ast_binop_t*)expr;

        // Assignment
        if (binop->op == &OP_ASSIGN)
        {
            value_t val = eval_expr(binop->right_expr, clos, locals);

            return eval_assign(
                binop->left_expr, 
                val, 
                clos,
                locals
            );
        }

        value_t v0 = eval_expr(binop->left_expr, clos, locals);
        value_t v1 = eval_expr(binop->right_expr, clos, locals);
        int64_t i0 = v0.word.int64;
        int64_t i1 = v1.word.int64;

        if (binop->op == &OP_INDEX)
            return array_get((array_t*)v0.word.heapptr, i1);

        if (binop->op == &OP_ADD)
            return value_from_int64(i0 + i1);
        if (binop->op == &OP_SUB)
            return value_from_int64(i0 - i1);
        if (binop->op == &OP_MUL)
            return value_from_int64(i0 * i1);
        if (binop->op == &OP_DIV)
            return value_from_int64(i0 / i1);
        if (binop->op == &OP_MOD)
            return value_from_int64(i0 % i1);

        if (binop->op == &OP_LT)
            return (i0 < i1)? VAL_TRUE:VAL_FALSE;
        if (binop->op == &OP_LE)
            return (i0 <= i1)? VAL_TRUE:VAL_FALSE;
        if (binop->op == &OP_GT)
            return (i0 > i1)? VAL_TRUE:VAL_FALSE;
        if (binop->op == &OP_GE)
            return (i0 >= i1)? VAL_TRUE:VAL_FALSE;

        if (binop->op == &OP_EQ)
            return value_equals(v0, v1)? VAL_TRUE:VAL_FALSE;
        if (binop->op == &OP_NE)
            return value_equals(v0, v1)? VAL_FALSE:VAL_TRUE;

        printf("unimplemented binary operator: %s\n", binop->op->str);
        return VAL_FALSE;
    }

    // Unary operator (e.g.: -x, not a)
    if (shape == SHAPE_AST_UNOP)
    {
        ast_unop_t* unop = (ast_unop_t*)expr;

        value_t v0 = eval_expr(unop->expr, clos, locals);

        if (unop->op == &OP_NEG)
            return value_from_int64(-v0.word.int64);

        if (unop->op == &OP_NOT)
            return eval_truth(v0)? VAL_FALSE:VAL_TRUE;

        printf("unimplemented unary operator: %s\n", unop->op->str);
        return VAL_FALSE;
    }

    // Sequence/block expression
    if (shape == SHAPE_AST_SEQ)
    {
        ast_seq_t* seqexpr = (ast_seq_t*)expr;
        array_t* expr_list = seqexpr->expr_list;

        value_t value = VAL_TRUE;

        for (size_t i = 0; i < expr_list->len; ++i)
        {
            heapptr_t expr = array_get(expr_list, i).word.heapptr;
            value = eval_expr(expr, clos, locals);
        }

        // Return the value of the last expression
        return value;
    }

    // If expression
    if (shape == SHAPE_AST_IF)
    {
        ast_if_t* ifexpr = (ast_if_t*)expr;

        value_t t = eval_expr(ifexpr->test_expr, clos, locals);

        if (eval_truth(t))
            return eval_expr(ifexpr->then_expr, clos, locals);
        else
            return eval_expr(ifexpr->else_expr, clos, locals);
    }

    // Function/closure expression
    if (shape == SHAPE_AST_FUN)
    {
        //printf("creating closure\n");

        ast_fun_t* nested = (ast_fun_t*)expr;

        // Allocate a closure of the nested function
        clos_t* new_clos = clos_alloc(nested);

        // For each free (closure) variable of the nested function
        for (size_t i = 0; i < nested->free_vars->len; ++i)
        {
            ast_decl_t* decl = array_get(nested->free_vars, i).word.decl;

            // If the variable is from this function
            if (decl->fun == clos->fun)
            {
                new_clos->cells[i] = locals[decl->idx].word.cell;
            }
            else
            {
                uint32_t free_idx = array_indexof_ptr(clos->fun->free_vars, (heapptr_t)decl);
                assert (free_idx < clos->fun->free_vars->len);
                new_clos->cells[i] = clos->cells[free_idx];
            }
        }

        assert (new_clos->fun == nested);

        return value_from_heapptr((heapptr_t)new_clos, TAG_CLOS);
    }

    // Call expression
    if (shape == SHAPE_AST_CALL)
    {
        //printf("evaluating call\n");

        ast_call_t* callexpr = (ast_call_t*)expr;

        // Evaluate the closure expression
        value_t callee_clos = eval_expr(callexpr->fun_expr, clos, locals);

        if (callee_clos.tag == TAG_CLOS)
        {
            return eval_call(
                callee_clos.word.clos,
                callexpr->arg_exprs,
                clos,
                locals
            );
        }

        if (callee_clos.tag == TAG_HOSTFN)
        {
            return eval_host_call(
                callee_clos.word.hostfn,
                callexpr->arg_exprs,
                clos,
                locals
            );
        }

        printf("invalid callee in function call\n");
        exit(-1);
    }

    printf("eval error, unknown expression type, shapeidx=%d\n", get_shape(expr));
    exit(-1);
}

/**
Evaluate the source code in a given string
This can also be used to evaluate files
*/
value_t eval_unit(ast_fun_t* unit_fun)
{
    assert (unit_fun != NULL);

    if (unit_fun == NULL)
    {
        printf("unit failed to parse\n");
        exit(-1);
    }

    // Resolve all variables in the unit
    var_res_pass(unit_fun, vm.global_clos? vm.global_clos->fun:NULL);

    // Create the unit closure by evaluating the unit function expression
    // This will resolve the free variables for this unit
    value_t unit_clos = eval_expr(
        (heapptr_t)unit_fun,
        vm.global_clos,
        NULL
    );

    // Call the unit function with no arguments
    return eval_call(
        unit_clos.word.clos,
        array_alloc(0),
        NULL,
        NULL
    );
}

/**
Evaluate the source code in a given string
*/
value_t eval_string(const char* cstr, const char* src_name)
{
    ast_fun_t* unit_fun = parse_check_error(parse_string(cstr, src_name));
    return eval_unit(unit_fun);
}

/**
Evaluate a source file
*/
value_t eval_file(const char* file_name)
{
    ast_fun_t* unit_fun = parse_check_error(parse_file(file_name));
    return eval_unit(unit_fun);
}

void test_eval(char* cstr, value_t expected)
{
    printf("%s\n", cstr);

    value_t value = eval_string(cstr, "test");

    if (!value_equals(value, expected))
    {
        printf(
            "value doesn't match expected for input:\n%s\n",
            cstr
        );

        printf("got value:\n");
        value_print(value);
        printf("\n");

        exit(-1);
    }
}

void test_eval_int(char* cstr, int64_t expected)
{
    test_eval(cstr, value_from_int64(expected));
}

void test_eval_true(char* cstr)
{
    test_eval(cstr, VAL_TRUE);
}

void test_eval_false(char* cstr)
{
    test_eval(cstr, VAL_FALSE);
}

void test_interp()
{
    printf("core interpreter tests\n");

    // Empty unit
    test_eval_true("");

    // Literals and constants
    test_eval_int("0", 0);
    test_eval_int("1", 1);
    test_eval_int("7", 7);
    test_eval_int("0xFF", 255);
    test_eval_int("0b101", 5);
    test_eval_true("true");
    test_eval_false("false");

    // Arithmetic
    test_eval_int("3 + 2 * 5", 13);
    test_eval_int("-7", -7);
    test_eval_int("-(7 + 3)", -10);
    test_eval_int("3 + -2 * 5", -7);

    // Comparisons
    test_eval_true("0 < 5");
    test_eval_true("0 <= 5");
    test_eval_true("0 <= 0");
    test_eval_true("0 == 0");
    test_eval_true("0 != 1");
    test_eval_true("not false");
    test_eval_true("not not true");
    test_eval_true("true == true");
    test_eval_false("true == false");
    test_eval_true("'foo' == 'foo'");
    test_eval_false("'foo' == 'bar'");
    test_eval_true("'f' != 'b'");
    test_eval_false("'f' != 'f'");

    // Arrays
    test_eval_int("[7][0]", 7);
    test_eval_int("[0,1,2][0]", 0);
    test_eval_int("[7+3][0]", 10);

    // Sequence expression
    test_eval_true("{}");
    test_eval_int("{ 2 3 }", 3);
    test_eval_int("{ 2 3+7 }", 10);
    test_eval_int("3 7", 7);

    // If expression
    test_eval_int("if true then 1 else 0", 1);
    test_eval_int("if false then 1 else 0", 0);
    test_eval_int("if 0 < 10 then 7 else 3", 7);
    test_eval_int("if not true then 1 else 0", 0);

    // Variable declarations
    test_eval_int("var x = 3    x", 3);
    test_eval_int("let x = 7    x+1", 8);
    test_eval_int("var x = 3    x = 4       x", 4);
    test_eval_int("var x = 3    x = x+1     x", 4);
    test_eval_int("var x = 3    if x != 0 then 1", 1);

    // Closures and function calls
    test_eval_int("fun () 1                   1", 1);
    test_eval_int("let f = fun () 1           1", 1);
    test_eval_int("let f = fun () 7           f()", 7);
    test_eval_int("let f = fun (n) n          f(8)", 8);
    test_eval_int("let f = fun (a, b) a - b   f(7, 2)", 5);

    // Unit-level variable captured by a closure
    test_eval_int("let x = 3    let f = fun () x    1", 1);
    test_eval_int("let x = 3    let f = fun () x    x = 4", 4);
    test_eval_int("let x = 3    let f = fun () x    x", 3);

    // Reading and assigning to a captured variable
    test_eval_int("let a = 3    let f = fun () a    f()", 3);
    test_eval_int("let a = 3    let f = fun () a=2  f()   a", 2);

    // Recursive function
    test_eval_int("let fib = fun (n) { if n < 2 then n else fib(n-1) + fib(n-2) } fib(11)", 89);

    // Two levels of nesting
    test_eval_int("let f = fun () { let x = 7 fun() x }     let g = f()     g()", 7);

    // Capture by inner from outer
    test_eval_int("let n = 5    let f = fun () { fun() n }     let g = f()     g()", 5);

    // Captured function parameter
    test_eval_int("let f = fun (n) { fun () n }      let g = f(88)   g()", 88);

    //eval_file("global.zeta");
}

void test_runtime()
{
    printf("core runtime tests\n");

    test_eval_true("print != false");
    test_eval_true("println != false");
    test_eval_true("assert != false");
    test_eval_true("assert (true, '')   true");







}

