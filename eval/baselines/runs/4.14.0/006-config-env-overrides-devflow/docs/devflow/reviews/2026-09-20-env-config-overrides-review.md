# Code Review: Environment overrides for loadConfig

**Date:** 2026-09-20
**Reviewer:** DevFlow Reviewer (automated)
**Review Mode:** Standalone (invoked by Feature Agent)
**Invoking Agent:** Feature Agent
**Reference:** `docs/devflow/features/2026-09-20-env-config-overrides-feature.md`

## Summary

`loadConfig(file, env = process.env)` applies `HOST`/`PORT`/`DEBUG` overrides with allowlist parsing that fails loudly on invalid values, and the result satisfies the contract `createServer` enforces. No blockers or warnings: the deterministic scans are clean, the DoD and behavior scenarios S1-S9 trace to code paths and tests, and every mutation tried on a behavior-relevant path fails at least one test.

## Findings

> **Evidence** is `{standard}.md §{N}` or `scenario: {precondition} → {sequence} → observed {X}, expected {Y} per {source}` — see rules.md → Finding Evidence.

### 🔴 BLOCK (must fix)
None.

### 🟡 WARN (should fix)
None.

### 🟢 INFO (optional)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| 1 | `src/config.js` | 13, 16, 44 | A whitespace-only `HOST` is accepted verbatim, while `PORT=' '` and `DEBUG=' '` throw. `createServer` accepts it too. Classified as a deliberate decision (CI Assumption 5: HOST taken verbatim, no syntax validation) that is partly a plan gap because the whitespace-only case was not named. | scenario: config.json host `localhost` → `loadConfig(FILE, { HOST: ' ' })` → observed host `' '` at `src/config.js:44` and address `' :3000'` from `createServer` (`src/server.js:20`), expected a usable interface per the `loadConfig` header comment (host is "the interface to bind"); also `security.md §1 → INFO` | Optionally trim and treat blank as unset, or reject with a `TypeError` naming `HOST`, and pin the choice with a test. |
| 2 | `src/config.js` | 36-40, 44-46 | The pre-existing header comment states the result shape, but only env-sourced values are validated in `loadConfig`; file-sourced values pass through unchecked (a string `port` in the file is returned as a string). `createServer` still rejects it, so the only caller is protected. Cause predates this change; recorded as backlog D1. | scenario: config.json `{"host":"h","port":"3000","debug":true}`, no env → `loadConfig` returns `port: '3000'` at `src/config.js:45`, expected number per the header comment; severity INFO because the current caller cannot produce an incorrect result (Behavioral Impact Severity) | Validate file values with the same parsers, or soften the comment. Deferred: `devflow-ctl backlog` D1. |
| 3 | `src/config.js` | 29, 46 | `DEBUG` collides with the `debug` package convention: `DEBUG=app:*` exported in a developer shell makes `loadConfig()` throw at startup. Recorded decision from the plan's Critical Friend WARN (fail loudly, `error-handling.md §1`), pinned by an S7 test. | scenario: `DEBUG=app:*` exported → run anything calling `loadConfig()` → observed `TypeError: DEBUG must be one of true, false, 1, 0` at `src/config.js:29`, expected: request does not define non-boolean values; deliberate decision per the plan | None required; document the behavior when a README exists. |
| 4 | `test/config.test.js` | 53-57 | The S3 test is named for `loadConfig` but also asserts `createServer(config).logLevel` (two subjects). The two assertions are related (S3 end to end) and the plan prescribed this test. | `testing.md §2 → INFO` | Split into a `loadConfig` test and a `createServer` test, or rename to cover both. |

### ❓ Open Questions *(optional — not findings, never affect the verdict)*
- `src/config.js:19` — `PORT=0` is accepted and yields an ephemeral bind. It matches the documented contract (0 to 65535) and `assertValidConfig`; it would only be a defect if port 0 were meant to be unintended in production. The request does not say so.
- `src/config.js:41-47` — file values are never validated in `loadConfig`; only a defect if a consumer other than `createServer` appears. None found.

## Coverage

> What this review actually examined. An APPROVED verdict is only as strong as this section: a dimension, standard or consumer that is not listed here was not reviewed.

| Dimension | Ran? | Standards loaded in full | Notes |
|-----------|------|--------------------------|-------|
| 1 — Security & Safety | ✅ | security.md v2.6.0, error-handling.md v1.4.0 | Quick Card BLOCK triggers scanned first, none matched |
| 2 — Performance, Concurrency & Data | ⏭ no signal | — | No data access, loops over collections, async work or state that outlives a call (S6 absent); a single synchronous file read and a fixed three-key parse |
| 3 — Architecture & Design | ✅ | design-principles.md v1.2.0, solid.md v2.4.0, project-design.md v2.4.0, testing.md v1.5.0 | Reference implementation compared: `src/server.js` (`assertValidConfig`) and the existing test style in `test/config.test.js`; clean-architecture.md not loaded (no layering signal: two flat modules) |
| 4 — Correctness & Behavior | ✅ | — | Consumers read: `src/server.js`; grep for `loadConfig` found no other consumer (only `src/config.js`, `test/config.test.js`, `package.json`); scenarios walked: 9 (S1-S9) plus empty-string trap, partial failure, call-time env read; mutation reasoning applied, no surviving mutation; open questions: 2 |
| 5a/5b/5c/5d — Domain | ⏭ no trigger | — | No endpoint, event, external integration, UI, logging, dependency manifest or new abstraction/extension point in the diff |

- **Review path:** parallel (subagents 1, 3, 4) — **diff signals present:** S4 (contract: `loadConfig` signature and configuration keys), S5 (security surface: environment input parsing/validation)
- **Deterministic checks:** `scan all` clean (secrets clean, SCA clean, SAST skipped: semgrep not installed) · `scope audit` clean · `traceability check` n/a (no `traceability.md` for a standalone Feature Agent cycle)
- **Visual diff:** skipped — no UI
- **Runtime verification:** skipped — rigor `standard`, below `deep`; behavior traced against code and exercised by read-only one-liners (`HOST=' '`, `DEBUG='*'`, `PORT='80\n'`, non-ASCII digits, oversized PORT, `PORT='0'`)
- **Git conventions:** branch `feat/env-config-overrides`; commits `feat(config): let HOST, PORT and DEBUG override config.json values` and `feat(config): reject invalid PORT/DEBUG and treat empty variables as unset` follow `git-conventions.md §1, §2` (type, scope, imperative description; no work on a protected branch)
- **Not covered:** the full suite was not re-run by the Reviewer (the Feature Agent ran it: 38 pass / 0 fail); dimension 2 skipped for lack of signals; semgrep SAST unavailable

## Verdict
✅ APPROVED — no blockers
