#import "reflection-lexer.typ": *
#import "reflection-parser.typ": *

#let tokens = typst_lex("
#let x = x.x()
aboba")

#tokens.map(x => [#x]).join([ \ ])
\ \
// #pprint_ast(typst_parse(tokens))

// #"abacaba".slice(2, -2)
