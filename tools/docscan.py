"""Declaration scanner adapted from vhyl's MIT-licensed documentation builder.

Copyright (c) 2026 John Cunningham. See THIRD_PARTY_NOTICES.md.
Upstream: tashmurra/vhyl at 53dbf3b94bb12f269fc447c414bff09fc0b7e46d.
This scans declarations; it does not validate Zebulon semantics.
"""
from __future__ import annotations
from dataclasses import dataclass, field
import re

@dataclass
class Member:
    name: str
    kind: str
    signature: str
    source: str
    line: int
    description: str = ""
    audience: str = "internal"


@dataclass
class Symbol:
    name: str
    kind: str
    source: str
    line: int
    signature: str
    parent: str = ""
    description: str = ""
    audience: str = "internal"
    members: list[Member] = field(default_factory=list)


def masked(text: str) -> str:
    """Hide strings and comments while retaining offsets and line endings."""
    out = list(text)
    i = 0
    while i < len(text):
        if text.startswith("//", i):
            end = text.find("\n", i)
            end = len(text) if end < 0 else end
        elif text.startswith("/*", i):
            close = text.find("*/", i + 2)
            if close < 0:
                raise ValueError("unterminated block comment")
            end = close + 2
        elif text[i] in "'\"":
            quote = text[i]
            end = i + 1
            while end < len(text):
                if text[end] == "\\":
                    end += 2
                elif text[end] == quote:
                    end += 1
                    break
                else:
                    end += 1
            else:
                raise ValueError("unterminated string")
        else:
            i += 1
            continue
        for j in range(i, min(end, len(text))):
            if text[j] != "\n":
                out[j] = " "
        i = end
    return "".join(out)


def matching(mask: str, start: int, opening: str, closing: str) -> int:
    depth = 0
    for i in range(start, len(mask)):
        if mask[i] == opening:
            depth += 1
        elif mask[i] == closing:
            depth -= 1
            if depth == 0:
                return i + 1
    raise ValueError(f"unclosed {opening} at offset {start}")


def semicolon(mask: str, start: int) -> int:
    brace = bracket = paren = 0
    for i in range(start, len(mask)):
        c = mask[i]
        if c == "{":
            brace += 1
        elif c == "}":
            brace -= 1
        elif c == "[":
            bracket += 1
        elif c == "]":
            bracket -= 1
        elif c == "(":
            paren += 1
        elif c == ")":
            paren -= 1
        elif c == ";" and brace == bracket == paren == 0:
            return i + 1
    raise ValueError(f"declaration without semicolon at offset {start}")


def documentation(text: str, start: int) -> tuple[str, str]:
    """Read an adjacent comment; /** blocks can mark supported APIs."""
    before = text[:start]
    end = before.rfind("*/")
    if end < 0 or before[end + 2:].strip():
        return "", "internal"
    begin = before.rfind("/*", 0, end)
    if begin < 0:
        return "", "internal"
    prefix = 3 if before.startswith("/**", begin) else 2
    lines = [re.sub(r"^\s*\*\s?", "", line).strip() for line in before[begin + prefix:end].splitlines()]
    audience = "internal"
    kept = []
    for line in lines:
        if line.startswith("@api "):
            audience = line[5:].strip()
        elif line:
            kept.append(line)
    return " ".join(kept), audience


