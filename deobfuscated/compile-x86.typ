#import "utils.typ": *
#import "typesystem.typ": *
#import "ir-def.typ": *
#import "utils-asm-highlighting.typ": *

#let registers = (
    "rax", "rbx", "rcx", "rdx",
    "rsi", "rdi",
    "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15",
)

#let fp_registers = (
    "xmm0","xmm1", "xmm2", "xmm3", "xmm4", "xmm5", "xmm6", "xmm7",
    "xmm8", "xmm9","xmm10", "xmm11", "xmm12", "xmm13", "xmm14", "xmm15",
)

#let external_function = mk_enum(
    debug: true,
    "content_join",
    "mk_function",
    "cast_int_to_content",
)

//#define ESCAPE $L
//# (($L).replace("%", "_P_").replace("@", "_A_").replace(".", "_"))!

// Returns the assembly instruction with indentation
//#define ASM $I
//# ("    " + $I)!

// Pushes the instruction to the code
//#define EMIT $I
//# code.push(ASM[$I])!

// Pushes the label to the code
//#define LABEL $L
//# code.push(ESCAPE[$L] + ":")!

// Marks register $R as allocated. Register MUST be free
//#define ALLOCATE $R
//# { let r = $R; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
//# allocated_num_registers.push(r); r }!

// Marks register $R as free. Register MUST be allocated
//#define FREE $R
//# { let r = $R; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
//# free_num_registers.push(r); r }!

// Returns a free register and mark it as allocated. 
// If no free registers are available, a register is forced to be freed/
//#define GET_FREE_REGISTER
//#({
//#    if free_num_registers.len() > 0 {
//#        ALLOCATE[free_num_registers.first()]
//#    } else {
//#        let reg = FORCE_FREE_REGISTER[allocated_num_registers.first()]
//#        ALLOCATE[reg]
//#    }
//#})!

// Forces an allocated register $R to be freed, returns free register
//#define FORCE_FREE_REGISTER $R
//# ({
//#     let reg = $R
//#     let pos = temp_values_occupancy.position(x => not x)
//#     if pos == none {
//#         pos = temp_values_occupancy.len()
//#         temp_values_occupancy.push(true)
//#     } else {
//#         temp_values_occupancy.at(pos) = true
//#     }
//#     EMIT["mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg]
//#     let val = values_in_registers.at(reg)
//#     let _ = FREE[reg]
//#     locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
//#     reg
//#})!

// Returns the FREED register that contains the value $V
//#define VALUE_IN_REGISTER $V
//# ({
//#     let val = $V
//#     if is_register(locations.at(val)) {
//#         let reg = locations.at(val)
//#         if last_use.at(val) == line {
//#             let _ = FREE[reg]
//#         }
//#         reg
//#     } else {
//#         let reg = GET_FREE_REGISTER[]
//#         EMIT["mov " + reg + ", " + locations.at(val)]
//#         if last_use.at(val) != line {
//#             locations.insert(val, reg)
//#             values_in_registers.insert(reg, val)
//#         }
//#         reg
//#     }
//# })!

// Moves value $V to FREE register $R and allocates it
//#define MOVE_VALUE_TO_REGISTER $V $R
//# ({
//#     let val = $V
//#     let reg = $R
//#     if locations.at(val) != reg {
//#         if is_register(locations.at(val)) {
//#             let _ = FREE[locations.at(val)]
//#         }
//#         EMIT["mov " + reg + ", " + locations.at(val)]
//#         let _ = ALLOCATE[reg]
//#         locations.insert(val, reg)
//#         values_in_registers.insert(reg, val)
//#     }
//#     reg
//# })!

// Returns location of the value $V
//#define LOCAL_VALUE_LOCATION $V
//# ({
//#     let location = function.locals.at($V).stack_pos
//#     "[rbp - " + str(location * 8 + 8) + "]"
//# })!

// Marks the value $V as used in the register $R, marks the register as allocated
//#define ASSIGN_REGISTER_TO_VALUE $R $V
//# ({
//#     locations.insert($V, $R)
//#     values_in_registers.insert($R, $V)
//#     if $R not in allocated_num_registers {
//#         let _ = ALLOCATE[$R]
//#     }
//#     $R
//# })!

// Returns an allocated register with the value $V assigned to it
//#define ASSIGN_FREE_REGISTER_TO_VALUE $V
//# ({
//#     let reg = GET_FREE_REGISTER[]
//#     ASSIGN_REGISTER_TO_VALUE[reg; $V]
//# })!

// Returns a constant label with the name $C
//#define ALLOCATE_CONSTANT $C
//# ({
//#    let c = $C
//#    let name = ESCAPE["%%const_" + str(constant_counter) + "_" + function_name]
//#    constants.insert(name, "db `" + c.replace("\n", "\\n") + "`, 0")
//#    constant_counter = constant_counter + 1
//#    name
//# })!

