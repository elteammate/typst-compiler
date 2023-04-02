#import "reflection-parser.typ": typst_parse, typst_lex, lex_file

#let parse(source) = typst_parse(typst_lex(source))
#let parse_file(filename) = parse(open(filename))
