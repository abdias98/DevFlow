# Plan — Multi-agent contract integrity check (§15)

**Goal:** Give `validate-framework.sh` the ability to detect a multi-agent contract whose declared participants don't actually honour it — the F60 class.
**Architecture:** `docs/devflow/specs/2026-09-08-validate-contract-check-design.md`
**Rigor:** standard — small surface, but the check's own correctness is the deliverable, so the negative test is non-negotiable.
**Tech Stack:** Bash 4+ (GNU grep), bats 1.13 for tests. No runtime dependencies.

---

## Plan Digest

- **Tasks:** 3 tasks in 2 waves
- **Files to create:** `tests/validate-framework.bats`
- **Files to modify:** `scripts/validate-framework.sh`, `.agents/skills/shared/traceability-matrix.md`, `.agents/skills/shared/metrics-template.md`
- **Key dependencies:** Task 1 (declarations) → Task 2 (check reads them). Task 3 (tests) is written first per TDD but asserts on Task 2's output.
- **Risk areas:** Task 2 — a permissive check is worse than no check; guarded by the negative test and the live F60 revert.
- **Test strategy:** bats fixtures for the four logic cases + one live revert-and-verify acceptance run recorded in the review.
- **Scope:** §13 is NOT consolidated into §15 (deferred to Wave 18). No new standards. No CI changes — those are Grupo B.

---

## File Map

**Modify:**
- `scripts/validate-framework.sh` — add §15; update the usage header's numbered check list
- `.agents/skills/shared/traceability-matrix.md` — add `**Contract artifact:**` line
- `.agents/skills/shared/metrics-template.md` — add `**Contract artifact:**` line

**Create:**
- `tests/validate-framework.bats` — first test suite for the validator

**Impact Zone:**

| File | Verdict | Reason (if touch) |
|------|---------|--------------------|
| `.github/workflows/ci.yml` | no touch | Already runs `npm test` over `tests/`, so the new bats file is picked up with no edit |
| `package.json` | no touch | `"test": "bats tests/"` already globs the directory |
| `.agents/skills/devflow-{plan,implement,review,finalize}/SKILL.md` | no touch | They are the *subjects* of the check; they already satisfy it as of 4.8.1 |

---

### Task 1: Declare the contract artifact in the two contract documents

> **Risk:** 🟢 LOW

**Goal:** Both contract documents state, in one machine-readable line, which artifact their participant list governs.
**Context:** Spec → Data Structures. The `**<Verb> by:**` blocks already exist at the top of both files; the artifact path currently lives only in body prose.
**Constraints:** Do not alter the existing participant lines or their notes. The added line goes directly above the first `**<Verb> by:**` line.
**Acceptance criteria:** `grep -c '^\*\*Contract artifact:\*\*' ` returns 1 in each of the two files; `npm run validate` stays at 0 errors / 0 warnings.

**Deliverables:**
- Modify: `.agents/skills/shared/traceability-matrix.md` — `**Contract artifact:** \`docs/devflow/session/{slug}/traceability.md\``
- Modify: `.agents/skills/shared/metrics-template.md` — `**Contract artifact:** \`docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md\``

- [ ] **Commit checkpoint**
```bash
git add .agents/skills/shared/traceability-matrix.md .agents/skills/shared/metrics-template.md
git commit -m "docs(shared): declare the governed artifact on each multi-agent contract"
```

---

### Task 2: Implement §15 in the validator

> **Risk:** 🟡 MEDIUM — a check that passes everything gives false confidence. Its correctness is verified by Task 3's negative case, not by inspection.
> **Reference implementation:** `scripts/validate-framework.sh` §13 — same `header`/`fail`/`green` idiom, same guarded-directory shape.

**Goal:** §15 walks every declared contract and errors when a declared participant's `SKILL.md` doesn't reference the governed artifact.
**Context:** Spec → Architecture, Data Structures (agent map + token derivation rule).
**Constraints:** `set -euo pipefail` is active — every `grep` in a substitution or pipeline needs `|| true`. Do not modify §1–§14. Do not introduce a `SKILLS_DIR` env override.
**Acceptance criteria:**
- Running `npm run validate` on this branch reports §15 green, repository still 0 errors / 0 warnings.
- Reverting commit `bcf08fc` (the F60 fix) makes §15 emit an ERROR for `devflow-implement` and `devflow-review`.
- An unmapped agent name produces an ERROR, not a skip.

