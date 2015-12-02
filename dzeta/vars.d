import ast;

/**
Find all declarations within an AST subtree
*/
void findDecls(ASTExpr expr, FunExpr fun)
{
    /*
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
            findDecls(array_get(array_expr, i).word.heapptr, fun);

        return;
    }

    // Object literal expression
    if (shape == SHAPE_AST_OBJ)
    {
        ast_obj_t* obj_expr = (ast_obj_t*)expr;

        if (obj_expr->proto_expr)
            findDecls(obj_expr->proto_expr, fun);

        for (size_t i = 0; i < obj_expr->val_exprs->len; ++i)
            findDecls(array_get(obj_expr->val_exprs, i).word.heapptr, fun);

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
            findDecls(array_get(expr_list, i).word.heapptr, fun);

        return;
    }

    // Binary operator (e.g. a + b)
    if (shape == SHAPE_AST_BINOP)
    {
        ast_binop_t* binop = (ast_binop_t*)expr;
        findDecls(binop->left_expr, fun);
        findDecls(binop->right_expr, fun);
        return;
    }

    // Unary operator (e.g. -1)
    if (shape == SHAPE_AST_UNOP)
    {
        ast_unop_t* unop = (ast_unop_t*)expr;
        findDecls(unop->expr, fun);
        return;
    }

    // If expression
    if (shape == SHAPE_AST_IF)
    {
        ast_if_t* ifexpr = (ast_if_t*)expr;
        findDecls(ifexpr->test_expr, fun);
        findDecls(ifexpr->then_expr, fun);
        findDecls(ifexpr->else_expr, fun);
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

        findDecls(callexpr->fun_expr, fun);

        for (size_t i = 0; i < arg_exprs->len; ++i)
            findDecls(array_get_ptr(arg_exprs, i), fun);

        return;
    }
    */

    // Unsupported AST node type
    assert (false);
}

/**
Find the declaration corresponding to a reference,
possibly from outer (nested) scope levels
*/
/*
ast_decl_t* findDecl(ast_ref_t* ref, ast_fun_t* cur_fun)
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

    return findDecl(ref, cur_fun->parent);
}*/

/**
Thread an escaping variable through nested functions
*//*
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
}*/

void varRes(ASTExpr expr, FunExpr fun)
{
    /*
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
            varRes(array_get(array_expr, i).word.heapptr, fun);

        return;
    }

    // Object literal expression
    if (shape == SHAPE_AST_OBJ)
    {
        ast_obj_t* obj_expr = (ast_obj_t*)expr;

        if (obj_expr->proto_expr)
            varRes(obj_expr->proto_expr, fun);

        for (size_t i = 0; i < obj_expr->val_exprs->len; ++i)
            varRes(array_get(obj_expr->val_exprs, i).word.heapptr, fun);

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
        ast_decl_t* decl = findDecl(ref, fun);

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
            varRes(array_get_ptr(expr_list, i), fun);

        return;
    }

    // Binary operator (e.g. a + b)
    if (shape == SHAPE_AST_BINOP)
    {
        ast_binop_t* binop = (ast_binop_t*)expr;

        varRes(binop->left_expr, fun);
        varRes(binop->right_expr, fun);
        return;
    }

    // Unary operator (e.g. -a)
    if (shape == SHAPE_AST_UNOP)
    {
        ast_unop_t* unop = (ast_unop_t*)expr;
        varRes(unop->expr, fun);
        return;
    }

    // If expression
    if (shape == SHAPE_AST_IF)
    {
        ast_if_t* ifexpr = (ast_if_t*)expr;
        varRes(ifexpr->test_expr, fun);
        varRes(ifexpr->then_expr, fun);
        varRes(ifexpr->else_expr, fun);
        return;
    }

    // Function/closure expression
    if (shape == SHAPE_AST_FUN)
    {
        ast_fun_t* child_fun = (ast_fun_t*)expr;

        // Resolve variable references in the nested child function
        varResPass(child_fun, fun);

        return;
    }

    // Function call
    if (shape == SHAPE_AST_CALL)
    {
        ast_call_t* callexpr = (ast_call_t*)expr;
        array_t* arg_exprs = callexpr->arg_exprs;

        varRes(callexpr->fun_expr, fun);

        for (size_t i = 0; i < arg_exprs->len; ++i)
            varRes(array_get_ptr(arg_exprs, i), fun);

        return;
    }
    */

    // Unsupported AST node type
    assert (false);
}

/**
Resolve variables in a given function
*/
void varResPass(FunExpr fun, FunExpr parent)
{
    fun.parent = parent;

    /*
    // Add the function parameters to the local scope
    for (size_t i = 0; i < fun->param_decls->len; ++i)
    {
        findDecls(
            array_get_ptr(fun->param_decls, i),
            fun
        );
        assert (array_get(fun->param_decls, i).word.decl->fun == fun);
    }
    */

    // Find declarations in the function body
    findDecls(fun.bodyExpr, fun);

    // Resolve variable references
    varRes(fun.bodyExpr, fun);
}

