#import "reflection-ast.typ": *
#import "reflection.typ": *
#import "pprint.typ": *
#import "typesystem.typ": *
#import "ir-def.typ": *








#let ir_from_ast_(context) = {
    if context.errors.len() > 0 { return context }

    if context.ast.type == ast_node_type.content {
        let entry_point = context.counter == 0
        context.ast.ty = types.content
        context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.const, ptype.content, "")); __a}
        for i, piece in context.ast.fields.pieces {
            let __a = context.ast
context.ast = context.ast.fields.pieces.at(i)
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.pieces.at(i) = __b

            if context.ast.fields.pieces.at(i).ty == types.content {
                context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.join, ptype.content, context.ast.val, context.ast.fields.pieces.at(i).val)); __a}
            } else if context.ast.fields.pieces.at(i).ty != types.none_ {
                {context.errors.push("Type error when joining content pieces"); return context}
            }

            if flags.terminates_function in context.ast.fields.pieces.at(i) {
                context.ast.terminates_function = true
                break
            }
        }

        if entry_point {
            {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.return_, ptype.content, context.ast.val)); __a}
        }


    } else if context.ast.type == ast_node_type.content_block {
        context.ast.ty = types.content
        let __a = context.ast
context.ast = context.ast.fields.content
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.content = __b

        context.ast.val = context.ast.fields.content.val


    } else if context.ast.type == ast_node_type.code_block {

        let block_type = types.none_
        let val = none
        context.scope_stack.push((:))
        for i, expr in context.ast.fields.statements {
            let __a = context.ast
context.ast = context.ast.fields.statements.at(i)
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.statements.at(i) = __b

            block_type = type_of_join(block_type, context.ast.fields.statements.at(i).ty)
            if block_type == none {
                {context.errors.push("Type error when joining statements of block"); return context}
            } else if block_type.at(0) != ptype.none_ {
                if val == none {
                    val = context.ast.fields.statements.at(i).val
                } else if context.ast.fields.statements.at(i).ty != types.none_ {
                    val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.join, block_type.at(0), val, context.ast.fields.statements.at(i).val)); __a}
                }
            }
            if flags.terminates_function in context.ast.fields.statements.at(i) {
                context.ast.terminates_function = true
                break
            }
        }
        let scope = context.scope_stack.pop()
