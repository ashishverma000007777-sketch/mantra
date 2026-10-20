#!/usr/bin/env python3
import os
import sys

def check_dart_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    stack = []
    in_single_quote = False
    in_double_quote = False
    in_triple_single = False
    in_triple_double = False
    in_line_comment = False
    in_block_comment = False

    i = 0
    n = len(content)
    line = 1
    col = 1

    while i < n:
        c = content[i]
        nxt = content[i+1] if i+1 < n else ''
        nxt2 = content[i+2] if i+2 < n else ''

        if c == '\n':
            line += 1
            col = 1
            if in_line_comment:
                in_line_comment = False
            i += 1
            continue

        if in_line_comment:
            i += 1
            col += 1
            continue

        if in_block_comment:
            if c == '*' and nxt == '/':
                in_block_comment = False
                i += 2
                col += 2
            else:
                i += 1
                col += 1
            continue

        if in_triple_single:
            if c == "'" and nxt == "'" and nxt2 == "'":
                in_triple_single = False
                i += 3
                col += 3
            else:
                i += 1
                col += 1
            continue

        if in_triple_double:
            if c == '"' and nxt == '"' and nxt2 == '"':
                in_triple_double = False
                i += 3
                col += 3
            else:
                i += 1
                col += 1
            continue

        if in_single_quote:
            if c == '\\':
                i += 2
                col += 2
            elif c == "'":
                in_single_quote = False
                i += 1
                col += 1
            else:
                i += 1
                col += 1
            continue

        if in_double_quote:
            if c == '\\':
                i += 2
                col += 2
            elif c == '"':
                in_double_quote = False
                i += 1
                col += 1
            else:
                i += 1
                col += 1
            continue

        # Check start of comments
        if c == '/' and nxt == '/':
            in_line_comment = True
            i += 2
            col += 2
            continue

        if c == '/' and nxt == '*':
            in_block_comment = True
            i += 2
            col += 2
            continue

        # Check triple quotes
        if c == "'" and nxt == "'" and nxt2 == "'":
            in_triple_single = True
            i += 3
            col += 3
            continue

        if c == '"' and nxt == '"' and nxt2 == '"':
            in_triple_double = True
            i += 3
            col += 3
            continue

        # Check single quotes
        if c == "'":
            in_single_quote = True
            i += 1
            col += 1
            continue

        if c == '"':
            in_double_quote = True
            i += 1
            col += 1
            continue

        # Bracket matching
        if c in '({[':
            stack.append((c, line, col))
        elif c in ')}]':
            if not stack:
                return False, f"Unexpected closing '{c}' at {line}:{col}"
            top, t_line, t_col = stack.pop()
            expected = {'(': ')', '{': '}', '[': ']'}[top]
            if c != expected:
                return False, f"Mismatched bracket: expected '{expected}' (opened at {t_line}:{t_col}), got '{c}' at {line}:{col}"

        i += 1
        col += 1

    if stack:
        top, t_line, t_col = stack[-1]
        return False, f"Unclosed bracket '{top}' opened at {t_line}:{t_col}"

    return True, "OK"

def main():
    errors = 0
    checked = 0
    for root, _, files in os.walk('lib'):
        for f in sorted(files):
            if f.endswith('.dart'):
                filepath = os.path.join(root, f)
                checked += 1
                ok, msg = check_dart_file(filepath)
                if not ok:
                    print(f"FAIL: {filepath} - {msg}")
                    errors += 1
    for root, _, files in os.walk('test'):
        for f in sorted(files):
            if f.endswith('.dart'):
                filepath = os.path.join(root, f)
                checked += 1
                ok, msg = check_dart_file(filepath)
                if not ok:
                    print(f"FAIL: {filepath} - {msg}")
                    errors += 1
    print(f"Checked {checked} Dart files. Errors: {errors}")
    sys.exit(0 if errors == 0 else 1)

if __name__ == '__main__':
    main()
