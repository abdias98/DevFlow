# DevFlow Permission Snippets — Tier Classification

> Single source of truth for the 3-tier permission model used by all editor
> profiles. `validate-framework.sh` enforces that Tier C patterns never appear
> in a Tier A (allow) section.

## Design principle

DevFlow `rules.md` defines **Standard mode** as auto-execute: the Implementer
auto-runs branch creation, tests, commits, and git SHAs. The permission
snippets must align with that contract so the editor does not re-prompt for
actions DevFlow already authorizes.

The corollary: **destructive or sensitive commands must ask the user**, even
in Standard mode. Only commands that violate DevFlow rules outright are
denied.

## Tier A — Allow (auto-approve)

Safe, idempotent, or explicitly auto-executed by Standard mode.

| Category | Commands |
|----------|----------|
| **DevFlow** | `devflow-ctl *`, `mkdir *`, `touch *` |
| **File ops (safe)** | `cp *`, `mv *`, `mkdir *` |
| **Search / read** | `grep`, `rg`, `find`, `ls`, `cat`, `head`, `tail`, `wc`, `tree`, `du`, `stat`, `file`, `which`, `pwd`, `diff`, `sort`, `uniq`, `awk`, `sed`, `echo`, `printf`, `test` |
| **Git (non-destructive + Standard mode)** | `git rev-parse`, `git status`, `git diff`, `git log`, `git checkout -b`, `git add`, `git commit` (without `--no-verify`), `git branch` |
| **Build / test / lint** | `npm run/test/ci`, `npx`, `pnpm`, `yarn`, `python`, `python3`, `pytest`, `ruff`, `mypy`, `node`, `tsc`, `go test/build/vet`, `cargo test/build/check`, `make` |

## Tier B — Ask (confirm with user)

Deletion, destructive git, privilege escalation, or supply-chain risk.

| Category | Commands |
|----------|----------|
| **Deletion** | `rm *`, `rmdir *` |
| **Git (destructive)** | `git push`, `git reset --hard`, `git clean`, `git rebase`, `git commit --amend`, `git cherry-pick` |
| **Privilege escalation** | `sudo`, `chmod`, `chown`, `kill`, `pkill`, `killall` |
| **Dependencies (new packages)** | `npm install`, `yarn add`, `pip install` |

> **Rationale:** `rules.md` states `git push` is NEVER auto-executed in any
> mode. New dependencies trigger `dependencies.md` review (supply-chain risk).
> Deletion is irreversible and outside DevFlow's auto-rollback checkpoint.

## Tier C — Deny (prohibited by DevFlow rules)

| Pattern | Reason |
|---------|--------|
| `git push --force*` / `git push -f*` | Destroys remote history; violates `rules.md` push policy |
| `git commit --no-verify*` | Bypasses hooks; `rules.md` prohibits skipping hooks |

> **Note:** Deny prevents the **agent** from running the command. The user can
> still execute it manually in their terminal.

## Editor-specific implementation

| Editor | Tier A | Tier B | Tier C | Mechanism |
|--------|--------|--------|--------|-----------|
| **Claude Code** | `permissions.allow[]` | `permissions.ask[]` | `permissions.deny[]` | Glob patterns: `Bash(cmd *)`, `Read(path)`, `Edit(path)`, `Write(path)` |
| **opencode** | `permission.bash` → `"allow"` | `permission.bash` → `"ask"` | `permission.bash` → `"deny"` | Map of command pattern → verdict. Deny patterns listed first for first-match precedence |
| **VS Code (Copilot)** | `chat.tools.terminal.autoApprove` → `true` | *(omitted — default prompts)* | *(omitted — no deny mechanism in this key)* | Regex patterns `/^cmd\\b/` |

### Precedence rules

- **Claude Code:** `deny` > `ask` > `allow`. First matching pattern in each
  tier wins. More specific patterns (e.g. `git commit --amend*` in ask)
  correctly override broader ones (e.g. `git commit *` in allow).
- **opencode:** Patterns evaluated in insertion order (JSON object key order).
  Deny patterns are listed first, then ask, then allow — ensuring
  first-match correctness.
- **VS Code:** No tiered precedence. Anything in `autoApprove` is auto-run;
  anything omitted falls through to the editor default (prompt).

## Alignment with `rules.md`

| `rules.md` rule | Snippet enforcement |
|-----------------|---------------------|
| Standard mode auto-executes `git checkout -b` | Tier A: `git checkout -b *` |
| Standard mode auto-executes `git add` + `git commit` | Tier A: `git add *`, `git commit *` |
| Standard mode auto-runs `{Test Command}` | Tier A: `npm run/test`, `pytest`, `go test`, `cargo test`, `make` |
| `git push` NEVER auto-executed | Tier B: `git push*` → ask |
| Hooks must not be skipped | Tier C: `git commit --no-verify*` → deny |
| `devflow-ctl` exempt from Test Execution Policy | Tier A: `devflow-ctl *` |

## Validation

`scripts/validate-framework.sh` (section 9) checks:
1. Every profile declares a `permissions.strategy`.
2. Every `json-merge` snippet is valid JSON and referenced by a profile.
3. **Guardrail:** no snippet places Tier C patterns (`rm `, `git push`,
   `--force`, `--no-verify`) in a Tier A (allow) section.