for _, var in scope {
let lvar = context.functions.at(context.current_function).locals.at(var.name)
context.functions.at(context.current_function).stack_occupancy.at(lvar.stack_pos) = false
}

        context.ast.ty = block_type
        context.ast.val = val


    } else if context.ast.type == ast_node_type.unknown {
        context.ast.ty = types.content
        context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.const, ptype.content, context.ast.fields.value)); __a}

        
    } else if context.ast.type == ast_node_type.literal_int {
        context.ast.ty = types.int
        context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.const, ptype.int, context.ast.fields.value)); __a}


    } else if context.ast.type == ast_node_type.literal_float {
        context.ast.ty = types.float
        context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.const, ptype.float, context.ast.fields.value)); __a}


    } else if context.ast.type == ast_node_type.literal_bool {
        context.ast.ty = types.bool
        context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.const, ptype.bool, context.ast.fields.value)); __a}


    } else if context.ast.type == ast_node_type.literal_string {
        context.ast.ty = types.string
        context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.const, ptype.string, context.ast.fields.value)); __a}





    } else if context.ast.type == ast_node_type.binary_add {
        let __a = context.ast
context.ast = context.ast.fields.lhs
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.lhs = __b

let __a = context.ast
context.ast = context.ast.fields.rhs
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.rhs = __b

if context.ast.fields.lhs.ty != context.ast.fields.rhs.ty or context.ast.fields.lhs.ty.at(0) not in (ptype.content, ptype.string, ptype.float, ptype.int, ptype.array, ptype.dictionary) {
{context.errors.push("Type error when adding expressions (op add, allowed types: ptype.content, ptype.string, ptype.float, ptype.int, ptype.array, ptype.dictionary, got: " + repr(context.ast.fields.lhs.ty.at(0)) + " and " + repr(context.ast.fields.rhs.ty.at(0)) + ")"); return context}
}
context.ast.ty = context.ast.fields.lhs.ty
context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.add, context.ast.ty.at(0), context.ast.fields.lhs.val, context.ast.fields.rhs.val)); __a}
if flags.terminates_function in context.ast.fields.lhs { context.ast.terminates_function = true }
if flags.terminates_function in context.ast.fields.rhs { context.ast.terminates_function = true }


    } else if context.ast.type == ast_node_type.binary_sub {
        let __a = context.ast
context.ast = context.ast.fields.lhs
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.lhs = __b

let __a = context.ast
context.ast = context.ast.fields.rhs
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.rhs = __b

if context.ast.fields.lhs.ty != context.ast.fields.rhs.ty or context.ast.fields.lhs.ty.at(0) not in (ptype.float, ptype.int) {
{context.errors.push("Type error when adding expressions (op sub, allowed types: ptype.float, ptype.int, got: " + repr(context.ast.fields.lhs.ty.at(0)) + " and " + repr(context.ast.fields.rhs.ty.at(0)) + ")"); return context}
}
context.ast.ty = context.ast.fields.lhs.ty
context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.sub, context.ast.ty.at(0), context.ast.fields.lhs.val, context.ast.fields.rhs.val)); __a}
if flags.terminates_function in context.ast.fields.lhs { context.ast.terminates_function = true }
if flags.terminates_function in context.ast.fields.rhs { context.ast.terminates_function = true }


    } else if context.ast.type == ast_node_type.binary_div {
        let __a = context.ast
context.ast = context.ast.fields.lhs
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.lhs = __b

let __a = context.ast
context.ast = context.ast.fields.rhs
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.rhs = __b

if context.ast.fields.lhs.ty != context.ast.fields.rhs.ty or context.ast.fields.lhs.ty.at(0) not in (ptype.float) {
{context.errors.push("Type error when adding expressions (op div, allowed types: ptype.float, got: " + repr(context.ast.fields.lhs.ty.at(0)) + " and " + repr(context.ast.fields.rhs.ty.at(0)) + ")"); return context}
}
context.ast.ty = context.ast.fields.lhs.ty
context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.div, context.ast.ty.at(0), context.ast.fields.lhs.val, context.ast.fields.rhs.val)); __a}
if flags.terminates_function in context.ast.fields.lhs { context.ast.terminates_function = true }
if flags.terminates_function in context.ast.fields.rhs { context.ast.terminates_function = true }


    } else if context.ast.type == ast_node_type.binary_mul {
        let __a = context.ast
context.ast = context.ast.fields.lhs
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.lhs = __b

        let __a = context.ast
context.ast = context.ast.fields.rhs
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.rhs = __b

        if context.ast.fields.lhs.ty.at(0) in (
            ptype.content, 
            ptype.string,
            ptype.array,
        ) and context.ast.fields.rhs.ty.at(0) == ptype.int {
            {context.errors.push("Not implemented"); return context}
        }
        if context.ast.fields.lhs.ty != context.ast.fields.rhs.ty or context.ast.fields.lhs.ty.at(0) not in (ptype.float, ptype.int) {
{context.errors.push("Type error when adding expressions (op mul, allowed types: ptype.float, ptype.int, got: " + repr(context.ast.fields.lhs.ty.at(0)) + " and " + repr(context.ast.fields.rhs.ty.at(0)) + ")"); return context}
}
context.ast.ty = context.ast.fields.lhs.ty
context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.mul, context.ast.ty.at(0), context.ast.fields.lhs.val, context.ast.fields.rhs.val)); __a}
if flags.terminates_function in context.ast.fields.lhs { context.ast.terminates_function = true }
if flags.terminates_function in context.ast.fields.rhs { context.ast.terminates_function = true }



    } else if context.ast.type == ast_node_type.stmt {
        if context.ast.fields.expr == none {
            context.ast.ty = types.none_
        } else {
            let __a = context.ast
context.ast = context.ast.fields.expr
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.expr = __b

            context.ast.ty = context.ast.fields.expr.ty
            if context.ast.ty != types.none_ {
                context.ast.val = context.ast.fields.expr.val
            }
            if flags.terminates_function in context.ast.fields.expr { context.ast.terminates_function = true }
        }

        
    } else if context.ast.type == ast_node_type.hash_expr {
        let __a = context.ast
context.ast = context.ast.fields.expr
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.expr = __b

        if context.ast.fields.expr.ty == types.none_ {
            context.ast.ty = types.none_
        } else {
            context.ast.ty = types.content
            if context.ast.fields.expr.ty.at(0) == ptype.content {
                context.ast.val = context.ast.fields.expr.val
            } else if context.ast.fields.expr.ty.at(0) == ptype.int {
                context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.cast, ptype.content, context.ast.fields.expr.val)); __a}
            } else {
                {context.errors.push("Not implemented (cast from " + repr(context.ast.fields.expr.ty.at(0)) + " to content)"); return context}
            }
        }
        if flags.terminates_function in context.ast.fields.expr { context.ast.terminates_function = true }


    } else if context.ast.type == ast_node_type.paren {
        let __a = context.ast
context.ast = context.ast.fields.expr
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.expr = __b

        context.ast.ty = context.ast.fields.expr.ty
        if context.ast.ty != types.none_ {
            context.ast.val = context.ast.fields.expr.val
        }
        if flags.terminates_function in context.ast.fields.expr { context.ast.terminates_function = true }


    } else if context.ast.type == ast_node_type.ident {
        let pname = context.ast.fields.name
        let found = false
        for scope in context.scope_stack.rev() {
            if pname in scope {
                let var = scope.at(pname)
                if var.function == context.current_function {
                    context.ast.ty = var.ty
                    context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.load, var.ty.at(0), var.name)); __a}
                    found = true
                    break
                } else {
                    {context.errors.push("Not implemented (captured variable from other function)"); return context}
                }
            }
        }
        if not found {
            {context.errors.push("Variable not found: " + pname); return context}
        }


    } else if context.ast.type == ast_node_type.type_cast {
        let __a = context.ast
context.ast = context.ast.fields.expr
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.expr = __b

        context.ast.ty = type_from_string(context.ast.fields.type)
        if context.ast.ty not in (
            types.none_,
            types.int,
            types.float,
            types.string,
            types.content,
            types.any,
        ) {
            {context.errors.push("Invalid type for cast"); return context}
        }
        if context.ast.fields.expr.ty != types.int {
            {context.errors.push("Not implemented (cast from " + repr(context.ast.ty) + ")"); return context}
        }
        context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.cast, context.ast.ty.at(0), context.ast.fields.expr.val)); __a}
        if flags.terminates_function in context.ast.fields.expr { context.ast.terminates_function = true }


    } else if context.ast.type == ast_node_type.let_ {




        if context.ast.fields.params == none {
            let __a = context.ast
context.ast = context.ast.fields.expr
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.expr = __b

            {
let pname = context.ast.fields.ident.fields.name
let ty = context.ast.fields.expr.ty
let name = "@" + pname + "." + str({ context.counter += 1; context.counter })
let stack_pos = context.functions.at(context.current_function).stack_occupancy.position(x => not x)
if stack_pos == none {
stack_pos = context.functions.at(context.current_function).stack_occupancy.len()
context.functions.at(context.current_function).stack_occupancy.push(true)
} else {
context.functions.at(context.current_function).stack_occupancy.at(stack_pos) = true
}
context.functions.at(context.current_function).locals.insert(
name, (ty: ty, stack_pos: stack_pos)
)
context.scope_stack.last().insert(pname, (
ty: ty,
function: context.current_function,
name: name,
))
{let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.store_fast, ty.at(0), name, context.ast.fields.expr.val)); __a}
}
            context.ast.ty = types.none_


        } else {
            let old_function = context.current_function
            let pname = context.ast.fields.ident.fields.name
            let name = "@" + pname + "." + str({ context.counter += 1; context.counter })
            context.functions.insert(name, mk_function())

            context.current_function = name
            context.scope_stack.push((:))

            let params = context.ast.fields.params.fields.args
            let positional_param_types = ()
            for i, param in params {
                if param.sink {
                    {context.errors.push("Not implemented (sink parameters)"); return context}
                }

                if param.key != none {
                    {context.errors.push("Not implemented (keyword parameters)"); return context}
                }

                if param.value.type == ast_node_type.ident {
                    let ty = types.any
                    let pref = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.move_param, ty.at(0), i)); __a}
                    {
let pname = param.value.fields.name
let ty = ty
let name = "@" + pname + "." + str({ context.counter += 1; context.counter })
let stack_pos = context.functions.at(context.current_function).stack_occupancy.position(x => not x)
if stack_pos == none {
stack_pos = context.functions.at(context.current_function).stack_occupancy.len()
context.functions.at(context.current_function).stack_occupancy.push(true)
} else {
context.functions.at(context.current_function).stack_occupancy.at(stack_pos) = true
}
context.functions.at(context.current_function).locals.insert(
name, (ty: ty, stack_pos: stack_pos)
)
context.scope_stack.last().insert(pname, (
ty: ty,
function: context.current_function,
name: name,
))
{let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.store_fast, ty.at(0), name, pref)); __a}
}
                    context.functions.at(name).params.push((
                        ty: ty,
                        name: param.value.fields.name,
                        index: i,
                    ))
                    positional_param_types.push(ty)
                } else if param.value.type == ast_node_type.type_cast {
                    let ty = type_from_string(param.value.fields.type)
                    let pref = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.move_param, ty.at(0), i)); __a}
                    let param_name_ = param.value.fields.expr.fields.name
                    {
let pname = param_name_
let ty = ty
let name = "@" + pname + "." + str({ context.counter += 1; context.counter })
let stack_pos = context.functions.at(context.current_function).stack_occupancy.position(x => not x)
if stack_pos == none {
stack_pos = context.functions.at(context.current_function).stack_occupancy.len()
context.functions.at(context.current_function).stack_occupancy.push(true)
} else {
context.functions.at(context.current_function).stack_occupancy.at(stack_pos) = true
}
context.functions.at(context.current_function).locals.insert(
name, (ty: ty, stack_pos: stack_pos)
)
context.scope_stack.last().insert(pname, (
ty: ty,
function: context.current_function,
name: name,
))
{let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.store_fast, ty.at(0), name, pref)); __a}
}
                    context.functions.at(name).params.push((
                        ty: ty,
                        name: param_name_,
                        index: i,
                    ))
                    positional_param_types.push(ty)
                } else {
                    {context.errors.push("Invalid parameter"); return context}
                }
            }

            let __a = context.ast
