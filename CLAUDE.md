# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

DevFlow is a multi-agent AI engineering framework distributed as Markdown skills plus a small bash kernel. It is installed into editors (VS Code Copilot, Claude Code, OpenCode, Antigravity, generic), not built or run as an app. `AGENTS.md` has the agent inventory, folder layout and naming conventions.

## Commands

```bash
npm install --ignore-scripts        # installs only bats; the package "install" script runs the editor installer, so skip it
npm run validate                    # scripts/validate-framework.sh: structural consistency (run after ANY change)
npm run validate:fix                # same checks, plus a fix hint for each failure
npm run lint:sh                     # shellcheck at warning level (the repo is clean at that level)
npm test                            # bats tests/
npx bats tests/devflow-ctl.bats     # one suite
npx bats -f 'regex' tests/devflow-ctl.bats   # tests whose name matches
eval/bin/devflow-eval list|init|score ...    # eval harness (see eval/README.md)
```

CI (`.github/workflows/ci.yml`) runs lint:sh → validate → test under **both `LC_ALL=C` and `es_ES.UTF-8`**. Bash in this repo must be locale-safe: for example, awk `printf "%.1f"` prints a comma under a Spanish locale. That bug once reached main.

## Architecture

- **Skills** (`.agents/skills/devflow-*/SKILL.md`): each agent is a self-contained Markdown skill with frontmatter. The orchestrator (`devflow/`, which also contains `lifecycle.md`) runs the 8-phase lifecycle. The other skills are phases or standalone agents. Every `devflow-*` skill must have a mirror `.github/prompts/devflow-*.prompt.md`, and the validator enforces this.
- **Shared layer** (`.agents/skills/shared/`) holds a single source of truth for each topic. `rules.md` owns the common policies: scope-locking, test execution, approval, finding evidence and severity. `memory-conventions.md` owns all paths and formats. `standards-loading.md` controls when each standard in `shared/standards/` is loaded. Do not restate these in skills. The validator catches some duplication (§14–§19).
- **`shared/bin/devflow-ctl`** is the deterministic enforcement CLI. Agents call it at gate transitions (phase, gates, scope and impact zone, iteration limits, locks, artifact sections), so state is not self-reported. State lives in the YAML frontmatter of `docs/devflow/session/{slug}/phase-state.md`, and `DEVFLOW_SESSION_ROOT` overrides the root. Exit codes: 0 = pass, 1 = check failed, 2 = usage or state error. `tests/devflow-ctl.bats` covers it.
- **Editor profiles** (`editor-profiles/*.yaml`) are parsed with grep/awk by `install.sh`/`install.ps1`, so keep the format strict: one `key: value` per line, no inline comments. At install time, `{{SKILLS_DIR}}` and backticked tool names from `tool_mappings`/`path_mappings` are replaced with sed. A mapping to `REMOVE` deletes the lines that use it. Write skills with the canonical tool names and `{{SKILLS_DIR}}`, never with editor-specific paths. Adding an editor needs only a new YAML file. Per-profile permission snippets live in `editor-profiles/permissions/`.
- **Review pipeline** (`devflow-review/`): `SKILL.md` defines the review subagents. `review-checklist.md` assigns each checklist section to exactly one subagent, declares no severities, and cites `{standard}.md §N` sections that must exist. Each subagent loads at most 5 standards. The validator enforces all of this.
- **Standards** (`shared/standards/*.md`) are technology-agnostic and written as DO/DON'T. Each needs a `> **Version:** X.Y.Z` header and a Limited Scope section. Sections are numbered: never renumber them; append new ones at the end.
- **Framework memory** (`shared/framework-memory.md`): cross-project lessons live outside every project and editor install, at `$DEVFLOW_HOME/memory/` (default `~/.local/share/devflow`; never `~/.devflow`, which `install.sh` deletes as legacy). Only `devflow-ctl memory` writes it. It holds one file per entry, a generated `INDEX.md`, and `friction.log`, which `devflow-ctl` appends to on every failed gate, scope, iterate or artifact check. Tests must isolate it with `DEVFLOW_HOME`. Confirmed entries are promoted into this repo as normal PRs: `devflow-ctl memory promote-list`, then `memory promote <id> --ref <PR>`.
- **Eval harness** (`eval/`): golden tasks with weighted executable checks. `devflow-eval` scores a result workspace and does not run the model. Pass/fail depends on **outcome** checks only. Process checks (DevFlow artifacts) are reported but never gate. Baselines per version live in `eval/baselines/`.

## Release and versioning

The version must match in `package.json`, `package-lock.json` and a `## [X.Y.Z] — YYYY-MM-DD` entry in `CHANGELOG.md` (validator §10). `install.sh` must not hardcode a version. Changelog entries cite finding IDs (`F66`) and waves (`Wave 19`) from the plans in `docs/`.

## Changing DevFlow itself

Adding an agent means adding a SKILL.md, its templates and a prompt file, then updating the orchestrator, `memory-conventions.md`, `output-format.md`, the lifecycle, `docs/ARCHITECTURE.md` and the reviewer. After editing a skill, run `npm run validate` and then check the behavior by invoking the modified agent.
