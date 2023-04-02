#import "utils.typ": *

#let flags = mk_enum(
    debug: true, // do not remove
    "terminates_function"
)


#let ir_instruction = mk_enum(
    debug: true,
    "const",
    "load",
    "load_addr",
    "store",
    "store_fast",
    "drop",
    "cast",
    "goto",
    "goto_if_not",
    "add",
    "sub",
    "mul",
    "div",
    "join",
    "move_param",
    "load_slot",
    "mk_function",
    "call_fast",
    "return_",
)

#let mk_ir(res, instr, ty, ..args) = (res: res, instr: instr, ty: ty, args: args.pos())

#let mk_function() = (
    locals: (:), code: (), 
    labels: (:), params: (),
    stack_occupancy: (),
    slots: (:), return_ty: none
)
