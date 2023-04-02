#set list(marker: none)

= TODO

#let resolved = text(green, sym.checkmark)
#let low = text(yellow, sym.circle.filled)
#let med = text(orange, sym.circle.filled)
#let high = text(red, sym.circle.filled)

== Lexer

- #resolved Works ok-ish????

== Lexer Postprocessor

- #med Handle dot call on new line
- #low Handle `else` on new line
- #high Semicolon after function is added to content block after

== Parser

- #med Merge `member_access` and `call` into `method_call`

== Parser Postprocessor

- #low Add more checks to params, too boring though

== Typesystem

- #resolved Rewrite with LALR(1) parser
- #resolved Make function into parametrized type
- #resolved Special type for object
- #low Aliases
- #low Derive alias from constructors
- #high Utils for type comparison

== IR generator

- #resolved Strongly typed function call
- #low Optimize joining with empty content
- #med Implicit arithmetic conversions
- #med Determine call type
- #low Unvirtualize non-closure calls
- #med Capturing values in closure slots
- #med Capturing external functions and values
- #low Sink parameters
- #high lvalues
- #high arrays & tuples
- #low `array` times `int` and others
- #high dicts & objects
- #high A LOT MORE AST NODE TYPES
- #low Reset loop stack when entering the function
- #high Basic control flow graph analisys
- #low Warning in unreachable code
- #low Don't allocate stack variable for `none` typed args

== x86

- #high Reuse parameters on stack as local variables
- #high Replace `mul` with `imul`

== LLVM

Not started
