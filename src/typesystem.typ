#import "typesystem-def.typ": *
#import "typesystem-lexer.typ": *
#import "typesystem-parser.typ": *


#let type_from_string(str) = typesystem_parse(ts_lex(str))

// #type_from_string("tuple<content,none,float,tuple<int,any>,array<int>,dictionary<int>,function<int,int>,tuple<>,object<any:any>>")

#let type_to_string(ty) = {
  let type_to_string_no_flags(ty) = {
    let t = ty.at(0)
    if t == ptype.none_ {
      return "none"
    } else if t == ptype.content {
      return "content"
    } else if t == ptype.bool {
      return "bool"
    } else if t == ptype.string {
      return "string"
    } else if t == ptype.float {
      return "float"
    } else if t == ptype.any {
      return "any"
    } else if t == ptype.int {
      return "int"
    } else if t == ptype.arguments {
      return "arguments"
    } else if t == ptype.dictionary {
      return "dictionary<" + type_to_string(ty.at(1).at(0)) + ">"
    } else if t == ptype.array {
      return "array<" + type_to_string(ty.at(1).at(0)) + ">"
    } else if t == ptype.tuple {
      return "tuple<" + ty.at(1).map(t => type_to_string(t)).join(",") + ">"
    } else if t == ptype.function {
      return (
        "function<" + 
        type_to_string(ty.at(1).at(0)) + "," + 
        ty.at(1).slice(1).map(t => type_to_string(t)).join(",") + ">"
      )
    } else if t == ptype.object {
      return (
        "object<" + ty.at(1).map(t => t.name + ":" + type_to_string(t.ty)).join(",") + ">"
      )
    }
    panic("unreachable, " + repr(ty)) 
  }

  let ty_no_flags = type_to_string_no_flags(ty)
  if ty.at(2).len() > 0 {
    return (
      ty_no_flags + "[" + 
      ty.at(2).pairs().filter(x => x.at(1)).map(x => x.at(0)).join(",") + 
      "]")
  } else {
    return ty_no_flags
  }
}
