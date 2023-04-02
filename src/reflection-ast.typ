#import "utils.typ": *

#let ast_node_type = mk_enum(
  debug: true,
  "paren",
  "ident",
  "unknown",
  
  "member_access",
  "call",
  "call_param_list",

  "content",
  "hash_expr",
  "stmt",
  "code_block",
  "content_block",

  "let_",
  "if_",
  "else_",
  "while_",
  "for_",
  "continue_",
  "break_",
  "return_",
  "set_",
  "show_",
  "import_",
  
  "param_list",
  "sink",

  "unary_plus",
  "unary_minus",
  "unary_not",
  
  "binary_add",
  "binary_sub",
  "binary_mul",
  "binary_div",
  "binary_eq",
  "binary_ne",
  "binary_lt",
  "binary_gt",
  "binary_le",
  "binary_ge",
  "binary_in",
  "binary_not_in",
  "binary_and",
  "binary_or",
  
  "type_cast",

  "assign",
  "add_assign",
  "sub_assign",
  "mul_assign",
  "div_assign",
  
  "literal_int",
  "literal_float",
  "literal_string",
  "literal_bool",
  "literal_none",
  "suffixed",
  "array",
  "dict",
  "lambda",
)

#let mk_node(type, span: none, ..fields) = {
  assert(fields.pos().len() == 0, message: "AST requires node parameters to be named")

  (
    type: type,
    fields: fields.named(),
    span: span,
  )
}

#let is_ast_node(obj) = type(obj) == "dictionary" and "type" in obj and "fields" in obj

#let pprint_ast_old(ast) = [
  #text(blue, raw(ast.type)) // @ #pprint_span(ast.span)
  #list(
    ..ast.fields.pairs().map(item => {
      let key = item.at(0)
      let value = item.at(1)
      let ty = if is_ast_node(value) {
        "ast"
      } else {
        type(value)
      }
      [#raw(key);(#raw(ty))#sym.space.quad]
      if ty == "ast" {
        pprint_ast(value)
      } else if ty in ("dictionary", "array") {
        let items = ()
        for k, v in value {
          if is_ast_node(v) {
            items.push([#raw(k): #pprint_ast(v)])
          } else {
            items.push([#raw(k): #repr(v)])
          }
        }
        list(..items)
      } else {
        text(maroon, [#repr(value)])
      }
    })
  )
]

#let fix_paren_value(parenthesised) = {
  if parenthesised.dict_flag {
    return mk_node(
      ast_node_type.dict,
      elements: parenthesised.elements,
    )
  }
    
  if parenthesised.elements.len() == 0 {
    return mk_node(
      ast_node_type.array,
      elements: (),
    )
  } else if parenthesised.elements.len() == 1 {
    if parenthesised.elements.at(0).sink {
      return mk_node(
        ast_node_type.array,
        elements: parenthesised.elements,
      )
    } else if parenthesised.elements.at(0).key != none {
      return mk_node(
        ast_node_type.dict,
        elements: parenthesised.elements,
      )
    } else if parenthesised.trailing_comma {
      return mk_node(
        ast_node_type.array,
        elements: parenthesised.elements,
      )
    } else {
      return mk_node(
        ast_node_type.paren,
        expr: parenthesised.elements.at(0).value,
      )
    }
  } else {
    if parenthesised.elements.all(x => x.key == none) {
      return mk_node(
        ast_node_type.array,
        elements: parenthesised.elements,
      )
    } else if parenthesised.elements.all(x => x.sink or x.key != none) {
      return mk_node(
        ast_node_type.dict,
        elements: parenthesised.elements,
      )
    } else {
      panic("Bad parenthesised literal")
    }
  }
}

#let fix_paren_call(parenthesised) = {
  parenthesised.elements
}

#let fix_paren_params(parenthesised) = {
  parenthesised.elements
}
