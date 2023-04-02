#import "utils.typ": *
#import "typesystem-def.typ": *
#import "lexer.typ": *

#let ts_token_kind = mk_enum(
  debug: true,
  "ident",
  "alias",
  "ty_none_",
  "ty_content",
  "ty_string",
  "ty_float",
  "ty_int",
  "ty_any",
  "ty_bool",
  "ty_arguments",
  "ty_dictionary",
  "ty_function",
  "ty_array",
  "ty_tuple",
  "ty_object",
  "punc_comma",
  "punc_lt",
  "punc_gt",
  "punc_colon",
)

#let ts_keyword_mapping = (
  "none": ts_token_kind.ty_none_,
  "content": ts_token_kind.ty_content,
  "string": ts_token_kind.ty_string,
  "float": ts_token_kind.ty_float,
  "int": ts_token_kind.ty_int,
  "dictionary": ts_token_kind.ty_dictionary,
  "function": ts_token_kind.ty_function,
  "array": ts_token_kind.ty_array,
  "tuple": ts_token_kind.ty_tuple,
  "object": ts_token_kind.ty_object,
  "any": ts_token_kind.ty_any,
  "bool": ts_token_kind.ty_bool,
  "arguments": ts_token_kind.ty_arguments,
)

#let ts_lexer = (
  ("\$[A-Za-z0-9\-_\*]+", ts_token_kind.alias),
  ("[A-Za-z0-9\-_\*]+", m => {
    if m.text in ts_keyword_mapping {
      ts_keyword_mapping.at(m.text)
    } else {
      ts_token_kind.ident
    }
  }),
  (",", ts_token_kind.punc_comma),
  ("<", ts_token_kind.punc_lt),
  (">", ts_token_kind.punc_gt),
  (":", ts_token_kind.punc_colon),
)

#let ts_lex = compile_lexer(ts_lexer, (t, m) => (
  kind: t, 
  text: m.text,
))
