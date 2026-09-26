# Framework Memory — Canonical Pattern

> **Framework-centric principle:** everything DevFlow learned used to be written into the project it was working on (`docs/devflow/knowledge-base/`). A lesson learned in project A never reached project B, and a mistake of the *framework itself* — a standard that doesn't exist, a Reviewer dimension that keeps missing the same class, a gate that keeps failing the same way — had nowhere to accumulate. Framework memory is the second level: lessons about **how DevFlow works**, abstracted from the project where they happened, kept by the framework across every project and every editor, and promoted into the framework's own standards and skills once they are confirmed.

This document is the canonical source for the framework memory: where it lives, what an entry is, what may be written to it, how agents load it, and how an entry becomes a change to DevFlow. `devflow-ctl memory` implements every rule below deterministically — agents never read or edit the store's files directly.

---

## Two Levels of Memory

| Level | Holds | Lives in | Precedence |
|---|---|---|---|
| **Project** | Conventions, decisions and anti-patterns of *this* codebase; the standards profile; the deferred backlog; this project's metrics and escapes | `docs/devflow/knowledge-base/` ([memory-conventions.md](./memory-conventions.md) → Persistent Artifacts) | Always wins over framework memory |
| **Framework** | Mistakes and lessons about **how DevFlow works**, with nothing that identifies the project where they happened | The framework memory store (below) | Below the standards and below the project |

**Precedence when applying:** standard > project standards profile > project learnings > framework memory `confirmed` > framework memory `candidate`. A memory entry never overrides a standard. An entry that contradicts one is exactly what promotion (below) exists to resolve.

---

## The Store

```
DEVFLOW_HOME   = $DEVFLOW_HOME, else $XDG_DATA_HOME/devflow, else ~/.local/share/devflow
                 (Git Bash on Windows: %LOCALAPPDATA%\devflow)

$DEVFLOW_HOME/
├── config                     # written by install.sh: source_dir, source_repo, version
└── memory/
    ├── INDEX.md               # generated on every write — never edited by hand
    ├── entries/M0001-<slug>.md
    ├── friction.log           # process events, written only by devflow-ctl
    └── escape-counts.tsv      # class × layer counts of every escape, no text
```

- **Outside every project and every editor install.** Reinstalling, switching editors or uninstalling never touches it (`uninstall.sh --purge-memory` is the only way to delete it). Every editor profile shares the same store.
- **Never `~/.devflow`.** `install.sh` deletes that path as a leftover of v1.2.x installs.
- **It never blocks a cycle.** An unwritable store is a warning (exit 0): memory is instrumentation, not a gate.
- `devflow-ctl memory path` prints where it is.

---

## Entry Format

One file per entry, so deduplication, retirement and review are single-file operations:

```markdown
---
id: M0007
type: escape | correction | false-positive | friction | stack-pattern
status: candidate | confirmed | promoted | retired
title: <one line>
agents: [devflow-review]          # who should apply it; [any] for all
stack: [any]                      # or [node, react], [python, django]…
class: state-transitions          # escape class (escape-analysis.md), or —
layer: reviewer:correctness-behavior   # escape layer, or —
target: devflow-review/correctness-guide.md   # where it would be promoted, relative to the skills dir
key: escape:state-transitions:reviewer-correctness:cache-key-options
seen:
  - p-3fa9c21e 2026-09-12         # project id (hash) + date, one line per project
promoted_ref: —
created: 2026-09-12
updated: 2026-09-24
---

**Rule:** <what to do — one sentence>
**Why:** <what went wrong, in the abstract>
**How to apply:** <which agent, which step, which signal>
```

- **`key`** is the deduplication signature: `{type}:{class-or-topic}:{layer-or-agent}:{short-kebab}`. `memory add` with an existing key exits 1 and names the entry — record a recurrence with `memory seen <id>` instead.
- **Project ids** are `p-` + 8 hex characters of a hash of the project's `origin` remote (or its root path). They count *distinct projects* without storing a name or a path.

```bash
devflow-ctl memory add --type <type> --key <key> --title "<title>" --rule "<rule>" \
  [--why "<why>"] [--apply "<how>"] [--agent a,b] [--stack s,t] \
  [--class <escape class>] [--layer <escape layer>] [--target <skills-relative path>]
devflow-ctl memory list [--status s] [--type t] | show <id> | index | path
```