context.ast = context.ast.fields.expr
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.expr = __b

            let ty = context.ast.fields.expr.ty
            let ret_ty = context.functions.at(name).return_ty
            
            if (flags.terminates_function not in context.ast.fields.expr 
                and context.ast.fields.expr.ty != types.none_) {
                {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.return_, ty.at(0), context.ast.fields.expr.val)); __a}
            } else if ty != ret_ty and ret_ty != none {
                {context.errors.push("Return type mismatch: " + type_to_string(ty) + " != " + type_to_string(ret_ty)); return context}
            }

            context.functions.at(name).return_ty = if ty == none and ret_ty == none {
                types.none_
            } else if ty == none {
                ret_ty
            } else {
                ty
            }

            let scope = context.scope_stack.pop()
for _, var in scope {
let lvar = context.functions.at(context.current_function).locals.at(var.name)
context.functions.at(context.current_function).stack_occupancy.at(lvar.stack_pos) = false
}

            context.current_function = old_function

            if context.functions.at(name).slots != (:) {
                {context.errors.push("Not implemented (slots)"); return context}
            }
            
            let fn_object = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.mk_function, ptype.none_, name, 0)); __a}
            // todo: loading slots here
            {
let pname = pname
let ty = mk_type(
                ptype.function, 
                context.functions.at(name).return_ty, 
                ..positional_param_types,
                slotless: true, // todo: slots
                positional_only: true, // todo: keyword parameters
            )
let name = "@" + pname + "." + str({ context.counter += 1; context.counter })
let stack_pos = context.functions.at(context.current_function).stack_occupancy.position(x => not x)
if stack_pos == none {
stack_pos = context.functions.at(context.current_function).stack_occupancy.len()
context.functions.at(context.current_function).stack_occupancy.push(true)
} else {
context.functions.at(context.current_function).stack_occupancy.at(stack_pos) = true
}
context.functions.at(context.current_function).locals.insert(
name, (ty: ty, stack_pos: stack_pos)
)
context.scope_stack.last().insert(pname, (
ty: ty,
function: context.current_function,
name: name,
))
{let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.store_fast, ty.at(0), name, fn_object)); __a}
}

            context.ast.ty = types.none_
        }


    } else if context.ast.type == ast_node_type.call {
        let __a = context.ast
context.ast = context.ast.fields.func
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.func = __b

        let func_ty = context.ast.fields.func.ty

        if not func_ty.at(2).positional_only or not func_ty.at(2).slotless {
            {context.errors.push("Not implemented (keyword parameters or slots)"); return context}
        }

        let return_ty = func_ty.at(1).at(0)
        let positional_param_types = func_ty.at(1).slice(1)

        let args = context.ast.fields.args.fields.args

        if args.len() != positional_param_types.len() {
            {context.errors.push("Invalid number of arguments: " + str(args.len()) + 
                " != " + str(positional_param_types.len())); return context}
        }

        let arg_vals = ()

        for i, arg in args {
            if arg.sink {
                {context.errors.push("Not implemented (sink parameters)"); return context}
            }

            if arg.key != none {
                {context.errors.push("Not implemented (keyword parameters)"); return context}
            }

            let __a = context.ast
context.ast = arg.value
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
arg.value = __b

            let ty = arg.value.ty
            let param_ty = positional_param_types.at(i)
            if ty != param_ty {
                {context.errors.push("Type mismatch in argument: got " + 
                    type_to_string(ty) + " expected " + type_to_string(param_ty)); return context}
            }

            arg_vals.push(arg.value.val)
        }

        let val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.call_fast, return_ty.at(0), context.ast.fields.func.val, ..arg_vals)); __a}
        context.ast.ty = return_ty
        context.ast.val = val



    } else if context.ast.type == ast_node_type.return_ {
        if context.ast.fields.expr == none {
            {context.errors.push("Not implemented " +
                "(Valueless return is a nightmare and I hate the person who invented it)"); return context}
        
        
        } else {
            let __a = context.ast
context.ast = context.ast.fields.expr
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.expr = __b

            context.ast.ty = types.none_
            let prev_return_ty = context.functions.at(context.current_function).return_ty
            let new_ty = context.ast.fields.expr.ty
            if prev_return_ty != none and prev_return_ty != new_ty {
                {context.errors.push("Return type mismatch: previous: " + 
                    type_to_string(prev_return_ty) + " new: " + 
                    type_to_string(new_ty)); return context}
            }

            context.functions.at(context.current_function).return_ty = new_ty
            if new_ty != types.none_ {
                {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.return_, new_ty.at(0), context.ast.fields.expr.val)); __a}
            }
            context.ast.terminates_function = true
        }


    } else if context.ast.type == ast_node_type.assign {
        let __a = context.ast
context.ast = context.ast.fields.rhs
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.rhs = __b


        context.ast.ty = types.none_
        if context.ast.fields.lhs.type == ast_node_type.ident {
            {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.store_fast, context.ast.fields.rhs.ty.at(0), context.ast.fields.lhs.fields.name, context.ast.fields.rhs.val)); __a}
        } else {
            {context.errors.push("Not implemented"); return context}
        }
        if flags.terminates_function in context.ast.fields.rhs { context.ast.terminates_function = true }


    } else if context.ast.type == ast_node_type.add_assign {

        context.ast = mk_node(
ast_node_type.assign,
lhs: context.ast.fields.lhs,
rhs: mk_node(
ast_node_type.binary_add,
lhs: context.ast.fields.lhs,
rhs: context.ast.fields.rhs,
),
)
let __a = context.ast
context.ast = context.ast
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast = __b


    } else if context.ast.type == ast_node_type.sub_assign {
        context.ast = mk_node(
ast_node_type.assign,
lhs: context.ast.fields.lhs,
rhs: mk_node(
ast_node_type.binary_sub,
lhs: context.ast.fields.lhs,
rhs: context.ast.fields.rhs,
),
)
let __a = context.ast
context.ast = context.ast
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast = __b


    } else if context.ast.type == ast_node_type.mul_assign {
        context.ast = mk_node(
ast_node_type.assign,
lhs: context.ast.fields.lhs,
rhs: mk_node(
ast_node_type.binary_mul,
lhs: context.ast.fields.lhs,
rhs: context.ast.fields.rhs,
),
)
let __a = context.ast
context.ast = context.ast
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast = __b


    } else if context.ast.type == ast_node_type.div_assign {
        context.ast = mk_node(
ast_node_type.assign,
lhs: context.ast.fields.lhs,
rhs: mk_node(
ast_node_type.binary_div,
lhs: context.ast.fields.lhs,
rhs: context.ast.fields.rhs,
),
)
let __a = context.ast
context.ast = context.ast
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast = __b




    } else if context.ast.type == ast_node_type.if_ {
        let __a = context.ast
context.ast = context.ast.fields.expr
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.expr = __b

        if context.ast.fields.expr.ty != types.bool {
            {context.errors.push("If condition must be a boolean"); return context}
        }


        let temp_var = ("@temp." + str({ context.counter += 1; context.counter }))
        let false_label = ".FALSE." + str({ context.counter += 1; context.counter })
        let end_label = ".END." + str({ context.counter += 1; context.counter })

        {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.goto_if_not, ptype.none_, context.ast.fields.expr.val, false_label)); __a}

        let __a = context.ast
