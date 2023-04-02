#import "utils.typ": *

#let ptype = mk_enum(
    debug: true,
    "none_",
    "content",
    "string",
    "float",
    "int",
    "any",
    "bool",
    "arguments",
    "dictionary",
    "function",
    "array",
    "tuple",
    "object",
)

#let mk_type(base, ..args) = (base, args.pos(), args.named())

#let types = (
    none_: mk_type(ptype.none_),
    content: mk_type(ptype.content),
    string: mk_type(ptype.string),
    float: mk_type(ptype.float),
    int: mk_type(ptype.int),
    empty_tuple: mk_type(ptype.tuple),
    any: mk_type(ptype.any),
    bool: mk_type(ptype.bool),
)

#let type_of_join(ty1, ty2) = if ty1.at(0) == ptype.none_ {
    ty2
} else if ty2.at(0) == ptype.none_ {
    ty1
} else if ty1 == ty2 and ty1.at(0) in (
    ptype.content, 
    ptype.string,
    ptype.dictionary,
    ptype.array,
) {
    ty1
} else if ty1.at(0) == ptype.tuple and ty2.at(0) == ptype.tuple {
    mk_type(ptype.tuple, ..ty1.slice(1), .. ty2.slice(1))
} else {
    none
}