def source_line(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def without_comments(fragment: str) -> str:
    """Remove comments from displayed declarations without stripping strings."""
    result = []
    i = 0
    while i < len(fragment):
        if fragment.startswith("/*", i):
            close = fragment.find("*/", i + 2)
            i = len(fragment) if close < 0 else close + 2
            result.append(" ")
        elif fragment.startswith("//", i):
            close = fragment.find("\n", i + 2)
            i = len(fragment) if close < 0 else close
            result.append(" ")
        elif fragment[i] in "'\"":
            quote = fragment[i]
            start = i
            i += 1
            while i < len(fragment):
                if fragment[i] == "\\":
                    i += 2
                elif fragment[i] == quote:
                    i += 1
                    break
                else:
                    i += 1
            result.append(fragment[start:i])
        else:
            result.append(fragment[i])
            i += 1
    return "".join(result)


def members(text: str, mask: str, start: int, end: int, source: str) -> list[Member]:
    found: list[Member] = []
    i = start
    while i < end:
        m = re.search(r"[A-Za-z_]\w*", mask[i:end])
        if not m:
            break
        at = i + m.start()
        name = m.group()
        after = at + len(name)
        while after < end and mask[after].isspace():
            after += 1
        if after >= end:
            break
        kind = ""
        finish = after
        if mask[after] == "(":
            args_end = matching(mask, after, "(", ")")
            body = args_end
            while body < end and mask[body].isspace():
                body += 1
            if body < end and mask[body] == "{":
                finish = matching(mask, body, "{", "}")
                kind = "method"
                signature = re.sub(r"\s+", " ", text[at:args_end]).strip()
        elif mask[after] == "{":
            finish = matching(mask, after, "{", "}")
            kind = "property"
            signature = name + " { ... }"
        elif mask[after] == "=" and (after + 1 >= end or mask[after + 1] != "="):
            kind = "property"
            finish = after + 1
            brace = bracket = paren = 0
            while finish < end:
                c = mask[finish]
                if c == "{":
                    brace += 1
                elif c == "}":
                    brace -= 1
                elif c == "[":
                    bracket += 1
                elif c == "]":
                    bracket -= 1
                elif c == "(":
                    paren += 1
                elif c == ")":
                    paren -= 1
                if brace == bracket == paren == 0 and c.isspace():
                    nxt = re.match(r"\s+([A-Za-z_]\w*)\s*(=|\(|\{)", mask[finish:end])
                    if nxt:
                        next_at = finish + len(nxt.group(0)) - len(nxt.group(0).lstrip())
                        if nxt.group(2) == "(":
                            opening = finish + len(nxt.group(0)) - 1
                            close = matching(mask, opening, "(", ")")
                            next_body = close
                            while next_body < end and mask[next_body].isspace():
                                next_body += 1
                            if next_body < end and mask[next_body] == "{":
                                finish = next_at
                                break
                        else:
                            finish = next_at
                            break
                    if "\n" in mask[finish:finish + 1] and re.match(r"\s*[A-Za-z_]\w*\s*(?:=|\(|\{)", mask[finish:end]):
                        break
                finish += 1
            signature = re.sub(r"\s+", " ", without_comments(text[at:finish])).strip()
            signature = signature.rstrip(";")
        if kind:
            desc, audience = documentation(text, at)
            found.append(Member(name, kind, signature, source, source_line(text, at), desc, audience))
            i = max(finish, after + 1)
        else:
            i = after + 1
    return found


def parse_source(source: str, text: str) -> list[Symbol]:
    mask = masked(text)
    out: list[Symbol] = []
    i = 0
    while i < len(mask):
        while i < len(mask) and mask[i].isspace():
            i += 1
        if i >= len(mask):
            break
        rest = mask[i:]
        m = re.match(r"(class\s+)?([A-Za-z_]\w*)\s*:\s*([A-Za-z_]\w*)", rest)
        mod = re.match(r"modify\s+([A-Za-z_]\w*)\b", rest)
        func = re.match(r"([A-Za-z_]\w*)\s*\(", rest)
        direct = re.match(r"(relation|enum|property|dictionary|grammar)\b", rest)
        template = re.match(r"[A-Za-z_]\w*\s+template\b", rest)
        define = re.match(r"#(?:define|include|if|endif|else)\b", rest)
        plus = re.match(r"\+\s*property\b", rest)
        if m or mod:
            header = m or mod
            finish = semicolon(mask, i)
            name = m.group(2) if m else mod.group(1)
            kind = "class" if m and m.group(1) else "object" if m else "modify"
            parent = m.group(3) if m else ""
            body_start = i + header.end()
            desc, audience = documentation(text, i)
            signature = re.sub(r"\s+", " ", text[i:body_start]).strip()
            sym = Symbol(name, kind, source, source_line(text, i), signature, parent, desc, audience)
            sym.members = members(text, mask, body_start, finish - 1, source)
            out.append(sym)
            i = finish
        elif func:
            args = i + func.end() - 1
            args_end = matching(mask, args, "(", ")")
            body = args_end
            while body < len(mask) and mask[body].isspace():
                body += 1
            if body < len(mask) and mask[body] == "{":
                finish = matching(mask, body, "{", "}")
                desc, audience = documentation(text, i)
                out.append(Symbol(func.group(1), "function", source, source_line(text, i),
                                  re.sub(r"\s+", " ", text[i:args_end]).strip(),
                                  description=desc, audience=audience))
                i = finish
            else:
                i = args_end
        elif direct or template or define or plus:
            kind = "template" if template else "macro" if define else "property" if plus else direct.group(1)
            finish = mask.find("\n", i) if define else semicolon(mask, i)
            if finish < 0:
                finish = len(mask)
            signature = re.sub(r"\s+", " ", text[i:finish]).strip().rstrip(";")
            if kind == "grammar":
                name_match = re.match(r"grammar\s+(\w+)\s*\(\s*(\w+)\s*\)", signature)
                name = f"{name_match.group(1)}({name_match.group(2)})" if name_match else signature[:50]
            elif kind == "template":
                name = signature.split()[0]
            elif kind == "macro":
                name_match = re.match(r"#\w+\s+(\w+)", signature)
                name = name_match.group(1) if name_match else signature
            else:
                name_match = re.match(r"\+?\s*\w+\s+(\w+)", signature)
                name = name_match.group(1) if name_match else signature
            desc, audience = documentation(text, i)
            out.append(Symbol(name, kind, source, source_line(text, i), signature,
                              description=desc, audience=audience))
            i = finish
        else:
            snippet = text[i:i + 70].splitlines()[0]
            raise ValueError(f"unrecognised declaration in {source}:{source_line(text, i)}: {snippet}")
    return out
