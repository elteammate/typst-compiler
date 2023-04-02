#import "utils.typ": *
#import "lexer.typ": *

#let typst_token_kind = mk_enum(
  debug: true,
  "ident",
  "kw_let",
  "kw_set",
  "kw_show",
  "kw_if",
  "kw_else",
  "kw_for",
  "kw_while",
  "kw_break",
  "kw_continue",
  "kw_return",
  "kw_include",
  "kw_import",
  "kw_from",
  "kw_in",
  "kw_not",
  "kw_and",
  "kw_or",
  "punc_minus",
  "punc_plus",
  "punc_star",
  "punc_slash",
  "punc_dot",
  "punc_dotdot",
  "punc_eq",
  "punc_pluseq",
  "punc_minuseq",
  "punc_stareq",
  "punc_slasheq",
  "punc_eqeq",
  "punc_neq",
  "punc_lt",
  "punc_gt",
  "punc_le",
  "punc_ge",
  "punc_lparen",
  "punc_rparen",
  "punc_lbracket",
  "punc_rbracket",
  "punc_lbrace",
  "punc_rbrace",
  "punc_hash",
  "punc_comma",
  "punc_colon",
  "punc_arrow",
  "punc_semi",
  "punc_dollar",
  "literal_int",
  "literal_float",
  "literal_string",
  "literal_bool",
  "literal_none",
  "hspace",
  "vspace",
  "comment_line",
  "comment_block",
  "comment_doc",
  "comment_doc_outer",
  "type_cast",
  "unknown",
  "workaround_call_glue_parens",
  "workaround_call_glue_brackets",
)

#let typst_keyword_mapping = (
  "let": typst_token_kind.kw_let,
  "set": typst_token_kind.kw_set,
  "show": typst_token_kind.kw_show,
  "if": typst_token_kind.kw_if,
  "else": typst_token_kind.kw_else,
  "for": typst_token_kind.kw_for,
  "while": typst_token_kind.kw_while,
  "break": typst_token_kind.kw_break,
  "continue": typst_token_kind.kw_continue,
  "include": typst_token_kind.kw_include,
  "return": typst_token_kind.kw_return,
  "import": typst_token_kind.kw_import,
  "from": typst_token_kind.kw_from,
  "in": typst_token_kind.kw_in,
  "not": typst_token_kind.kw_not,
  "and": typst_token_kind.kw_and,
  "or": typst_token_kind.kw_or,

  "true": typst_token_kind.literal_bool,
  "false": typst_token_kind.literal_bool,
  "none": typst_token_kind.literal_none,
)

#let typst_lexer = (
  ("[\pL_][\pL\pN_\-]*", (m) => {
    if m.text in typst_keyword_mapping {
      typst_keyword_mapping.at(m.text)
    } else {
      typst_token_kind.ident
    }
  }),
  ("([0-9]*\.[0-9]+|[0-9]+\.[0-9]*|[0-9]+)[eE][\+\-]?[0-9]+", typst_token_kind.literal_float),
  ("([0-9]*\.[0-9]+|[0-9]+\.[0-9]*)", typst_token_kind.literal_float),
  ("[0-9]+", typst_token_kind.literal_int),
  ("\"([^\\\\\"]|\\\\.)*\"", typst_token_kind.literal_string),
  ("[^\S\n]+", typst_token_kind.hspace),
  ("\s*\n\s*", typst_token_kind.vspace),
  ("/\\*[a-zA-Z0-9_\-<>]+\\*/", typst_token_kind.type_cast),
  ("/// [^\n]*", typst_token_kind.comment_doc),
  ("//% [^\n]*", typst_token_kind.comment_doc_outer),
  ("//[^\n]*", typst_token_kind.comment_line),
  ("/\\*.+?\\*/", typst_token_kind.comment_block),
  
  
  ("#", typst_token_kind.punc_hash),
  ("\$", typst_token_kind.punc_dollar),
  (":", typst_token_kind.punc_colon),
  (";", typst_token_kind.punc_semi),
  ("\.\.", typst_token_kind.punc_dotdot),
  ("\.", typst_token_kind.punc_dot),
  (",", typst_token_kind.punc_comma),
  ("\{", typst_token_kind.punc_lbrace),
  ("\}", typst_token_kind.punc_rbrace),
  ("\[", typst_token_kind.punc_lbracket),
  ("\]", typst_token_kind.punc_rbracket),
  ("\(", typst_token_kind.punc_lparen),
  ("\)", typst_token_kind.punc_rparen),

  ("\+=", typst_token_kind.punc_pluseq),
  ("\+", typst_token_kind.punc_plus),
  ("\-=", typst_token_kind.punc_minuseq),
  ("\-", typst_token_kind.punc_minus),
  ("\*=", typst_token_kind.punc_stareq),
  ("\*", typst_token_kind.punc_star),
  ("/=", typst_token_kind.punc_slasheq),
  ("/", typst_token_kind.punc_slash),
  ("=>", typst_token_kind.punc_arrow),
  ("==", typst_token_kind.punc_eqeq),
  ("!=", typst_token_kind.punc_neq),
  ("<=", typst_token_kind.punc_le),
  (">=", typst_token_kind.punc_ge),
  ("<", typst_token_kind.punc_lt),
  (">", typst_token_kind.punc_gt),
  ("=", typst_token_kind.punc_eq),
  
  (".", typst_token_kind.unknown),
)

