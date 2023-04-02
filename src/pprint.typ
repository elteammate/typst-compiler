#import "reflection-ast.typ": is_ast_node
#import "typesystem.typ": type_to_string

#let pprint(node) = {
  let ty = if is_ast_node(node) {
    "ast"
  } else if type(node) == "dictionary" and "instr" in node {
    "ir_instr"
  } else if type(node) == "dictionary" and "code" in node and "labels" in node {
    "ir"
  } else {
    type(node)
  }
  
  if ty == "ast" {
    [
      #text(blue, raw(node.type))
      #if "ty" in node [#text(red, raw(type_to_string(node.ty)))]
      /* @#pprint_span(node.span) */ #h(1em)
      #pprint(node.fields)
    ]
  } else if ty == "ir_instr" {
    [
      #h(1em) #text(red, raw(node.res)) = 
      #text(weight: "extrabold", raw(node.instr)) #text(red, raw(node.ty))
      #node.args.map(x => text(blue, raw(repr(x)))).join([ ])
    ]
  } else if ty == "ir" {
    let labels = range(node.code.len() + 1).map(x => ())
    for label, pos in node.labels { labels.at(pos).push(label) }
    [ \ ]
    for i, instr in node.code [ 
        #box(align(text(blue, raw(instr.res)), end), width: 5em) = 
        #text(weight: "extrabold", raw(instr.instr)):#text(red, raw(instr.ty))
        #h(1em)
        #instr.args.map(x => [\<#text(blue, raw(repr(x)))\>]).join(h(0.6em)) 
        \
    ]
    [locals: #pprint(node.locals)]
    [params: #pprint(node.params)]
    [slots: #pprint(node.slots)]
  } else if ty in ("dictionary", "array") {
    let items = ()
    for k, v in node {
      items.push([#raw(str(k)): #pprint(v)])
    }
    list(..items)
  } else {
    text(maroon, raw(repr(node)))
  }
}
