# Standards Changelog

Version history for all DevFlow engineering standards. Each standard's current version is declared in its file header.

---

## 2.8.0 — 2026-06-15

### New standards — 2.8.0
- **`accessibility.md`** (new, v1.0.0): Accessibility (a11y) standard — extracted from `ui-design.md §10` into its own first-class standard. Covers Perceivable (text alternatives, no color-only meaning), color contrast (WCAG AA), keyboard operability, visible focus, semantics & ARIA (native-first, no `aria-hidden` on focusable elements), forms & errors, and dynamic content & motion (reduced-motion, 200% zoom, target size), with a Severity Classification and limited-scope guidance. Registered in `standards-quick-card.md`, the Critical Friend scan table, and linked from the Architect and the standalone agents' UI-conditional standard set. Part of Wave 3.

### Updated standards — 2.8.0
- **`ui-design.md`** (→ v2.3.0): §10 Accessibility is now a brief pointer to the dedicated `accessibility.md` (essentials retained, full rules moved). §16 Severity Classification accessibility triggers now cite `accessibility.md` (previously an incorrect `§8` self-reference); the touch-target trigger also points to `accessibility.md §7`.

---

## 2.7.0 — 2026-06-15

### New standards — 2.7.0
- **`dependencies.md`** (new, v1.0.0): Dependency Management & Supply Chain standard — minimize the dependency surface, pin versions & commit lockfiles, **vulnerability auditing** (critical/high = release blocker — backs the Finalizer's `Audit Command`), integrity & source trust (typosquatting/dependency confusion), license compliance, deliberate updates, and transitive footprint, with a Severity Classification and limited-scope guidance. Registered in `standards-quick-card.md`, the Critical Friend scan table, and linked from the Architect and the standalone agents' loadable standard set. Part of Wave 3.

---

## 2.6.0 — 2026-06-15

### New standards — 2.6.0
- **`concurrency.md`** (new, v1.0.0): Concurrency & Async standard — shared mutable state, atomicity & race conditions, locking discipline (deadlock avoidance), async discipline (no data-loss fire-and-forget, no sync-over-async), idempotency under at-least-once delivery, safe publication & memory visibility, background-task lifecycle, Severity Classification, and limited-scope guidance. Registered in `standards-quick-card.md`, the Critical Friend scan table, and linked from the Architect and the standalone agents' loadable standard set. Part of Wave 3.

---

## 2.5.0 — 2026-06-15

### New standards — 2.5.0
- **`error-handling.md`** (new, v1.0.0): Error Handling standard — fail fast, **never swallow errors**, catch specifically & preserve cause, translate at layer boundaries, **safe error surfaces** (no internal leaks to callers), resource cleanup & consistency, errors vs. control flow, retries & idempotency, Severity Classification, and limited-scope guidance. Complements `logging.md` (how errors are recorded). Registered in `standards-quick-card.md`, the Critical Friend scan table, and linked from the Architect and the standalone agents' loadable standard set. Part of Wave 3.

---

## 2.4.0 — 2026-06-15

### New standards — 2.4.0
- **`logging.md`** (new, v1.0.0): Logging & Observability standard — structured logging, log levels, sensitive-data redaction (no secrets/PII in logs), correlation/trace context, error logging (no silent swallowing), performance & volume, log management, Severity Classification, and limited-scope guidance. Registered in `standards-quick-card.md` and linked from the Architect and the standalone agents' loadable standard set. Part of Wave 3 of the framework improvement roadmap.

---

## 2.3.0 — 2026-06-10

### New standards — 2.3.0
- **`testing.md`** (new): Full testing standard with Test Pyramid, Arrange/Act/Assert, mock policy, coverage, regression tests, independence, naming, performance, checklist, Severity Classification, and scope guidance. Covers the TDD requirement that was previously undocumented.
- **`git-conventions.md`** (new): Conventional Commits format, branch naming policy, DevFlow commit checkpoints, PR rules, tagging, checklist, and Severity Classification. Replaces hardcoded commit formats scattered across skill files.

### Updated standards — 2.3.0
- **`security.md`**: Added password hashing (Argon2id/bcrypt), JWT pitfalls (`alg:none`, short expiry, no sensitive payload), and MFA guidance (§7).
- **`rest-api.md`**: Error format now recommends RFC 9457 Problem Details (`application/problem+json`) as the preferred format, with a fallback custom envelope (§7).

### Shared framework files — 2.3.0
- **`standards-quick-card.md`** (new): Fast-scan BLOCK-only reference card for the Critical Friend check. Agents load this first; if a red flag matches, they load the full standard. Reduces context consumption.
- **`critical-friend.md`**: Check 1 now references the quick card and adds `testing.md` to the standards table.
- **`devflow/SKILL.md`**: Validation Gate (Step 2) now archives report to `docs/devflow/validations/` immediately and records accepted risks with timestamp. Step 0 checkpoint (`git rev-parse HEAD`) is now auto-executed (read-only, safe in all modes) instead of asking the user.
- **`devflow-finalize/SKILL.md`**: Step 5 renamed to "Archive & Clean Session Memory". Added safeguard: Finalizer checks for archived validation report before deleting session copy.
- **`scripts/validate-framework.sh`** (new): Framework self-validation script. Checks: template variable integrity, broken cross-references, required SKILL.md sections, unreferenced shared files, version headers, Critical Friend step in standalone agents, artifact path consistency. Run with `npm run validate`.
- **`package.json`**: Added `validate` and `validate:fix` scripts.

---

## 2.2.0 — 2026-06-10

### All standards — 2.2.0
Added **Severity Classification** section to all 7 standards:

- Each standard now declares which violations are 🔴 BLOCK, 🟡 WARN, or 🟢 INFO.
- Severity tables cite specific section numbers so agents can reference them deterministically.
- Replaces discrecional judgment for the Reviewer and Validation Gate with explicit triggers.
- Standards updated: `solid`, `clean-architecture`, `security`, `performance`, `rest-api`, `project-design`, `ui-design`.

### shared — 2.2.0 (framework files)
- **`critical-friend.md`** (new): Shared step-by-step Critical Friend procedure for standalone agents. Includes 4 checks, output format with standard citations, and severity routing.
- **`rules.md`**: Fixed "NEVER auto-run tests" contradiction — now explicitly scoped to Pair mode and standalone agents (Standard mode and CI mode exceptions documented). Updated Critical Friend Principle to require standard citation per finding. Added reference to `critical-friend.md`.
- **`memory-conventions.md`**: Clarified lock scope — lock is per-cycle (Orchestrator), not per-agent; sub-agents in the same cycle do not need to re-acquire.
- **`artifact-checklist.md`**: Added explicit BLOCK and WARN trigger tables to Validation Gate section. "At least one assumption challenged" now allows "no fragile assumptions — justification: …" to prevent invented challenges. Added validation report archival path (`docs/devflow/validations/`).
- **`devflow/SKILL.md`**: Fixed duplicate iteration loop rows (merged into one 5↔6 row). Added Phase 4 gap explanation note. Added CI mode exception: BLOCK findings from Validation Gate fail the CI pipeline (not auto-accepted).
- **`devflow-refactor/SKILL.md`**: Added Step 1.5 (Critical Friend Check).
- **`devflow-perf/SKILL.md`**: Added Step 1.5 (Critical Friend Check).
- **`devflow-debug/SKILL.md`**: Added Step 1.5 (Critical Friend Check).
- **`devflow-migrate/SKILL.md`**: Added Step 1.5 (Critical Friend Check).

---

## 2.1.0 — 2026-05-22

### ui-design — 2.1.0
- Comprehensive expansion: 108 → 348 lines
- Added detailed design principles, interaction patterns, and trade-off analysis
- Enhanced checklist with accessibility and responsive design criteria

---

## 2.0.0 — 2026-04-29

### All standards — 2.0.0
Complete technology-agnostic rewrite across all 7 standards:

- **solid:** Generic pseudo-code examples, SOLID interactions & tensions, code review checklist, limited scope section
- **clean-architecture:** Technology-agnostic examples, dependency rule clarified, limited scope section
- **security:** Transport security, data protection at rest, rate limiting added, checklist, limited scope section
- **performance:** Async/resource/caching interactions, checklist, limited scope section
- **rest-api:** Idempotency, documentation, security & safety, checklist, limited scope section
- **project-design:** Architecture Spec documentation, checklist, limited scope section
- **ui-design:** Interactions & trade-offs, checklist, limited scope section

---

## 1.0.0 — 2026-04-20

### Initial release
- 7 standards created: SOLID, Clean Architecture, Security, Performance, REST API, Project Design, UI Design
- Strict DO/DON'T format
- Private Library approach: standards loaded exclusively by DevFlow agents
- Original technology-specific examples (later rewritten in 2.0.0)

---

## Version Policy

- **Major (X.0.0):** Breaking changes to standard rules or structure
- **Minor (X.Y.0):** New sections, expanded coverage, significant additions
- **Patch (X.Y.Z):** Clarifications, typo fixes, non-semantic adjustments
- Each standard may version independently when only one standard changes.
- All standards share a major version bump when a framework-wide rewrite occurs.
