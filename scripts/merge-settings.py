#!/usr/bin/env python3
"""Merge a DevFlow permission snippet into an editor's JSON settings file.

Used by install.sh (configure_permissions). The snippet arrives on stdin, with
install-path placeholders ($SKILLS_DIR, $HOME, ...) already substituted; the
target settings file is the only argument.

Merge semantics — non-destructive, the user's settings always win:
  * objects merge recursively; on a scalar conflict the user's value is kept;
  * lists are unioned (existing items first, new ones appended);
  * a map whose keys are all strings and whose values are all strings or
    booleans is a *rule map* (opencode's permission.bash, VS Code's
    autoApprove). Some editors evaluate those in order — opencode: the LAST
    matching rule wins — so after merging, the user's own keys come first and
    the snippet's keys follow in the snippet's order, keeping the precedence
    the snippet was written for;
  * "_devflow_retired" in the snippet mirrors the settings structure and lists
    list items / map keys that earlier DevFlow versions installed and that must
    now go (e.g. a rule the editor rejects). Only those exact values are
    removed; nothing the user wrote is touched.

Exit codes: 0 = merged, 1 = target is not plain JSON (JSONC) or unreadable —
the caller leaves it untouched and prints manual instructions;
2 = our own invocation failed (usage error, broken snippet JSON) — loud,
never mistaken for JSONC.
"""
import copy
import json
import sys

RETIRED_KEY = "_devflow_retired"


def is_rule_map(value):
    return (isinstance(value, dict) and bool(value)
            and all(isinstance(k, str) for k in value)
            and all(isinstance(v, (str, bool)) for v in value.values()))


def merge(base, add):
    if isinstance(base, dict) and isinstance(add, dict):
        if is_rule_map(base) and is_rule_map(add):
            ordered = {k: v for k, v in base.items() if k not in add}
            for k, v in add.items():
                ordered[k] = base.get(k, copy.deepcopy(v))  # user's verdict wins
            return ordered
        for key, value in add.items():
            base[key] = merge(base[key], value) if key in base else copy.deepcopy(value)
        return base
    if isinstance(base, list) and isinstance(add, list):
        return base + [copy.deepcopy(item) for item in add if item not in base]
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


def main(argv):
    if len(argv) != 2:
        print(f"usage: {argv[0] if argv else 'merge-settings.py'} <target-settings.json> < snippet.json",
              file=sys.stderr)
        return 2
    target = argv[1]
    try:
        snippet = json.loads(sys.stdin.read())
    except (ValueError, OSError) as exc:
        print(f"merge-settings: cannot parse snippet JSON from stdin: {exc}", file=sys.stderr)
        return 2
    if not isinstance(snippet, dict):
        print("merge-settings: snippet JSON must be an object", file=sys.stderr)
        return 2
    retired = snippet.pop(RETIRED_KEY, {})

    data = {}
    try:
        with open(target, encoding="utf-8") as fh:
            content = fh.read().strip()
    except FileNotFoundError:
        content = ""
    except OSError as exc:
        print(f"merge-settings: cannot read {target}: {exc}", file=sys.stderr)
        return 2
    if content:
        try:
            data = json.loads(content)
        except ValueError:
            return 1  # JSONC (comments / trailing commas): leave it untouched

    data = merge(retire(data, retired), snippet)
    try:
        with open(target, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
    except OSError as exc:
        print(f"merge-settings: cannot write {target}: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
