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
            let _ = { let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
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
            code.push(((label).replace("%", "_P_").replace("@", "_A_").replace(".", "_")) + ":")
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
                let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
                code.push(("    " + "mov " + reg + ", " + location))
                locations.insert(res, reg)
                values_in_registers.insert(reg, res)
            }
        
        
        } else if opcode == ir_instruction.store_fast {
            let reg = ({
let val = args.at(1)
if is_register(locations.at(val)) {
let reg = locations.at(val)
if last_use.at(val) == line {
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
reg
} else {
let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
if last_use.at(val) != line {
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
}
})
            code.push(("    " + "mov " + ({
let location = function.locals.at(args.at(0)).stack_pos
"[rbp - " + str(location * 8 + 8) + "]"
})) + ", " + reg)
        
        
        } else if opcode == ir_instruction.load {
            let reg = ({
let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
({
locations.insert(res, reg)
values_in_registers.insert(reg, res)
if reg not in allocated_num_registers {
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
reg
})
})
            let location = function.locals.at(args.at(0)).stack_pos
            code.push(("    " + "mov " + reg + ", " + ({
let location = function.locals.at(args.at(0)).stack_pos
"[rbp - " + str(location * 8 + 8) + "]"
})))


        } else if opcode == ir_instruction.const {
            if ty == ptype.int {
                let reg = ({
let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
({
locations.insert(res, reg)
values_in_registers.insert(reg, res)
if reg not in allocated_num_registers {
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
reg
})
})
                code.push(("    " + "mov " + reg + ", " + args.at(0)))
            } else if ty == ptype.content {
                let reg = ({
let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
({
locations.insert(res, reg)
values_in_registers.insert(reg, res)
if reg not in allocated_num_registers {
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
reg
})
})
                let name = ({
let c = args.at(0)
let name = (("%%const_" + str(constant_counter) + "_" + function_name).replace("%", "_P_").replace("@", "_A_").replace(".", "_"))
constants.insert(name, "db `" + c.replace("\n", "\\n") + "`, 0")
constant_counter = constant_counter + 1
name
})
                code.push(("    " + "mov " + reg + ", " + name))
            }



        } else if opcode == ir_instruction.add {
            if ty == ptype.int {
let reg1 = ({
let val = args.at(0)
if is_register(locations.at(val)) {
let reg = locations.at(val)
if last_use.at(val) == line {
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
reg
} else {
let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
if last_use.at(val) != line {
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
}
})
let reg2 = ({
let val = args.at(1)
if is_register(locations.at(val)) {
let reg = locations.at(val)
if last_use.at(val) == line {
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
reg
} else {
let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
if last_use.at(val) != line {
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
}
})
if last_use.at(args.at(0)) == line {
({
locations.insert(res, reg1)
values_in_registers.insert(reg1, res)
if reg1 not in allocated_num_registers {
let _ = { let r = reg1; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
reg1
})
code.push(("    " + "add " + reg1 + ", " + reg2))
} else {
let reg = ({
let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
({
locations.insert(res, reg)
values_in_registers.insert(reg, res)
if reg not in allocated_num_registers {
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
reg
})
})
code.push(("    " + "mov " + reg + ", " + reg1))
code.push(("    " + "add " + reg + ", " + reg2))
}
}

        } else if opcode == ir_instruction.sub {
            if ty == ptype.int {
let reg1 = ({
let val = args.at(0)
if is_register(locations.at(val)) {
let reg = locations.at(val)
if last_use.at(val) == line {
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
reg
} else {
let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
if last_use.at(val) != line {
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
}
})
let reg2 = ({
let val = args.at(1)
if is_register(locations.at(val)) {
let reg = locations.at(val)
if last_use.at(val) == line {
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
reg
} else {
let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
if last_use.at(val) != line {
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
}
})
if last_use.at(args.at(0)) == line {
({
locations.insert(res, reg1)
values_in_registers.insert(reg1, res)
if reg1 not in allocated_num_registers {
let _ = { let r = reg1; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
reg1
})
code.push(("    " + "sub " + reg1 + ", " + reg2))
} else {
let reg = ({
let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
({
locations.insert(res, reg)
values_in_registers.insert(reg, res)
if reg not in allocated_num_registers {
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
reg
})
})
code.push(("    " + "mov " + reg + ", " + reg1))
code.push(("    " + "sub " + reg + ", " + reg2))
}
}

        } else if opcode == ir_instruction.mul {
            if ty == ptype.int {
                if "rdx" in allocated_num_registers { ({
let reg = "rdx"
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
}) }
                if "rcx" in allocated_num_registers { ({
let reg = "rcx"
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
}) }
                ({
let val = args.at(1)
let reg = "rcx"
if locations.at(val) != reg {
if is_register(locations.at(val)) {
let _ = { let r = locations.at(val); let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
})
                if "rax" in allocated_num_registers { ({
let reg = "rax"
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
}) }
                ({
let val = args.at(0)
let reg = "rax"
if locations.at(val) != reg {
if is_register(locations.at(val)) {
let _ = { let r = locations.at(val); let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
})
                if last_use.at(args.at(0)) == line {
                    ({
locations.insert(res, "rax")
values_in_registers.insert("rax", res)
if "rax" not in allocated_num_registers {
let _ = { let r = "rax"; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
"rax"
})
                    code.push(("    " + "mul rcx"))
                }
            }


        } else if opcode == ir_instruction.return_ {
            if ty != ptype.none_ {
                let reg = ({
let val = args.at(0)
if is_register(locations.at(val)) {
let reg = locations.at(val)
if last_use.at(val) == line {
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
reg
} else {
let reg = ({
if free_num_registers.len() > 0 {
{ let r = free_num_registers.first(); let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
} else {
let reg = ({
let reg = allocated_num_registers.first()
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
{ let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
})
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
if last_use.at(val) != line {
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
}
})
                code.push(("    " + "mov rax, " + reg))
            } else {
                code.push(("    " + "xor rax, rax"))
            }
            code.push(("    " + "mov rsp, rbp"))
            code.push(("    " + "pop rbp"))
            code.push(("    " + "ret"))
        
        
        } else if opcode == ir_instruction.join {
            if ty == ptype.content {
                ({
for reg in allocated_num_registers {
if reg in ("rax", "rdi", "rsi", "rdx", "rcx", "r8", "r9") {
({
let reg = reg
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
}
}
code.push(("    " + "xor rax, rax"))
})

                ({
let val = args.at(0)
let reg = "rdi"
if locations.at(val) != reg {
if is_register(locations.at(val)) {
let _ = { let r = locations.at(val); let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
})
                ({
let val = args.at(1)
let reg = "rsi"
if locations.at(val) != reg {
if is_register(locations.at(val)) {
let _ = { let r = locations.at(val); let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
})
                code.push(("    " + "call " + external_function.content_join))
                ({
locations.insert(res, "rax")
values_in_registers.insert("rax", res)
if "rax" not in allocated_num_registers {
let _ = { let r = "rax"; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
"rax"
})
                ({
for reg in allocated_num_registers {
if reg in ("rdi", "rsi", "rdx", "rcx", "r8", "r9") {
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
}
})

            }


        } else if opcode == ir_instruction.cast {
            if ty == ptype.content {
                ({
for reg in allocated_num_registers {
if reg in ("rax", "rdi", "rsi", "rdx", "rcx", "r8", "r9") {
({
let reg = reg
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
}
}
code.push(("    " + "xor rax, rax"))
})

                ({
let val = args.at(0)
let reg = "rdi"
if locations.at(val) != reg {
if is_register(locations.at(val)) {
let _ = { let r = locations.at(val); let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
})
                code.push(("    " + "call " + external_function.cast_int_to_content))
                ({
locations.insert(res, "rax")
values_in_registers.insert("rax", res)
if "rax" not in allocated_num_registers {
let _ = { let r = "rax"; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
"rax"
})
                ({
for reg in allocated_num_registers {
if reg in ("rdi", "rsi", "rdx", "rcx", "r8", "r9") {
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
}
})

            }


        } else if opcode == ir_instruction.mk_function {
            ({
for reg in allocated_num_registers {
if reg in ("rax", "rdi", "rsi", "rdx", "rcx", "r8", "r9") {
({
let reg = reg
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
}
}
code.push(("    " + "xor rax, rax"))
})

            let escaped_label = ((args.at(0)).replace("%", "_P_").replace("@", "_A_").replace(".", "_"))
            code.push(("    " + "mov rdi, " + escaped_label))
            code.push(("    " + "mov rsi, " + str(args.at(1))))
            code.push(("    " + "call " + external_function.mk_function))
            ({
locations.insert(res, "rax")
values_in_registers.insert("rax", res)
if "rax" not in allocated_num_registers {
let _ = { let r = "rax"; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
"rax"
})
            ({
for reg in allocated_num_registers {
if reg in ("rdi", "rsi", "rdx", "rcx", "r8", "r9") {
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
}
})

    

        } else if opcode == ir_instruction.call_fast {
            ({
let reg = "rbx"
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
            ({
for reg in allocated_num_registers {
if reg in ("rax", "rdi", "rsi", "rdx", "rcx", "r8", "r9") {
({
let reg = reg
let pos = temp_values_occupancy.position(x => not x)
if pos == none {
pos = temp_values_occupancy.len()
temp_values_occupancy.push(true)
} else {
temp_values_occupancy.at(pos) = true
}
code.push(("    " + "mov [rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "], " + reg))
let val = values_in_registers.at(reg)
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
locations.insert(val, "[rbp - " + {str(temp_var_offset + 8 * pos + 8)} + "]")
reg
})
}
}
code.push(("    " + "xor rax, rax"))
})

            let arg_regs = ("rdi", "rsi", "rdx", "rcx", "r8", "r9")
            for arg_no, arg in args.slice(1, calc.min(args.len(), arg_regs.len() + 1)) {
                ({
let val = arg
let reg = arg_regs.at(arg_no)
if locations.at(val) != reg {
if is_register(locations.at(val)) {
let _ = { let r = locations.at(val); let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
})            
            }
            if args.len() > arg_regs.len() + 1 {
                for arg in args.slice(arg_regs.len() + 1).rev() {
                    ({
let val = arg
let reg = "rbx"
if locations.at(val) != reg {
if is_register(locations.at(val)) {
let _ = { let r = locations.at(val); let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
})
                    code.push(("    " + "push rbx"))
                    { let r = "rbx"; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
                    locations.remove(arg)
                    values_in_registers.remove("rbx")
                }
            }
            ({
let val = args.at(0)
let reg = "rbx"
if locations.at(val) != reg {
if is_register(locations.at(val)) {
let _ = { let r = locations.at(val); let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
code.push(("    " + "mov " + reg + ", " + locations.at(val)))
let _ = { let r = reg; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
locations.insert(val, reg)
values_in_registers.insert(reg, val)
}
reg
})
            code.push(("    " + "mov rbx, [rbx]"))
            code.push(("    " + "call rbx"))
            ({
locations.insert(res, "rax")
values_in_registers.insert("rax", res)
if "rax" not in allocated_num_registers {
let _ = { let r = "rax"; let _ = free_num_registers.remove(free_num_registers.position(x => x == r));
allocated_num_registers.push(r); r }
}
"rax"
})
            if args.len() > arg_regs.len() {
                code.push(("    " + "add rsp, " + str(8 * (args.len() - arg_regs.len()))))
            }
            ({
for reg in allocated_num_registers {
if reg in ("rdi", "rsi", "rdx", "rcx", "r8", "r9") {
let _ = { let r = reg; let _ = allocated_num_registers.remove(allocated_num_registers.position(x => x == r));
free_num_registers.push(r); r }
}
}
})

        }
    }

    let allocate_on_stack = 8 * (function.stack_occupancy.len() + temp_values_occupancy.len())
    if calc.mod(allocate_on_stack, 16) != 0 {
        allocate_on_stack += 16 - calc.mod(allocate_on_stack, 16)
    }

    code = (
        ("    " + "push rbp"), 
        ("    " + "mov rbp, rsp"),
        ("    " + "sub rsp, " + str(allocate_on_stack))
    ) + code

    return (code: code, constants: constants)
}

#let compile_x86(functions) = {
    let code = ()
    let constants = (:)

    for function_name, function in functions {
        code.push(((function_name.replace(".", "_")).replace("%", "_P_").replace("@", "_A_").replace(".", "_")) + ":")
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
    
    let ir = ir_from_ast(parse("#let f(/*int*/x, /*int*/y) = x + y

#f(2, 2)
"))

    pprint(ir)
    asm_code(compile_x86(ir.functions))
    
}