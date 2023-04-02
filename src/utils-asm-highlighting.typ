#import "utils.typ": *
#import "lexer.typ": *

#let assembly_token = mk_enum(
  debug: true,
  "reg", "instr", "label", "literal_int", "punc", 
  "literal_string", "space", "unknown", "comment", "ident",
)

// #let instructions = read("utils-asm-instructions.txt").split("\n").map(s => lower(s))

#let asm_lexer = compile_lexer((
  ("(r[abcd]x|rsi|rdi|rsp|rbp|r8|r9|r10|r11|r12|r13|r14|r15)", assembly_token.reg),
  ("(e[abcd]x|esi|edi|esp|ebp|[abcd]x|si|di|sp|bp)", assembly_token.reg),
  ("([abcd][lh])", assembly_token.reg),
  ("(xmm[0-9][a-z]?|xmm1[0-5][a-z]?)", assembly_token.reg),
  ("(st[0-7])", assembly_token.reg),
  ("(rip)", assembly_token.reg),

  ("\\S+:", assembly_token.label),

  ("0?[xbob]?\\d+[dhob]?", assembly_token.literal_int),

  ("\".*?\"", assembly_token.literal_string),
  ("`.*?`", assembly_token.literal_string),
  ("'.*?'", assembly_token.literal_string),

  ("[,\[\]\+\-\*]", assembly_token.punc),

  (";[^\\n]+", assembly_token.comment),

  ("([a-zA-Z0-9]*_[a-zA-Z0-9_]+)", assembly_token.ident),
  ("([a-zA-Z0-9]+)", assembly_token.instr),
  
  ("\\s+", assembly_token.space),

  (".", assembly_token.unknown),
  
), (t, m) => (
  kind: t, 
  text: m.text,
))

#let asm_code(code) = {
  let tokens = asm_lexer(code)
  return block(tokens.map(t => {
    if t.kind == assembly_token.reg {
      text(navy, raw(t.text))
    } else if t.kind == assembly_token.punc {
      text(gray, raw(t.text))
    } else if t.kind == assembly_token.instr {
      text(olive, raw(t.text))
    } else if t.kind == assembly_token.comment {
      text(gray, raw(t.text))
    } else if t.kind == assembly_token.label {
      text(purple, raw(t.text))
    } else if t.kind == assembly_token.literal_int {
      text(orange, raw(t.text))
    } else if t.kind == assembly_token.literal_string {
      text(fuchsia, raw(t.text))
    } else if t.kind == assembly_token.ident {
      text(blue, raw(t.text))
    } else {
      raw(t.text)
    }
  }).join())
}

// #show raw.where(lang: "asm", block: true): it => {
//   asm_code(it.text)
// }

#asm_code("db `aaa` \n LABEL: mov rax, [rbx + 5] ; test")