#let postprocess_lexed(tokens) = {
  let context = mk_enum(
    "content",
    "code_hash",
    "code_hash_stmt",
    "code_line",
    "code_multiline",
  )
  
  let context_stack = (context.content, )
  let current_context = context.content
  let result = ()
  tokens.push((kind: typst_token_kind.punc_rbracket))
  for i, token in tokens {
    if current_context == context.code_hash_stmt {
      if token.kind in (
        typst_token_kind.vspace,
        typst_token_kind.comment_line,
        typst_token_kind.punc_semi,
        typst_token_kind.punc_rbracket,
      ) {
        current_context = context_stack.pop()
      }
    }
    
    if current_context == context.code_hash {
      if token.kind in (
        typst_token_kind.vspace,
        typst_token_kind.comment_line,
        typst_token_kind.punc_semi,
        typst_token_kind.punc_rbracket,
        typst_token_kind.hspace,
        typst_token_kind.comment_block,
        typst_token_kind.punc_rparen,
        typst_token_kind.punc_rbracket,
        typst_token_kind.punc_rbrace,
        typst_token_kind.punc_colon,
      ) {
        result.push((kind: typst_token_kind.punc_semi))
        current_context = context_stack.pop()
        assert(current_context == context.content, message: "Unreachable?")
      }

      if token.kind in (
        typst_token_kind.kw_let,
        typst_token_kind.kw_set,
        typst_token_kind.kw_show,
        typst_token_kind.kw_if,
        typst_token_kind.kw_for,
        typst_token_kind.kw_while,
        typst_token_kind.kw_break,
        typst_token_kind.kw_continue,
        typst_token_kind.kw_include,
        typst_token_kind.kw_return,
        typst_token_kind.kw_import,
      ) {
        context_stack.push(current_context)
        current_context = context.code_hash_stmt
      }
    }
    
    if current_context == context.content {
      if token.kind == typst_token_kind.punc_hash {
        context_stack.push(current_context)
        current_context = context.code_hash
      } else if token.kind not in (
        typst_token_kind.punc_lbracket,
        typst_token_kind.punc_rbracket
      ) {
        if result.len() > 0 and result.last().kind == typst_token_kind.unknown {
          result.last().text += token.text
        } else {
          result.push((kind: typst_token_kind.unknown, text: token.text))
        }
        continue
      }
    } else if current_context == context.code_line {
      if token.kind in (typst_token_kind.hspace, typst_token_kind.comment_block) {
        continue
      } else if token.kind in (typst_token_kind.vspace, typst_token_kind.comment_line) {
        result.push((kind: typst_token_kind.punc_semi))
        continue
      }
    } else {
      if token.kind in (
        typst_token_kind.hspace,
        typst_token_kind.comment_block,
        typst_token_kind.vspace,
        typst_token_kind.comment_line
      ) {
        continue
      }
    }

    if token.kind == typst_token_kind.punc_lparen and current_context != context.content {
      if i > 0 and tokens.at(i - 1).kind in (
        typst_token_kind.ident,
        typst_token_kind.punc_rparen,
        typst_token_kind.punc_rbracket,
        typst_token_kind.punc_rbrace,
      ) {
        result.push((kind: typst_token_kind.workaround_call_glue_parens))
      }
      
      context_stack.push(current_context)
      current_context = context.code_multiline
    } else if token.kind == typst_token_kind.punc_rparen and current_context != context.content {
      assert(current_context == context.code_multiline, message: "Unmatched parenthesis at: " + str(i))
      current_context = context_stack.pop()
    } else if token.kind == typst_token_kind.punc_lbracket {
      if i > 0 and tokens.at(i - 1).kind in (
        typst_token_kind.ident,
        typst_token_kind.punc_rparen,
      ) {
        result.push((kind: typst_token_kind.workaround_call_glue_brackets))
      }
      context_stack.push(current_context)
      current_context = context.content
    } else if token.kind == typst_token_kind.punc_rbracket {
      assert(current_context == context.content, message: "Unmatched bracket")
      current_context = context_stack.pop()
    } else if token.kind == typst_token_kind.punc_lbrace and current_context != context.content {
      context_stack.push(current_context)
      current_context = context.code_line
    } else if token.kind == typst_token_kind.punc_rbrace and current_context != context.content {
      assert(current_context == context.code_line, message: "Unmatched brace")
      result.push((kind: typst_token_kind.punc_semi))
      current_context = context_stack.pop()
    }

    result.push(token)
  }

  assert(context_stack.len() == 0, message: "Unclosed something")
  result.pop()
  return result
}

#let typst_lex_raw = compile_lexer(typst_lexer, (t, m) => (
  kind: t, 
  text: m.text,
  // span: span(m.start, m.end)
))

#let typst_lex(source) = postprocess_lexed(typst_lex_raw(source))

#let lex_file(filename) = {
  // typst_lex(read(filename)).map(token => {
    // token.span.file = filename
    // token
  // })
  typst_lex(read(filename))
}

// #{
//   typst_lex("#{x + (1 +\n 1)}      [23] #{\nx\n\n} test").map(x => [#x]).join([ \ ])
// }
// #lex_file("reflection-lexer.typ").map(x => [#x]).join([ \ ])