// Frees all allocated registers required to be unused before a function call 
//#define PREPARE_FUNCTION_CALL
//# ({
//#     for reg in allocated_num_registers {
//#         if reg in ("rax", "rdi", "rsi", "rdx", "rcx", "r8", "r9") {
//#             FORCE_FREE_REGISTER[reg]
//#         }
//#     }
//#     EMIT["xor rax, rax"]
//# })

//#define CLEANUP_FUNCTION_CALL
//# ({
//#     for reg in allocated_num_registers {
//#         if reg in ("rdi", "rsi", "rdx", "rcx", "r8", "r9") {
//#             let _ = FREE[reg]
//#         }
//#     }
//# })


#let is_register(x) = x in registers

#let compile_function(function_name, function) = {
    let code = ()
    let constants = (:)
    let constant_counter = 0

    let free_num_registers = (
        "rdi", "rsi", "rdx", "rcx",
        "r8", "r9", "rax", "r10", "r11",
    )

    let allocated_num_registers = (
         "rbx", "r12", "r13", "r14", "r15",
    )

    let locations = (:)
    let values_in_registers = (:)
    let reserved = ()

    for i, reg in allocated_num_registers {
        let res = "%%res." + str(i)
        locations.insert(res, reg)
        values_in_registers.insert(reg, res)
        reserved.push(res)
    }

    let allocated_fp_registers = ()

    let param_locations = ()

    let int_param_counter = 0
    let float_param_counter = 0
    let stack_param_counter = 0

    for param in function.params {
        if int_param_counter < 6 {
            param_locations.push(free_num_registers.first())
            let _ = ALLOCATE[free_num_registers.first()]
            int_param_counter += 1
        } else {
            param_locations.push("[rbp + " + str(8 * stack_param_counter + 16) + "]")
            stack_param_counter += 1
        }
    }

    let labels_by_line = range(function.code.len() + 1).map(x => ())
    for label_name, label_line in function.labels {
        labels_by_line.at(label_line).push(label_name.replace(".", "_"))
    }

    let temp_values_occupancy = ()
    let temp_var_offset = 8 * function.stack_occupancy.len()
    
    
    let last_use = (:)

    for line, instr in function.code {
        for arg in instr.args {
            if type(arg) == "string" and arg.len() > 0 and arg.at(0) == "%" {
                last_use.insert(arg, line)
            }
        }
    }


    for line, instr in function.code {
        for label in labels_by_line.at(line) {
            LABEL[label]
        }

        let opcode = instr.instr
        let ty = instr.ty
        let res = instr.res
        let args = instr.args

        if opcode == ir_instruction.move_param {
            let param_no = args.at(0)
            let location = param_locations.at(param_no)
            if is_register(location) {
                locations.insert(res, location)
            } else {
                let reg = GET_FREE_REGISTER[]
                EMIT["mov " + reg + ", " + location]
                locations.insert(res, reg)
                values_in_registers.insert(reg, res)
            }
        
        
        } else if opcode == ir_instruction.store_fast {
            let reg = VALUE_IN_REGISTER[args.at(1)]
            EMIT["mov " + LOCAL_VALUE_LOCATION[args.at(0)] + ", " + reg]
        
        
        } else if opcode == ir_instruction.load {
            let reg = ASSIGN_FREE_REGISTER_TO_VALUE[res]
            let location = function.locals.at(args.at(0)).stack_pos
            EMIT["mov " + reg + ", " + LOCAL_VALUE_LOCATION[args.at(0)]]


        } else if opcode == ir_instruction.const {
            if ty == ptype.int {
                let reg = ASSIGN_FREE_REGISTER_TO_VALUE[res]
                EMIT["mov " + reg + ", " + args.at(0)]
            } else if ty == ptype.content {
                let reg = ASSIGN_FREE_REGISTER_TO_VALUE[res]
                let name = ALLOCATE_CONSTANT[args.at(0)]
                EMIT["mov " + reg + ", " + name]
            }


//#define BINOP $OPCODE
//# if ty == ptype.int {
//#     let reg1 = VALUE_IN_REGISTER[args.at(0)]
//#     let reg2 = VALUE_IN_REGISTER[args.at(1)]
//#     if last_use.at(args.at(0)) == line {
//#         ASSIGN_REGISTER_TO_VALUE[reg1; res]
//#         EMIT["$OPCODE " + reg1 + ", " + reg2]
//#     } else {
//#         let reg = ASSIGN_FREE_REGISTER_TO_VALUE[res]
//#         EMIT["mov " + reg + ", " + reg1]
//#         EMIT["$OPCODE " + reg + ", " + reg2]
//#     }
//# }

        } else if opcode == ir_instruction.add {
            BINOP[add]
        } else if opcode == ir_instruction.sub {
            BINOP[sub]
        } else if opcode == ir_instruction.mul {
            if ty == ptype.int {
                if "rdx" in allocated_num_registers { FORCE_FREE_REGISTER["rdx"] }
                if "rcx" in allocated_num_registers { FORCE_FREE_REGISTER["rcx"] }
                MOVE_VALUE_TO_REGISTER[args.at(1); "rcx"]
                if "rax" in allocated_num_registers { FORCE_FREE_REGISTER["rax"] }
                MOVE_VALUE_TO_REGISTER[args.at(0); "rax"]
                if last_use.at(args.at(0)) == line {
                    ASSIGN_REGISTER_TO_VALUE["rax"; res]
                    EMIT["mul rcx"]
                }
            }


        } else if opcode == ir_instruction.return_ {
            if ty != ptype.none_ {
                let reg = VALUE_IN_REGISTER[args.at(0)]
                EMIT["mov rax, " + reg]
            } else {
                EMIT["xor rax, rax"]
            }
            EMIT["mov rsp, rbp"]
            EMIT["pop rbp"]
            EMIT["ret"]
        
        
        } else if opcode == ir_instruction.join {
            if ty == ptype.content {
                PREPARE_FUNCTION_CALL[]
                MOVE_VALUE_TO_REGISTER[args.at(0); "rdi"]
                MOVE_VALUE_TO_REGISTER[args.at(1); "rsi"]
                EMIT["call " + external_function.content_join]
                ASSIGN_REGISTER_TO_VALUE["rax"; res]
                CLEANUP_FUNCTION_CALL[]
            }


        } else if opcode == ir_instruction.cast {
            if ty == ptype.content {
                PREPARE_FUNCTION_CALL[]
                MOVE_VALUE_TO_REGISTER[args.at(0); "rdi"]
                EMIT["call " + external_function.cast_int_to_content]
                ASSIGN_REGISTER_TO_VALUE["rax"; res]
                CLEANUP_FUNCTION_CALL[]
            }


        } else if opcode == ir_instruction.mk_function {
            PREPARE_FUNCTION_CALL[]
            let escaped_label = ESCAPE[args.at(0)]
            EMIT["mov rdi, " + escaped_label]
            EMIT["mov rsi, " + str(args.at(1))]
            EMIT["call " + external_function.mk_function]
            ASSIGN_REGISTER_TO_VALUE["rax"; res]
            CLEANUP_FUNCTION_CALL[]
    

        } else if opcode == ir_instruction.call_fast {
            FORCE_FREE_REGISTER["rbx"]
            PREPARE_FUNCTION_CALL[]
            let arg_regs = ("rdi", "rsi", "rdx", "rcx", "r8", "r9")
            for arg_no, arg in args.slice(1, calc.min(args.len(), arg_regs.len() + 1)) {
                MOVE_VALUE_TO_REGISTER[arg; arg_regs.at(arg_no)]            
            }
            if args.len() > arg_regs.len() + 1 {
                for arg in args.slice(arg_regs.len() + 1).rev() {
                    MOVE_VALUE_TO_REGISTER[arg; "rbx"]
                    EMIT["push rbx"]
                    FREE["rbx"]
                    locations.remove(arg)
                    values_in_registers.remove("rbx")
                }
            }
            MOVE_VALUE_TO_REGISTER[args.at(0); "rbx"]
            EMIT["mov rbx, [rbx]"]
            EMIT["call rbx"]
            ASSIGN_REGISTER_TO_VALUE["rax"; res]
            if args.len() > arg_regs.len() {
                EMIT["add rsp, " + str(8 * (args.len() - arg_regs.len()))]
            }
            CLEANUP_FUNCTION_CALL[]
        }
    }

    let allocate_on_stack = 8 * (function.stack_occupancy.len() + temp_values_occupancy.len())
    if calc.mod(allocate_on_stack, 16) != 0 {
        allocate_on_stack += 16 - calc.mod(allocate_on_stack, 16)
    }

    code = (
        ASM["push rbp"], 
        ASM["mov rbp, rsp"],
        ASM["sub rsp, " + str(allocate_on_stack)]
    ) + code

    return (code: code, constants: constants)
}

#let compile_x86(functions) = {
    let code = ()
    let constants = (:)

    for function_name, function in functions {
        LABEL[function_name.replace(".", "_")]
        let res = compile_function(function_name, function)
        code += res.code
        constants += res.constants
    }

    let externs = external_function.pairs().map(x => "    extern " + x.at(1) + "\n").join()
    let text_segment = "segment .text\n    global entry\n\n" + externs + code.join("\n") + "\n"
    let data_segment = (
        "segment .data\n" +
        constants.pairs().map(x => x.at(0) + ": " + x.at(1)).join("\n")
    ) + "\n\n"

    return data_segment + text_segment
} 


#{
    import "ir-gen.typ": *
    import "pprint.typ": *
    set page(height: auto)
    
    let ir = ir_from_ast(parse("#let f(/*int*/x, /*int*/y) = x + y; #f(2, 2)"))

    pprint(ir); pagebreak()
    asm_code(compile_x86(ir.functions))
}
