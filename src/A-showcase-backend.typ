#{
    import "ir-gen.typ": *
    import "pprint.typ": *
    import "utils-asm-highlighting.typ": *
    import "compile-x86.typ": *
    
    let ir = ir_from_ast(parse(read("A-showcase.typ")))

    // pprint(ir)
    page(
      columns: 2,
      height: 23.5cm,
      asm_code(compile_x86(ir.functions))
    )
}
