import pyperclip
import re


def read_macros(source):
    lines = source.split("\n")
    line_no = 0
    macros = {}
    while line_no < len(lines):
        line = lines[line_no]
        if line.startswith("//#define"):
            _, name, *params = line.split(" ")
            body = ""
            while True:
                line_no += 1
                line = lines[line_no]
                if not line.startswith("//#"):
                    break
                if line.endswith("!"):
                    body += line[3:-1].lstrip()
                else:
                    body += line[3:].lstrip() + "\n"
            macros[name] = (params, body)
        else:
            line_no += 1
    return macros


def replace_macros(source, macros):
    source = "\n".join(line for line in source.splitlines() if not line.startswith("//"))

    while True:
        changed = False
        for macro_name, (params, body) in macros.items():
            regex = re.compile(rf"((?<![a-zA-Z0-9_]){macro_name})\[(([^\]\"]|\".*?\")*?)\]", re.MULTILINE | re.DOTALL)
            while match := regex.search(source):
                changed = True
                _, args, _ = match.groups()
                args = args.split(";")
                args = [arg.strip() for arg in args]
                new_body = body
                for param, arg in zip(params, args):
                    new_body = new_body.replace(param, arg)
                source = source[:match.start()] + new_body + source[match.end():]
        if not changed:
            break

    return source


with open("typst-preprocessor/compile-x86.typ") as file:
# with open("typst-preprocessor/ir-gen.typ") as file:
    source = file.read()

macros = read_macros(source)
source = replace_macros(source, macros)
print(source)
pyperclip.copy(source)
