# Feature Report: Environment overrides for loadConfig

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript (CommonJS) · Node.js >=18 · node:test

## Summary

**Goal:** `HOST`, `PORT` and `DEBUG` environment variables override the matching values from `config.json` in `loadConfig()`, and the result still satisfies the contract `createServer` enforces (string host, integer port 0-65535, boolean debug).

## Definition of Done

| # | Criterion | Met? | Evidence |
|---|-----------|:----:|----------|
| 1 | `HOST` set → `loadConfig()` returns that host | ✅ | `test/config.test.js:36` (S1); `src/config.js:44` |
| 2 | `PORT` set → integer returned; `createServer(loadConfig())` accepts it and reports the overridden address | ✅ | `test/config.test.js:40,46` (S2); `src/config.js:18-23,45` |
| 3 | `DEBUG` boolean-like → real boolean; `DEBUG=false` turns debug off although file says `true` | ✅ | `test/config.test.js:53,59,77-82` (S3); `src/config.js:25-30,46` |
| 4 | Unset variables leave file values untouched (per key) | ✅ | `test/config.test.js:36,72` (S1, S4); `src/config.js:11-14` |
| 5 | Invalid `PORT` / `DEBUG` fail loudly at load time, naming the variable; no wrong config returned | ✅ | `test/config.test.js:109-123` (S6, S7); `src/config.js:19-21,29` |
| 6 | New behaviour covered by tests; `npm test` passes | ✅ | 38 tests, 38 pass, 0 fail (`npm test`) |

**Result:** 6/6 criteria met.

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `src/config.js` | Modified | `loadConfig(file, env = process.env)`; per-key override via `fromEnv`, `parsePort` and `parseDebug` validate and coerce; empty string means unset |
| `test/config.test.js` | Modified | Existing tests isolated with `env = {}`; 34 new tests (S1-S9) |
| `docs/devflow/features/2026-09-20-env-config-overrides-feature-plan.md` | Created | Approved plan (flow artifact) |
| `docs/devflow/features/2026-09-20-env-config-overrides-feature.md` | Created | This report (flow artifact) |
| `docs/devflow/metrics/2026-09-20-env-config-overrides-metrics.md` | Created | Metrics (flow artifact) |

`src/server.js` was intentionally left unchanged: it already validates the shape of what `loadConfig()` returns.

## Tasks Completed

- [x] Task 1: Override HOST, PORT, DEBUG from the environment — `feat(config): let HOST, PORT and DEBUG override config.json values`
- [x] Task 2: Fail fast on invalid values; empty variable means "not set" — `feat(config): reject invalid PORT/DEBUG and treat empty variables as unset`

## Tests

| Test File | Test Name | Status |
|-----------|-----------|--------|
| `test/config.test.js` | HOST/PORT/DEBUG override, type coercion, `createServer` integration, per-call env, default `process.env` (S1-S5, S9) — 17 tests | ✅ Red confirmed, then passing |
| `test/config.test.js` | invalid PORT (10 values), invalid DEBUG (5 values), partial override, empty strings (S6-S8) — 17 tests | ✅ Red confirmed, then passing |

**Verify with:**
- Single file: `node --test test/config.test.js`
- Full suite: `npm test`

## Self-Review

| Check | Result |
|-------|--------|
| Security (`security.md §1`) | ✅ env values are external input; allowlist-validated (`/^\d+$/` + range, `true/false/1/0`), never passed through as raw strings |
| Error handling (`error-handling.md §1, §2`) | ✅ invalid values throw `TypeError` naming the variable; nothing swallowed, no `NaN`, no partial config |
| Naming conventions | ✅ matches existing style (`'use strict'`, CommonJS, arrow/named functions, `TypeError` as in `server.js`) |
| Design principles (`design-principles.md §2, §5`) | ✅ one small helper, three parsers, no options object or new module |
| Test coverage (`testing.md §4, §6`) | ✅ happy path, boundaries, failure and empty-string cases, sequences; tests inject `env`, one test restores `process.env` in `finally` |
| Lint / typecheck | N/A — the project defines no lint or typecheck command |

## Notes

- **Assumptions made in CI mode** (nobody to ask): env var > file value, per key; unset or empty variable = no override; `PORT` digits only within 0-65535; `DEBUG` accepts `true|false|1|0` case-insensitively and anything else throws; `HOST` is taken verbatim when non-empty; the config file is still read even when all three variables are set.
- **Critical Friend WARN (accepted, documented):** `DEBUG` collides with the `debug` package's convention (`DEBUG=app:*`). Scenario: `DEBUG=app:*` exported → `loadConfig()` → `TypeError: DEBUG must be one of true, false, 1, 0` at `src/config.js:29`; the request does not define non-boolean values. Failing loudly was chosen over silently coercing (`error-handling.md §1`). A prefixed variable would avoid the collision but contradicts the requested names.
- **Signature change:** `loadConfig(file = DEFAULT_FILE, env = process.env)` — the new second parameter exists for test isolation; one-argument callers are unaffected.

### Additional Recommendations
- **Config validation:** file-sourced values are still not validated inside `loadConfig` (only `createServer` checks them); consider validating them at the same boundary in a separate change.
- **Documentation:** the project has no README; the override rules (precedence, accepted `DEBUG` values, empty = unset) are documented only in the code comments and this report.
