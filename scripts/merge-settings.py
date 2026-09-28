#!/usr/bin/env python3
"""Merge a DevFlow permission snippet into an editor's JSON settings file.

Used by install.sh (configure_permissions). The snippet arrives on stdin, with
install-path placeholders ($SKILLS_DIR, $HOME, ...) already substituted; the
target settings file is the only argument.

Merge semantics — non-destructive, the user's settings always win:
  * objects merge recursively; on a scalar conflict the user's value is kept;
  * lists are unioned (existing items first, new ones appended);
  * a map whose values are all scalars is a *rule map* (opencode's
    permission.bash, VS Code's autoApprove). Some editors evaluate those in
    order — opencode: the LAST matching rule wins — so after merging, the
    user's own keys come first and the snippet's keys follow in the snippet's
    order, keeping the precedence the snippet was written for;
  * "_devflow_retired" in the snippet mirrors the settings structure and lists
    list items / map keys that earlier DevFlow versions installed and that must
    now go (e.g. a rule the editor rejects). Only those exact values are
    removed; nothing the user wrote is touched.

Exit codes: 0 = merged, 1 = target is not plain JSON (JSONC) or unreadable —
the caller leaves it untouched and prints manual instructions.
"""
import json
import sys

RETIRED_KEY = "_devflow_retired"


def is_rule_map(value):
    return isinstance(value, dict) and value and all(
        not isinstance(v, (dict, list)) for v in value.values())


def merge(base, add):
    if isinstance(base, dict) and isinstance(add, dict):
        if is_rule_map(base) and is_rule_map(add):
            ordered = {k: v for k, v in base.items() if k not in add}
            for k, v in add.items():
                ordered[k] = base.get(k, v)  # the user's verdict wins
            return ordered
        for key, value in add.items():
            base[key] = merge(base[key], value) if key in base else value
        return base
    if isinstance(base, list) and isinstance(add, list):
        return base + [item for item in add if item not in base]
    return base  # scalar conflict: the user's existing value wins


def retire(base, retired):
    if isinstance(base, dict) and isinstance(retired, dict):
        for key, value in retired.items():
            if key in base:
                base[key] = retire(base[key], value)
        return base
    if isinstance(base, list) and isinstance(retired, list):
        return [item for item in base if item not in retired]
    if isinstance(base, dict) and isinstance(retired, list):
        return {k: v for k, v in base.items() if k not in retired}
    return base


def main():
    target = sys.argv[1]
    snippet = json.loads(sys.stdin.read())
    retired = snippet.pop(RETIRED_KEY, {})

    data = {}
    try:
        with open(target, encoding="utf-8") as fh:
            content = fh.read().strip()
    except FileNotFoundError:
        content = ""
    if content:
        try:
            data = json.loads(content)
        except ValueError:
            return 1  # JSONC (comments / trailing commas): leave it untouched

    data = merge(retire(data, retired), snippet)
    with open(target, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
