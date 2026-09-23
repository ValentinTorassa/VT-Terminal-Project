#!/usr/bin/env python3
"""Validate the Zed config files as the JSONC Zed reads.

Zed parses settings.json and keymap.json leniently: // and /* */ comments and
trailing commas are allowed. This checker accepts exactly that on top of strict
JSON and fails on anything else, plus on duplicate keys (which a JSON parser
silently resolves to the last one - a keybinding or setting that quietly loses)
and on a root of the wrong shape (settings is an object, a keymap an array).
It does not know Zed's settings schema.

Comments and trailing commas are blanked in place, so line and column numbers
in errors point into the original file.

Usage: check_jsonc.py [--self-test] [file ...]   (default: every tracked
*.json / *.jsonc file)
"""
import json
import subprocess
import sys


class JsoncError(ValueError):
    pass


class Pairs(list):
    """An object as its ordered (key, value) pairs, so duplicates survive parsing."""


def position(text, index):
    line_start = text.rfind("\n", 0, index) + 1
    return f"line {text.count(chr(10), 0, index) + 1} column {index - line_start + 1}"


def strip_jsonc(text):
    """Return text as strict JSON: comments and trailing commas become spaces."""
    out = list(text)
    i, n = 0, len(text)
    prev = None           # last significant character outside comments
    pending_comma = None  # a ',' after a value, not yet followed by another one

    def blank(start, end):
        for j in range(start, end):
            if out[j] != "\n":
                out[j] = " "

    while i < n:
        ch = text[i]
        if ch == '"':
            j = i + 1
            while j < n and text[j] not in '"\n':
                j += 2 if text[j] == "\\" else 1
            if j >= n or text[j] != '"':
                raise JsoncError(f"unterminated string at {position(text, i)}")
            prev, pending_comma = '"', None
            i = j + 1
        elif text.startswith("//", i):
            end = text.find("\n", i)
            end = n if end == -1 else end
            blank(i, end)
            i = end
        elif text.startswith("/*", i):
            end = text.find("*/", i + 2)
            if end == -1:
                raise JsoncError(f"unterminated /* comment at {position(text, i)}")
            blank(i, end + 2)
            i = end + 2
        elif ch in " \t\r\n":
            i += 1
        else:
            if ch in "}]" and pending_comma is not None:
                out[pending_comma] = " "
            # only a comma that follows a value can be a trailing one: "[,]"
            # and ",," stay errors
            pending_comma = i if ch == "," and prev not in (None, "[", "{", ",") else None
            prev = ch
            i += 1
    return "".join(out)


def duplicate_keys(node, path="$"):
    if isinstance(node, Pairs):
        seen = set()
        for key, value in node:
            if key in seen:
                yield f"{path}: duplicate key {key!r}"
            seen.add(key)
            yield from duplicate_keys(value, f"{path}.{key}")
    elif isinstance(node, list):
        for i, value in enumerate(node):
            yield from duplicate_keys(value, f"{path}[{i}]")


def parse_jsonc(text):
    """Parse JSONC; raise JsoncError on a syntax error or a duplicate key."""
    try:
        tree = json.loads(strip_jsonc(text), object_pairs_hook=Pairs)
    except json.JSONDecodeError as error:
        raise JsoncError(f"{error.msg} at line {error.lineno} column {error.colno}") from None
    dupes = list(duplicate_keys(tree))
    if dupes:
        raise JsoncError("; ".join(dupes))
    return tree


# settings is one object, a keymap is a list of {context, bindings} sections
ROOT_TYPES = {"settings.json": Pairs, "keymap.json": list}


def check_file(path):
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
    except (OSError, UnicodeDecodeError) as error:
        return [f"{path}: {error}"]
    if text.startswith("﻿"):
        return [f"{path}: starts with a byte-order mark"]
    try:
        tree = parse_jsonc(text)
    except JsoncError as error:
        return [f"{path}: {error}"]
    want = ROOT_TYPES.get(path.rsplit("/", 1)[-1])
    if want is not None and not isinstance(tree, want):
        kind = "an object" if want is Pairs else "an array"
        return [f"{path}: the root must be {kind}"]
    return []


def self_test():
    assert parse_jsonc('// c\n{"a": 1, /* b */ "b": [1, 2,], }') == Pairs(
        [("a", 1), ("b", [1, 2])])
    # comment markers inside strings are data
    assert parse_jsonc('{"u": "https://x//y", "g": "/* no */"}') == Pairs(
        [("u", "https://x//y"), ("g", "/* no */")])
    assert parse_jsonc('["a\\"//b",]') == ['a"//b']
    # a trailing comma may be separated from the bracket by comments
    assert parse_jsonc('{"a": 1, // last\n /* x */ }') == Pairs([("a", 1)])
    for bad, why in (('{"a": 1,, }', "line 1"),
                     ('{,}', "line 1"),
                     ('{"a": 1 "b": 2}', "line 1 column 9"),
                     ('{"a": 1}\n/* open', "unterminated /* comment at line 2"),
                     ('{"a": "open\n"}', "unterminated string at line 1"),
                     ('[,]', "Expecting value"),
                     ('{"k": {"x": 1, "x": 2}}', "$.k: duplicate key 'x'"),
                     ('[{"b": {"ctrl-d": 1}}, {"b": {"ctrl-d": 1, "ctrl-d": 2}}]',
                      "$[1].b: duplicate key 'ctrl-d'")):
        try:
            parse_jsonc(bad)
        except JsoncError as error:
            assert why in str(error), f"{bad!r}: {error}"
        else:
            raise AssertionError(f"accepted {bad!r}")
    print("self-test ok")


def main(argv):
    if argv[:1] == ["--self-test"]:
        self_test()
        argv = argv[1:]
    files = argv or subprocess.run(
        ["git", "ls-files", "*.json", "*.jsonc"],
        check=True, capture_output=True, text=True).stdout.split()
    problems = [p for f in files for p in check_file(f)]
    for problem in problems:
        print(problem, file=sys.stderr)
    for f in files:
        if not any(p.startswith(f"{f}:") for p in problems):
            print(f"ok  {f}")
    return 1 if problems or not files else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
