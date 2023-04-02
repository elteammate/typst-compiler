#import "reflection-lexer.typ": *
#import "reflection-parser.typ": *
#import "pprint.typ": *

#let tokens = lex_file("test2.typ")
// #for i, x in tokens {
//   [ #i: #x \ ]  
// }

// #postprocess_lexed(tokens)
#pprint(typst_parse(tokens))