**Deliverables:**
- Modify: `scripts/validate-framework.sh` — new `── 15. Multi-agent contract integrity ──` section before the Summary block; usage header list extended with item 15.

**Implementation guide:**

```bash
# ── 15. Multi-agent contract integrity ───────────────────────────────────────
header "15. Multi-agent contract integrity"

# A shared/ document declares a contract by naming the artifact it governs plus
# the agents that touch it:
#
#   **Contract artifact:** `docs/devflow/session/{slug}/traceability.md`
#   **Written by:** Planner (...)
#   **Updated by:** Implementer (...)
#
# The 14 checks above are structural -- they never verify that a declared
# participant actually references the artifact. F60 is what that costs: the
# traceability chain of custody named four agents and two of them had zero
# mentions of the file, with every check green.

_contract_skill_dir() {
  case "$1" in
    Orchestrator) echo "devflow" ;;
    Planner)      echo "devflow-plan" ;;
    Implementer)  echo "devflow-implement" ;;
    Reviewer)     echo "devflow-review" ;;
    Finalizer)    echo "devflow-finalize" ;;
    Architect)    echo "devflow-architect" ;;
    Brainstormer) echo "devflow-brainstorm" ;;
    Debugger)     echo "devflow-debug" ;;
    *)            echo "" ;;
  esac
}

# basename minus the date/slug placeholders: the stable fragment an agent's
# SKILL.md would have to name. Guarded by a length floor so a short token
# can't match incidental prose.
_contract_token() {
  local t; t="$(basename "$1")"
  t="${t//YYYY-MM-DD/}"; t="${t//\{slug\}/}"; t="${t//\{date\}/}"
  t="${t#-}"; t="${t%-}"
  echo "$t"
}
# ... walk SHARED_DIR/*.md, parse, assert ...
```

- [ ] **Commit checkpoint**
```bash
git add scripts/validate-framework.sh
git commit -m "feat(validate): add multi-agent contract integrity check (§15)"
```

#### 🧪 Tests for this Task

Covered by Task 3 — written first (red), then this task turns them green.

---

### Task 3: Test suite for §15

> **Risk:** 🟢 LOW

**Goal:** `tests/validate-framework.bats` proves §15 catches the F60 shape, and keeps proving it.
**Context:** Spec → Test Architecture. Fixture trees under `BATS_TEST_TMPDIR`; the real script is invoked by absolute path after `cd` into the fixture, so `SKILLS_DIR`'s relative resolution points at the fixture with no production change. Assertions match §15's output lines, never the process exit code (other sections legitimately warn about the fixture's missing directories).
**Constraints:** Follow `tests/devflow-ctl.bats` conventions (`setup`/`teardown`, `run`, `[ "$status" -eq N ]` style where applicable).
**Acceptance criteria:** All 4 fixture cases pass; the negative case fails if §15 is deleted.

**Deliverables:**
- Create: `tests/validate-framework.bats`

**Run command:**
```bash
./node_modules/.bin/bats tests/validate-framework.bats
```

- [ ] **Commit checkpoint**
```bash
git add tests/validate-framework.bats
git commit -m "test(validate): cover the multi-agent contract integrity check"
```

> ⚠️ Task 3's tests MUST be written and run red before Task 2's section exists.

---

### Self-Review Checklist
- [x] All spec requirements are covered
- [x] Each task has Goal, Context, Constraints, Acceptance criteria, Deliverables
- [x] Each task has a commit checkpoint
- [x] Test section has happy path, edge case (unknown agent), failure scenario (missing participant)
- [x] Test section includes the exact run command
- [x] Dependencies between tasks are respected (1 → 3 red → 2 green)
- [x] No orphan files
- [x] Conventional Commits format
- [x] Rigor classified and set via `devflow-ctl config set rigor standard`