---

## Privacy

The store is shared by every project on the machine — including client projects. **An entry describes the pattern, never the case**, the same rule the standards follow (technology-agnostic, no project examples). `memory add` refuses (exit 1, nothing written) any title, rule, why or how-to-apply that contains:

- an absolute path, or a relative path that exists in the current project;
- the current repository's or remote's name;
- more than 5 lines (code or a transcript, not a lesson);
- an email address, or a URL outside the DevFlow repository;
- anything that looks like a secret (the same families `devflow-ctl scan secrets` detects).

The project checks are skipped inside DevFlow's own repository, where naming the framework's files is the point of an entry. When a refusal fires, rewrite the entry in the abstract — do not work around the guard.

---

## Load Memory

Agents never read `INDEX.md` or entry files. They ask for the few entries that concern them:

```bash
devflow-ctl memory query --agent <this agent's skill name> --stack <detected stack, comma-separated> [--type <type>] [--limit 8]
```

- **Filters:** entries whose `agents` include this agent (or `any`) and whose `stack` includes one of the detected stacks (or `any`). `promoted` and `retired` entries are never returned — a promoted lesson already lives in a standard or skill, and repeating it would only duplicate context.
- **Ranking:** `confirmed` before `candidate`, then by number of distinct projects, then by most recent sighting. The default limit is 8, so the context cost stays bounded however large the store grows.
- **Reading the result:** a `confirmed` entry is a rule — apply it as you would a project learning. A `candidate` entry is printed as *unconfirmed, treat as a hint*: check whether it applies here, and if it does, record the recurrence with `devflow-ctl memory seen <id>`.
- **An empty result is normal**, not an error.

`devflow-ctl capabilities` and `devflow-ctl status` both print a `memory:` / `Framework memory:` line with the confirmed and candidate counts, so the store is visible at every agent's Step 0 even before a query.

---

## Lifecycle

```
candidate ──(seen in ≥2 distinct projects | the user confirms)──▶ confirmed ──(PR merged into DevFlow)──▶ promoted
    │                                                                 │
    └──────────────(unseen ≥180 days | the user retires it)───────────┴──────────────▶ retired
```

| Command | Transition | Who decides |
|---|---|---|
| `memory seen <id>` | Adds this project to `seen` (one line per project); a candidate with 2 distinct projects becomes `confirmed` | Automatic |
| `memory confirm <id>` | `candidate → confirmed` | The user |
| `memory retire <id> --reason "..."` | `candidate\|confirmed → retired`, reason appended to the entry | The user |

`memory query` lists candidates unseen for 180 days as *stale* and proposes retiring them. Nothing is ever retired automatically. Illegal transitions (e.g. confirming a retired entry) exit 1.

---

## Capture

Five entry types, each with one trigger and one owner. The first is deterministic and needs no agent cooperation; the others are written by the agent that owns the moment, under the rules in this section.

| Type | Trigger | Recorded by |
|---|---|---|
| `friction` | A gate check fails, a file is outside scope, an iteration limit is exceeded, an artifact check fails, a stale lock is broken or forced | `devflow-ctl` itself, in `friction.log` (below) |

### Friction (deterministic)

`devflow-ctl` appends one line to `friction.log` whenever `gate check`, `scope check`, `iterate`, or `artifacts check` exits 1, and whenever `lock acquire` breaks a stale lock or is forced over a live one. A line holds the date, the project id, a hashed session id, the session's mode and rigor, the event, and a detail (gate and state, loop name, artifact type, or — for scope — **only the file's extension**). The log never holds a slug, a name or a path. Usage errors (exit 2) and passing checks log nothing.

The raw log is never shown to an agent. `devflow-ctl memory friction report` groups it by mode, event and detail, and proposes each pattern that recurs in **≥3 sessions across ≥2 projects** (`--sessions` / `--projects` override) as a `friction` entry, with the exact `--key` to use — or names the entry that already records it, for `memory seen`. The Finalizer and every standalone agent's closing step run the report and propose new patterns to the user; the entry's rule is written by the agent, in the abstract, only after the user agrees.
