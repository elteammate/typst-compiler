#import "reflection-ast.typ": *
#import "reflection.typ": *
#import "pprint.typ": *
#import "typesystem.typ": *
#import "ir-def.typ": *

//#define RECURSE $AST
//#    let __a = context.ast
//#    context.ast = $AST
//#    context = ir_from_ast_(context)
//#    if context.errors.len() > 0 { return context }
//#    let __b = context.ast
//#    context.ast = __a
//#    $AST = __b

//#define COUNTER
//#    { context.counter += 1; context.counter }!

//#define ADD_IR $INSTRUCTION
//#   context.functions.at(context.current_function).code.push($INSTRUCTION)!

//#define IR $I $T $ARGS
//#   {let __a = "%" + str(COUNTER[]); ADD_IR[mk_ir(__a, ir_instruction.$I, $T, $ARGS)]; __a}!

//#define ERROR $MSG
//#   {context.errors.push($MSG); return context}!

//#define LABEL $NAME
//#    context.functions.at(context.current_function).labels.insert(
//#        $NAME, context.functions.at(context.current_function).code.len()
//#    )

//#define DERIVE_FLAGS $FROM
//#   if flags.terminates_function in $FROM { context.ast.terminates_function = true }!

#let ir_from_ast_(context) = {
    if context.errors.len() > 0 { return context }

    if context.ast.type == ast_node_type.content {
        let entry_point = context.counter == 0
        context.ast.ty = types.content
        context.ast.val = IR[const; ptype.content; ""]
        for i, piece in context.ast.fields.pieces {
            RECURSE[context.ast.fields.pieces.at(i)]
            if context.ast.fields.pieces.at(i).ty == types.content {
                context.ast.val = IR[join; ptype.content; context.ast.val, context.ast.fields.pieces.at(i).val]
            } else if context.ast.fields.pieces.at(i).ty != types.none_ {
                ERROR["Type error when joining content pieces"]
            }

            if flags.terminates_function in context.ast.fields.pieces.at(i) {
                context.ast.terminates_function = true
                break
            }
        }

        if entry_point {
            IR[return_; ptype.content; context.ast.val]
        }


    } else if context.ast.type == ast_node_type.content_block {
        context.ast.ty = types.content
        RECURSE[context.ast.fields.content]
        context.ast.val = context.ast.fields.content.val


    } else if context.ast.type == ast_node_type.code_block {
//#define POP_SCOPE
//#     let scope = context.scope_stack.pop()
//#     for _, var in scope {
//#         let lvar = context.functions.at(context.current_function).locals.at(var.name)
//#         context.functions.at(context.current_function).stack_occupancy.at(lvar.stack_pos) = false
//#     }

        let block_type = types.none_
        let val = none
        context.scope_stack.push((:))
        for i, expr in context.ast.fields.statements {
            RECURSE[context.ast.fields.statements.at(i)]
            block_type = type_of_join(block_type, context.ast.fields.statements.at(i).ty)
            if block_type == none {
                ERROR["Type error when joining statements of block"]
            } else if block_type.at(0) != ptype.none_ {
                if val == none {
                    val = context.ast.fields.statements.at(i).val
                } else if context.ast.fields.statements.at(i).ty != types.none_ {
                    val = IR[join; block_type.at(0); val, context.ast.fields.statements.at(i).val]
                }
            }
            if flags.terminates_function in context.ast.fields.statements.at(i) {
                context.ast.terminates_function = true
                break
            }
        }
        POP_SCOPE[]
        context.ast.ty = block_type
        context.ast.val = val


    } else if context.ast.type == ast_node_type.unknown {
        context.ast.ty = types.content
        context.ast.val = IR[const; ptype.content; context.ast.fields.value]

        
    } else if context.ast.type == ast_node_type.literal_int {
        context.ast.ty = types.int
        context.ast.val = IR[const; ptype.int; context.ast.fields.value]


    } else if context.ast.type == ast_node_type.literal_float {
        context.ast.ty = types.float
        context.ast.val = IR[const; ptype.float; context.ast.fields.value]


    } else if context.ast.type == ast_node_type.literal_bool {
        context.ast.ty = types.bool
        context.ast.val = IR[const; ptype.bool; context.ast.fields.value]


    } else if context.ast.type == ast_node_type.literal_string {
        context.ast.ty = types.string
        context.ast.val = IR[const; ptype.string; context.ast.fields.value]


//#define BINOP_ $TYPES $INSTRUCTION
//# if context.ast.fields.lhs.ty != context.ast.fields.rhs.ty or context.ast.fields.lhs.ty.at(0) not in ($TYPES) {
//#     ERROR["Type error when adding expressions (op $INSTRUCTION, allowed types: $TYPES, got: " + repr(context.ast.fields.lhs.ty.at(0)) + " and " + repr(context.ast.fields.rhs.ty.at(0)) + ")"]
//# }
//# context.ast.ty = context.ast.fields.lhs.ty
//# context.ast.val = IR[$INSTRUCTION; context.ast.ty.at(0); context.ast.fields.lhs.val, context.ast.fields.rhs.val]
//# DERIVE_FLAGS[context.ast.fields.lhs]
//# DERIVE_FLAGS[context.ast.fields.rhs]

//#define BINOP $TYPES $INSTRUCTION
//# RECURSE[context.ast.fields.lhs]
//# RECURSE[context.ast.fields.rhs]
//# BINOP_[$TYPES; $INSTRUCTION]


    } else if context.ast.type == ast_node_type.binary_add {
        BINOP[ptype.content, ptype.string, ptype.float, ptype.int, ptype.array, ptype.dictionary; add]
    } else if context.ast.type == ast_node_type.binary_sub {
        BINOP[ptype.float, ptype.int; sub]
    } else if context.ast.type == ast_node_type.binary_div {
        BINOP[ptype.float; div]
    } else if context.ast.type == ast_node_type.binary_mul {
        RECURSE[context.ast.fields.lhs]
        RECURSE[context.ast.fields.rhs]
        if context.ast.fields.lhs.ty.at(0) in (
            ptype.content, 
            ptype.string,
            ptype.array,
        ) and context.ast.fields.rhs.ty.at(0) == ptype.int {
            ERROR["Not implemented"]
        }
        BINOP_[ptype.float, ptype.int; mul]


    } else if context.ast.type == ast_node_type.stmt {
        if context.ast.fields.expr == none {
            context.ast.ty = types.none_
        } else {
            RECURSE[context.ast.fields.expr]
            context.ast.ty = context.ast.fields.expr.ty
            if context.ast.ty != types.none_ {
                context.ast.val = context.ast.fields.expr.val
            }
            DERIVE_FLAGS[context.ast.fields.expr]
        }

        
    } else if context.ast.type == ast_node_type.hash_expr {
        RECURSE[context.ast.fields.expr]
        if context.ast.fields.expr.ty == types.none_ {
            context.ast.ty = types.none_
        } else {
            context.ast.ty = types.content
            if context.ast.fields.expr.ty.at(0) == ptype.content {
                context.ast.val = context.ast.fields.expr.val
            } else if context.ast.fields.expr.ty.at(0) == ptype.int {
                context.ast.val = IR[cast; ptype.content; context.ast.fields.expr.val]
            } else {
                ERROR["Not implemented (cast from " + repr(context.ast.fields.expr.ty.at(0)) + " to content)"]
            }
        }
        DERIVE_FLAGS[context.ast.fields.expr]


    } else if context.ast.type == ast_node_type.paren {
        RECURSE[context.ast.fields.expr]
        context.ast.ty = context.ast.fields.expr.ty
        if context.ast.ty != types.none_ {
            context.ast.val = context.ast.fields.expr.val
        }
        DERIVE_FLAGS[context.ast.fields.expr]


    } else if context.ast.type == ast_node_type.ident {
        let pname = context.ast.fields.name
        let found = false
        for scope in context.scope_stack.rev() {
            if pname in scope {
                let var = scope.at(pname)
                if var.function == context.current_function {
                    context.ast.ty = var.ty
                    context.ast.val = IR[load; var.ty.at(0); var.name]
                    found = true
                    break
                } else {
                    ERROR["Not implemented (captured variable from other function)"]
                }
            }
        }
        if not found {
            ERROR["Variable not found: " + pname]
        }


    } else if context.ast.type == ast_node_type.type_cast {
        RECURSE[context.ast.fields.expr]
        context.ast.ty = type_from_string(context.ast.fields.type)
        if context.ast.ty not in (
            types.none_,
            types.int,
            types.float,
            types.string,
            types.content,
            types.any,
        ) {
            ERROR["Invalid type for cast"]
        }
        if context.ast.fields.expr.ty != types.int {
            ERROR["Not implemented (cast from " + repr(context.ast.ty) + ")"]
        }
        context.ast.val = IR[cast; context.ast.ty.at(0); context.ast.fields.expr.val]
        DERIVE_FLAGS[context.ast.fields.expr]


    } else if context.ast.type == ast_node_type.let_ {

//#define REGISTER_LOCAL_IN_FUNCTION $NAME $TYPE
//#     let stack_pos = context.functions.at(context.current_function).stack_occupancy.position(x => not x)
//#     if stack_pos == none {
//#         stack_pos = context.functions.at(context.current_function).stack_occupancy.len()
//#         context.functions.at(context.current_function).stack_occupancy.push(true)
//#     } else {
//#         context.functions.at(context.current_function).stack_occupancy.at(stack_pos) = true
//#     }
//#     context.functions.at(context.current_function).locals.insert(
//#         $NAME, (ty: $TYPE, stack_pos: stack_pos)
//#     )!

//#define ADD_LOCAL $NAME $TYPE $VALUE
//# {
//#     let pname = $NAME
//#     let ty = $TYPE
//#     let name = "@" + pname + "." + str(COUNTER[])
//#     REGISTER_LOCAL_IN_FUNCTION[name; ty]
//#     context.scope_stack.last().insert(pname, (
//#         ty: ty,
//#         function: context.current_function,
//#         name: name,
//#     ))
//#     IR[store_fast; ty.at(0); name, $VALUE]
//# }!


        if context.ast.fields.params == none {
            RECURSE[context.ast.fields.expr]
            ADD_LOCAL[context.ast.fields.ident.fields.name; 
                context.ast.fields.expr.ty; context.ast.fields.expr.val]
            context.ast.ty = types.none_


        } else {
            let old_function = context.current_function
            let pname = context.ast.fields.ident.fields.name
            let name = "@" + pname + "." + str(COUNTER[])
            context.functions.insert(name, mk_function())

            context.current_function = name
            context.scope_stack.push((:))

            let params = context.ast.fields.params.fields.args
            let positional_param_types = ()
            for i, param in params {
                if param.sink {
                    ERROR["Not implemented (sink parameters)"]
                }

                if param.key != none {
                    ERROR["Not implemented (keyword parameters)"]
                }

                if param.value.type == ast_node_type.ident {
                    let ty = types.any
                    let pref = IR[move_param; ty.at(0); i]
                    ADD_LOCAL[param.value.fields.name; ty; pref]
                    context.functions.at(name).params.push((
                        ty: ty,
                        name: param.value.fields.name,
                        index: i,
                    ))
                    positional_param_types.push(ty)
                } else if param.value.type == ast_node_type.type_cast {
                    let ty = type_from_string(param.value.fields.type)
                    let pref = IR[move_param; ty.at(0); i]
                    let param_name_ = param.value.fields.expr.fields.name
                    ADD_LOCAL[param_name_; ty; pref]
                    context.functions.at(name).params.push((
                        ty: ty,
                        name: param_name_,
                        index: i,
                    ))
                    positional_param_types.push(ty)
                } else {
                    ERROR["Invalid parameter"]
                }
            }

            RECURSE[context.ast.fields.expr]
            let ty = context.ast.fields.expr.ty
            let ret_ty = context.functions.at(name).return_ty
            
            if (flags.terminates_function not in context.ast.fields.expr 
                and context.ast.fields.expr.ty != types.none_) {
                IR[return_; ty.at(0); context.ast.fields.expr.val]
            } else if ty != ret_ty and ret_ty != none {
                ERROR["Return type mismatch: " + type_to_string(ty) + " != " + type_to_string(ret_ty)]
            }

            context.functions.at(name).return_ty = if ty == none and ret_ty == none {
                types.none_
            } else if ty == none {
                ret_ty
            } else {
                ty
            }

            POP_SCOPE[]
            context.current_function = old_function

            if context.functions.at(name).slots != (:) {
                ERROR["Not implemented (slots)"]
            }
            
            let fn_object = IR[mk_function; ptype.none_; name, 0]
            // todo: loading slots here
            ADD_LOCAL[pname; mk_type(
                ptype.function, 
                context.functions.at(name).return_ty, 
                ..positional_param_types,
                slotless: true, // todo: slots
                positional_only: true, // todo: keyword parameters
            ); fn_object]

            context.ast.ty = types.none_
        }


    } else if context.ast.type == ast_node_type.call {
        RECURSE[context.ast.fields.func]
        let func_ty = context.ast.fields.func.ty

        if not func_ty.at(2).positional_only or not func_ty.at(2).slotless {
            ERROR["Not implemented (keyword parameters or slots)"]
        }

        let return_ty = func_ty.at(1).at(0)
        let positional_param_types = func_ty.at(1).slice(1)

        let args = context.ast.fields.args.fields.args

        if args.len() != positional_param_types.len() {
            ERROR["Invalid number of arguments: " + str(args.len()) + 
                " != " + str(positional_param_types.len())]
        }

        let arg_vals = ()

        for i, arg in args {
            if arg.sink {
                ERROR["Not implemented (sink parameters)"]
            }

            if arg.key != none {
                ERROR["Not implemented (keyword parameters)"]
            }

            RECURSE[arg.value]
            let ty = arg.value.ty
            let param_ty = positional_param_types.at(i)
            if ty != param_ty {
                ERROR["Type mismatch in argument: got " + 
                    type_to_string(ty) + " expected " + type_to_string(param_ty)]
            }

            arg_vals.push(arg.value.val)
        }

        let val = IR[call_fast; return_ty.at(0); context.ast.fields.func.val, ..arg_vals]
        context.ast.ty = return_ty
        context.ast.val = val



    } else if context.ast.type == ast_node_type.return_ {
        if context.ast.fields.expr == none {
            ERROR["Not implemented " +
                "(Valueless return is a nightmare and I hate the person who invented it)"]
        
        
        } else {
            RECURSE[context.ast.fields.expr]
            context.ast.ty = types.none_
            let prev_return_ty = context.functions.at(context.current_function).return_ty
            let new_ty = context.ast.fields.expr.ty
            if prev_return_ty != none and prev_return_ty != new_ty {
                ERROR["Return type mismatch: previous: " + 
                    type_to_string(prev_return_ty) + " new: " + 
                    type_to_string(new_ty)]
            }

            context.functions.at(context.current_function).return_ty = new_ty
            if new_ty != types.none_ {
                IR[return_; new_ty.at(0); context.ast.fields.expr.val]
            }
            context.ast.terminates_function = true
        }


    } else if context.ast.type == ast_node_type.assign {
        RECURSE[context.ast.fields.rhs]
//#define LOAD_IDENT $NAME $TY
//# {let found = false; let val = none; let name = $NAME
//# for scope in context.scope_stack.rev() {
//#     if name in scope {
//#         let var = scope.at(name)
//#         if var.function == context.current_function {
//#             if ($TY) != var.ty { ERROR["Type mismatch"] }
//#             val = IR[load_addr; var.ty.at(0); var.name]
//#             found = true
//#             break
//#         } else {
//#             break
//#         }
//#     }
//# }
//# if not found {
//#     ERROR["Variable not found: " + name]
//# }
//# val }!

        context.ast.ty = types.none_
        if context.ast.fields.lhs.type == ast_node_type.ident {
            IR[store_fast; context.ast.fields.rhs.ty.at(0); 
                context.ast.fields.lhs.fields.name, context.ast.fields.rhs.val]
        } else {
            ERROR["Not implemented"]
        }
        DERIVE_FLAGS[context.ast.fields.rhs]


    } else if context.ast.type == ast_node_type.add_assign {
//#define REWRITE_ASSIGN $op
//# context.ast = mk_node(
//#     ast_node_type.assign,
//#     lhs: context.ast.fields.lhs,
//#         rhs: mk_node(
//#             ast_node_type.$op,
//#             lhs: context.ast.fields.lhs,
//#             rhs: context.ast.fields.rhs,
//#         ),
//#     )
//# RECURSE[context.ast]

        REWRITE_ASSIGN[binary_add]
    } else if context.ast.type == ast_node_type.sub_assign {
        REWRITE_ASSIGN[binary_sub]
    } else if context.ast.type == ast_node_type.mul_assign {
        REWRITE_ASSIGN[binary_mul]
    } else if context.ast.type == ast_node_type.div_assign {
        REWRITE_ASSIGN[binary_div]


    } else if context.ast.type == ast_node_type.if_ {
        RECURSE[context.ast.fields.expr]
        if context.ast.fields.expr.ty != types.bool {
            ERROR["If condition must be a boolean"]
        }

//#define TEMP_VAR
//# ("@temp." + str(COUNTER[]))!

        let temp_var = TEMP_VAR[]
        let false_label = ".FALSE." + str(COUNTER[])
        let end_label = ".END." + str(COUNTER[])

        IR[goto_if_not; ptype.none_; context.ast.fields.expr.val, false_label]

        RECURSE[context.ast.fields.block]

        context.ast.ty = types.none_

        if context.ast.fields.else_ == none {
            if context.ast.fields.block.ty != types.none_ {
                ERROR["If block can't return a value if there is no else block, returned: " + 
                    type_to_string(context.ast.fields.block.ty)]
            }
            LABEL[false_label]
        } else {
            if (
                context.ast.fields.block.ty != types.none_ and 
                    flags.terminates_function not in context.ast.fields.block
            ) {
                IR[store_fast; context.ast.fields.block.ty.at(0); temp_var, context.ast.fields.block.val]
                context.ast.ty = context.ast.fields.block.ty
            }
            IR[goto; ptype.none_; end_label]
            LABEL[false_label]
            RECURSE[context.ast.fields.else_]
            if (
                context.ast.fields.else_.ty != context.ast.fields.block.ty and
                    flags.terminates_function not in context.ast.fields.block and
                    flags.terminates_function not in context.ast.fields.else_
            ) {
                ERROR["If and else blocks must return the same type, returned: " + 
                    type_to_string(context.ast.fields.block.ty) + " and " + 
                    type_to_string(context.ast.fields.else_.ty)]
            }
            if (
                context.ast.fields.else_.ty != types.none_ and
                    flags.terminates_function not in context.ast.fields.else_
            ) {
                IR[store_fast; context.ast.fields.else_.ty.at(0); temp_var, context.ast.fields.else_.val]
                context.ast.ty = context.ast.fields.else_.ty
            }
            LABEL[end_label]
            
            if (flags.terminates_function in context.ast.fields.block 
                and flags.terminates_function in context.ast.fields.else_) {
                context.ast.terminates_function = true
            }
        }

        if context.ast.ty != types.none_ {
            context.ast.val = IR[load; context.ast.ty.at(0); temp_var]
            REGISTER_LOCAL_IN_FUNCTION[temp_var; context.ast.ty]
        }


    } else if context.ast.type == ast_node_type.while_ {
        let start_label = ".WHILE_START." + str(COUNTER[])
        let end_label = ".WHILE_END." + str(COUNTER[])
        context.loop_stack.push((start: start_label, end: end_label))
        // let temp_var = TEMP_VAR[]

        LABEL[start_label]
        RECURSE[context.ast.fields.expr]
        if context.ast.fields.expr.ty != types.bool {
            ERROR["While condition must be a boolean"]
        }
        IR[goto_if_not; ptype.none_; context.ast.fields.expr.val, end_label]
        RECURSE[context.ast.fields.block]
        IR[goto; ptype.none_; start_label]
        LABEL[end_label]

        let _ = context.loop_stack.pop()
        context.ast.ty = types.none_


    } else if context.ast.type == ast_node_type.continue_ {
        if context.loop_stack.len() == 0 {
            ERROR["Continue outside of loop"]
        }
        let loop = context.loop_stack.last()
        IR[goto; ptype.none_; loop.start]
        context.ast.ty = types.none_
    

    } else if context.ast.type == ast_node_type.break_ {
        if context.loop_stack.len() == 0 {
            ERROR["Break outside of loop"]
        }
        let loop = context.loop_stack.last()
        IR[goto; ptype.none_; loop.end]
        context.ast.ty = types.none_


    } else {
        ERROR["Unknown AST node type"]
    }

    return context
}

#let ir_from_ast(ast) = ir_from_ast_((
    ast: ast,
    functions: (entry: mk_function()),
    errors: (),
    scope_stack: ((:), ),
    loop_stack: (),
    counter: 0,
    current_function: "entry",
))

#{
    let ast = parse("#let f(/*int*/x, /*bool*/y) = { [base: ]; if y { [1] } else { return [2] } };#f(5,false)")
    // pprint(ast)
    let ir = ir_from_ast(ast)
    pprint(ir)
}