context.ast = context.ast.fields.block
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.block = __b


        context.ast.ty = types.none_

        if context.ast.fields.else_ == none {
            if context.ast.fields.block.ty != types.none_ {
                {context.errors.push("If block can't return a value if there is no else block, returned: " + 
                    type_to_string(context.ast.fields.block.ty)); return context}
            }
            context.functions.at(context.current_function).labels.insert(
false_label, context.functions.at(context.current_function).code.len()
)

        } else {
            if (
                context.ast.fields.block.ty != types.none_ and 
                    flags.terminates_function not in context.ast.fields.block
            ) {
                {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.store_fast, context.ast.fields.block.ty.at(0), temp_var, context.ast.fields.block.val)); __a}
                context.ast.ty = context.ast.fields.block.ty
            }
            {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.goto, ptype.none_, end_label)); __a}
            context.functions.at(context.current_function).labels.insert(
false_label, context.functions.at(context.current_function).code.len()
)

            let __a = context.ast
context.ast = context.ast.fields.else_
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.else_ = __b

            if (
                context.ast.fields.else_.ty != context.ast.fields.block.ty and
                    flags.terminates_function not in context.ast.fields.block and
                    flags.terminates_function not in context.ast.fields.else_
            ) {
                {context.errors.push("If and else blocks must return the same type, returned: " + 
                    type_to_string(context.ast.fields.block.ty) + " and " + 
                    type_to_string(context.ast.fields.else_.ty)); return context}
            }
            if (
                context.ast.fields.else_.ty != types.none_ and
                    flags.terminates_function not in context.ast.fields.else_
            ) {
                {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.store_fast, context.ast.fields.else_.ty.at(0), temp_var, context.ast.fields.else_.val)); __a}
                context.ast.ty = context.ast.fields.else_.ty
            }
            context.functions.at(context.current_function).labels.insert(
end_label, context.functions.at(context.current_function).code.len()
)

            
            if (flags.terminates_function in context.ast.fields.block 
                and flags.terminates_function in context.ast.fields.else_) {
                context.ast.terminates_function = true
            }
        }

        if context.ast.ty != types.none_ {
            context.ast.val = {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.load, context.ast.ty.at(0), temp_var)); __a}
            let stack_pos = context.functions.at(context.current_function).stack_occupancy.position(x => not x)
