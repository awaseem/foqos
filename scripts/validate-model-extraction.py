#!/usr/bin/env python3
"""Audit the widget model extraction against its pre-refactor source.

This intentionally validates this specific extraction, not arbitrary Swift syntax.
Run from any directory; output is a Markdown table with original/current line numbers.
"""

import difflib
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parent.parent
BASELINE = "6883cd0"
MODELS = [
    ("BlockedProfiles", "BlockedProfiles+App"),
    ("BlockedProfileSessions", "BlockedProfileSession+App"),
]


def git_source(path):
    return subprocess.check_output(
        ["git", "show", f"{BASELINE}:{path}"], cwd=ROOT, text=True
    )


def code_lines(source):
    # Comments/imports are checked separately; preserve all code and indentation.
    return [
        line for line in source.splitlines()
        if line.strip() and not line.strip().startswith("//")
        and not line.startswith("import ")
    ]


def line_number(source, offset):
    return source[:offset].count("\n") + 1


def validate():
    rows = []
    total = 0
    for model, extension in MODELS:
        path = f"Foqos/Models/{model}.swift"
        old = git_source(path)
        new = (ROOT / path).read_text()
        moved = (ROOT / f"Foqos/Models/{extension}.swift").read_text()
        remaining_old = old
        remaining_extension = moved
        members = list(re.finditer(
            r"^  (?:(?:static|private) )?(?:var|func) \w+[^\n]*", moved, re.M
        ))
        for member in members:
            # Each extracted member closes at class-member indentation.
            end = moved.index("\n  }", member.end()) + 4
            block = moved[member.start():end]
            assert old.count(block) == 1, f"Changed/missing member: {member.group()}"
            original_line = line_number(old, old.index(block))
            current_line = line_number(moved, member.start())
            name = re.search(r"(?:var|func) (\w+)", member.group()).group(1)
            rows.append(
                f"| `{name}` | `{model}.swift:{original_line}` | "
                f"`{extension}.swift:{current_line}` | Exact match |"
            )
            remaining_old = remaining_old.replace(block, "", 1)
            remaining_extension = remaining_extension.replace(block, "", 1)
        assert len(code_lines(remaining_extension)) == 2, "Unaccounted extension code"
        before = code_lines(remaining_old)
        if model == "BlockedProfiles":
            strategy = git_source("Foqos/Models/Strategies/NFCBlockingStrategy.swift")
            assert 'static var id: String = "NFCBlockingStrategy"' in strategy
            before = [line.replace(
                "blockingStrategyId: String = NFCBlockingStrategy.id,",
                'blockingStrategyId: String = "NFCBlockingStrategy",'
            ) for line in before]
        after = code_lines(new)
        assert before == after, "\n".join(difflib.unified_diff(before, after))
        old_comments = sorted(line for line in old.splitlines() if line.strip().startswith("//"))
        new_comments = sorted(
            line for line in (new + moved).splitlines()
            if line.strip().startswith("//") and not line.startswith("// App behavior")
        )
        assert old_comments == new_comments, "Changed/lost model comments"
        imports = lambda text: set(re.findall(r"^import .+$", text, re.M))
        assert imports(old) == imports(new) | imports(moved), "Unaccounted import change"
        total += len(members)
    print(f"Validated {total} exact member moves against {BASELINE}.")
    print("All stored declarations, attributes, relationships and initializer code match;")
    print("the profile default strategy substitution has the same verified value.\n")
    print("| Member | Before | After | Result |")
    print("| --- | --- | --- | --- |")
    print("\n".join(rows))


if __name__ == "__main__":
    validate()