if stack_pos == none {
stack_pos = context.functions.at(context.current_function).stack_occupancy.len()
context.functions.at(context.current_function).stack_occupancy.push(true)
} else {
context.functions.at(context.current_function).stack_occupancy.at(stack_pos) = true
}
context.functions.at(context.current_function).locals.insert(
temp_var, (ty: context.ast.ty, stack_pos: stack_pos)
)
        }


    } else if context.ast.type == ast_node_type.while_ {
        let start_label = ".WHILE_START." + str({ context.counter += 1; context.counter })
        let end_label = ".WHILE_END." + str({ context.counter += 1; context.counter })
        context.loop_stack.push((start: start_label, end: end_label))
        // let temp_var = ("@temp." + str({ context.counter += 1; context.counter }))

        context.functions.at(context.current_function).labels.insert(
start_label, context.functions.at(context.current_function).code.len()
)

        let __a = context.ast
context.ast = context.ast.fields.expr
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.expr = __b

        if context.ast.fields.expr.ty != types.bool {
            {context.errors.push("While condition must be a boolean"); return context}
        }
        {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.goto_if_not, ptype.none_, context.ast.fields.expr.val, end_label)); __a}
        let __a = context.ast
context.ast = context.ast.fields.block
context = ir_from_ast_(context)
if context.errors.len() > 0 { return context }
let __b = context.ast
context.ast = __a
context.ast.fields.block = __b

        {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.goto, ptype.none_, start_label)); __a}
        context.functions.at(context.current_function).labels.insert(
end_label, context.functions.at(context.current_function).code.len()
)


        let _ = context.loop_stack.pop()
        context.ast.ty = types.none_


    } else if context.ast.type == ast_node_type.continue_ {
        if context.loop_stack.len() == 0 {
            {context.errors.push("Continue outside of loop"); return context}
        }
        let loop = context.loop_stack.last()
        {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.goto, ptype.none_, loop.start)); __a}
        context.ast.ty = types.none_
    

    } else if context.ast.type == ast_node_type.break_ {
        if context.loop_stack.len() == 0 {
            {context.errors.push("Break outside of loop"); return context}
        }
        let loop = context.loop_stack.last()
        {let __a = "%" + str({ context.counter += 1; context.counter }); context.functions.at(context.current_function).code.push(mk_ir(__a, ir_instruction.goto, ptype.none_, loop.end)); __a}
        context.ast.ty = types.none_


    } else {
        {context.errors.push("Unknown AST node type"); return context}
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