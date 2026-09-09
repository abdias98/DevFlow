# Standards Changelog

Version history for all DevFlow engineering standards. Each standard's current version is declared in its file header.

---

## 2.15.0 — 2026-09-09

### Changed — 2.15.0
- **`design-principles.md`** (v1.0.0 → v1.1.0): adds **§5 KISS — Keep It Simple**, the fifth transversal principle. Written to be genuinely distinct from its neighbours rather than a restatement of them: YAGNI (§2) governs *whether* to build a thing at all, KISS governs the *form* of what does get built — a required feature implemented through three layers of dynamic dispatch satisfies YAGNI and violates KISS. Judges simplicity by the cost of reading code cold, not by line count ("simple" is not "short" — a dense one-liner is the same complexity with the names removed), and separates essential complexity, inherent to the problem, from accidental complexity the solution introduced. Premature optimization is framed here as unjustified complexity, cross-linking `performance.md` §6 as the canonical owner of *how* to measure rather than restating its rules (per `standards-dry-policy.md`). Adds a checklist item, a WARN trigger (optimization with no profiling data or performance budget) and an INFO trigger (measurably more indirection than a simpler alternative, not yet causing harm), plus a Limited Scope constraint: simplifying code the task already changes is ordinary cleanup, rewriting an over-engineered module the task merely calls is a separate change that gets backlogged. Registered in `standards-quick-card.md` and `critical-friend.md`. §1-§4 were deliberately **not** renumbered — `event-driven-architecture.md` cites `design-principles.md` §2 and §4 in four places, and citation stability outweighs placing KISS next to YAGNI. Refs: F64.

## 2.14.0 — 2026-09-08

### New standards — 2.14.0
- **`event-driven-architecture.md`** (new, v1.0.0): the 16th standard — producers/consumers as a public contract, delivery guarantees (at-least-once by default; cross-links `concurrency.md` §5 for the idempotency mechanism this requires), event schema versioning, ordering (most transports don't guarantee it globally), dead-letter queues for poison messages, Event Sourcing vs. simple notification (pick the lightest pattern a stated requirement justifies), and CQRS (§7 — applied only with a concrete, current reason; explicitly flags the common failure mode of adopting it as a default "best practice" with no measured symptom driving it, cross-linking `design-principles.md` §2 YAGNI). Conditional standard ("apply only if the project uses events/queues/streams"), registered in `standards-quick-card.md` and `critical-friend.md`'s scan table alongside `rest-api.md`/`ui-design.md`. Linked from the agents that design or implement architecture (`devflow-architect`, `devflow-plan`, `devflow-implement`, `devflow-review`, `devflow-debug`, `devflow-perf`, and the standalone agents that already load `rest-api.md` conditionally). Was previously a single unexplained row in `project-design.md`'s pattern-selection table, with no actual rules — `project-design.md` (→ v2.3.1) now cross-links to it from that row instead of standing alone. Refs: F56, Wave 15.

## 2.13.0 — 2026-09-08

### New standards — 2.13.0
- **`design-principles.md`** (new, v1.0.0): DRY, YAGNI, Separation of Concerns, and Technology Agnosticism — the 4 transversal design principles that apply to every DevFlow cycle (lifecycle and standalone alike), unconditional on stack or feature type, unlike domain-specific standards. Registered as "Always — every request" in `standards-quick-card.md` and `critical-friend.md`'s scan table, and linked from every agent that writes or reviews code (10 standalone agents + `devflow-implement`, `devflow-plan`, `devflow-architect`, `devflow-review`, `devflow-debug`). Not linked from the 3 purely documentation-producing standalone agents (`devflow-docs`, `devflow-templates`, `devflow-tutorial`), which write no production code these principles apply to. Refs: F54, Wave 15.

## 2.12.0 — 2026-09-08

### Updated standards — 2.12.0
- **`logging.md`** (→ v1.3.0): new `## 5. Business/Audit Event Logging` — distinguishes business/audit events (what happened, to whom, when — for traceability and compliance) from technical/diagnostic logs. Requires logging successes as well as failures, keeping audit events independent of the general verbosity level, and append-only storage when the domain needs non-repudiation. Sections after it renumbered (Error Logging §6, Performance & Volume §7, Log Management §8, Code Review Checklist §9, Severity Classification §10, Limited Scope §11). Updated the 2 external citations to `logging.md §5` (now §6) in `error-handling.md` (→ v1.2.2) and `devflow-review/review-checklist.md`. Refs: F52, Wave 15.

## 2.11.1 — 2026-09-08

### Updated standards — 2.11.1
- **`testing.md`** (→ v1.3.0): §1 (Test Pyramid) now explicitly recognizes concurrency/load tests as orthogonal to the unit/integration/E2E pyramid, cross-linking `concurrency.md` §2 — a feature with a business-critical concurrency invariant needs this test budgeted separately, not treated as already covered by pyramid counts. Refs: F51, Wave 15.

## 2.11.0 — 2026-09-08

### Updated standards — 2.11.0
- **`concurrency.md`** (→ v1.3.0): §2 now requires empirical evidence for business-critical atomicity fixes (inventory, balance, unique allocation) — a sequential unit test is explicitly not sufficient; a real concurrency test (simultaneous operations racing for the same contended resource) is required. Reflected in the Code Review Checklist (§8, new item) and Severity Classification (§9, new WARN trigger). Found during the Wave 15 validation run: two full `/devflow` cycles both produced the correct fix, but nothing in the framework *required* the concurrency test that proved it — it existed only because the Planner chose to add one. Refs: F48, Wave 15.

## 2.10.2 — 2026-09-07

### Updated standards — 2.10.2
- **`security.md`** (→ v2.4.2), **`accessibility.md`** (→ v1.2.2), **`concurrency.md`** (→ v1.2.1), **`rest-api.md`** (→ v2.3.2), **`testing.md`** (→ v1.2.2), **`clean-architecture.md`** (→ v2.3.2): reworded 9 Severity-table triggers so each shares a real term with the section body it cites, closing the last warnings from the §12 lightweight semantic citation check (validate-framework.sh) — required for the plan's global Definition of Done (0 errors and 0 warnings on the final tree). No normative change; wording only. Part of the 4.6.0 release.

## 2.10.1 — 2026-09-07

### Updated standards — 2.10.1
- **`security.md`** (→ v2.4.1): §6 now names `error-handling.md §5` as the canonical citation for "stack trace exposed to an external caller"; §6 is the security-angle cross-reference only, avoiding the same finding logged under two section numbers.
- **`error-handling.md`** (→ v1.2.1): §5's Blocker note reciprocates — this section is canonical, `security.md §6` cross-references it.
- **`dependencies.md`** (→ v1.2.1): intro now states it owns the supply-chain depth (OWASP A08); `security.md` §5 covers the same topic at security-scan depth and links back.
- **`performance.md`** (→ v2.3.2): §4 now declares `concurrency.md` §4 the owner of fire-and-forget error handling and sync-over-async correctness hazards; performance.md keeps the throughput angle and links instead of duplicating the rule. Severity table's fire-and-forget BLOCK trigger now cites `concurrency.md §4` as canonical; `standards-quick-card.md`'s matching row updated to match.
- **`clean-architecture.md`** (→ v2.3.1) / **`testing.md`** (→ v1.2.1): §5 (Testing Requirements) and testing.md's intro now cross-link — clean-architecture.md owns per-layer architectural testability, testing.md owns test design depth (AAA, mocking, coverage).

Refs: F17, Wave 13.

## 2.10.0 — 2026-09-07

### Updated standards — 2.10.0
- **`security.md`** (→ v2.4.0): new `## 8. Additional OWASP Top 10 (2021) Coverage` — CSRF (tokens/`SameSite`), insecure deserialization, mass assignment/over-posting, and Insecure Design (A04, threat-modeling tie to the Validation Gate). §5 (Dependency Security) now cross-references `dependencies.md` as the standard that owns A08's supply-chain depth. Sections after the new one renumbered: Security Interactions §9, Code Review Checklist §10, Severity Classification §11, Limited Scope §12. New red flags registered in `standards-quick-card.md`.
- `devflow-reverse/SKILL.md` Step 8b and `reverse-template.md`'s Vulnerability Findings table: OWASP taxonomy updated from the 2017 list (Injection, Broken Auth, Sensitive Data Exposure, XXE, ...) to OWASP Top 10 (2021) A01–A10. Refs: F18, Wave 13.

## 2.9.5 — 2026-09-07

### Updated standards — 2.9.5
- **`rest-api.md`** (→ v2.3.1): added a precedence note to §4 (Response Structure) — RFC 9457 Problem Details (§7) governs error response bodies whenever adopted, prevailing over the success envelope's `errors` field; the two sections previously read as contradictory. Unified the nested-path threshold: §1's "more than 2–3 levels" and the Severity table's ">3 levels" now both read ">3 levels".
- **`accessibility.md`** (→ v1.2.1) / **`ui-design.md`** (→ v2.4.2): fixed a contradictory touch-target threshold — accessibility.md §7 now states the WCAG 2.2 AA floor (**24×24 CSS px**, 2.5.8) as the required minimum and the AAA recommendation (**44×44 CSS px**, 2.5.5, already ui-design.md's own default) as a separate, non-blocking preference. Both standards' Severity tables split the single "below 44×44" WARN into a 24×24 WARN (AA violation) and a 44×44 INFO (AAA gap). Refs: F25, F26, Wave 13.

## 2.9.4 — 2026-09-07

### Updated standards — 2.9.4
- **`testing.md`** (→ v1.2.0): new `## 9. The TDD Cycle (Red → Green → Refactor)` — what a valid Red is (fails for the right reason, not a plumbing error), what a minimal Green is, when to refactor, and the rule that a Green is never committed without a confirmed PASS. Code Review Checklist, Severity Classification, and Limited Scope renumbered to §10/§11/§12. `devflow-implement/tdd-procedure.md` now references this section as the standard it executes. Refs: F34, Wave 13.

## 2.9.3 — 2026-09-07

### Updated standards — 2.9.3
- **`logging.md`, `error-handling.md`, `concurrency.md`, `dependencies.md`, `accessibility.md`** (each → v1.2.0): gained a `Code Review Checklist` section (renumbering Severity Classification and Limited Scope by one), bringing all 14 standards to structural parity (Code Review Checklist + Severity Classification + Limited Scope). `git-conventions.md`'s Limited Scope gap was already closed in v2.9.0 — not repeated here.
- `devflow-review/review-checklist.md` gained matching **Error Handling**, **Concurrency**, **Logging**, **Dependencies** (Universal Checks) and **Accessibility** (UI-Specific) sections — the checklist sections `devflow-review/SKILL.md`'s subagent-3 dimension already assigned but that didn't exist in the file. Refs: F15, Wave 13.

## 2.9.2 — 2026-09-07

### Updated standards — 2.9.2
- **`performance.md`** (→ v2.3.1): Severity table's unbounded-collection BLOCK trigger cited `(§2, §6)`; §6 is *Measure Before Optimizing*, unrelated to pagination — corrected to `(§2)`.
- **`ui-design.md`** (→ v2.4.1): 4 stale citations in the Severity Classification table pointed at sections that no longer hold that content (renumbered by earlier standard restructuring): design-token citations `§4` → `§13` (Design Tokens & Consistency), responsive-behavior citation `§9` → `§3` (Visual Foundation), virtualization citation `§15` → `§11` (Performance). Refs: F16, Wave 13.

## 2.9.1 — 2026-09-07

### Updated standards — 2.9.1
- **`security.md`** (→ v2.3.1): fixed a duplicate `## 10.` — *Severity Classification* keeps §10, *Applying This Standard with a Limited Scope* is renumbered to §11. `security.md` is the most-cited standard in the framework; every `security.md §10` citation was ambiguous before this fix (a repo-wide sweep found none actually pointing at the scope block). Refs: F14, Wave 13.

## 2.9.0 — 2026-09-07

### Updated standards — 2.9.0
- **All 14 standards** (`accessibility.md` → v1.1.0, `clean-architecture.md` → v2.3.0, `concurrency.md` → v1.1.0, `dependencies.md` → v1.1.0, `error-handling.md` → v1.1.0, `git-conventions.md` → v1.1.0, `logging.md` → v1.1.0, `performance.md` → v2.3.0, `project-design.md` → v2.3.0, `rest-api.md` → v2.3.0, `security.md` → v2.3.0, `solid.md` → v2.3.0, `testing.md` → v1.1.0, `ui-design.md` → v2.4.0): "Applying This Standard with a Limited Scope" rewritten to align with the three-zone scope model (`rules.md` → Scope-Locking — Three Zones). Violations outside Core no longer default to a silent TODO/INFO comment; a fix in the Impact Zone with a closed coherence reason gets applied and recorded with `devflow-ctl scope justify`, everything else is deferred with `devflow-ctl backlog add` at `incomplete` or `info` severity. `git-conventions.md` gained a Limited Scope section (§8) for the first time, bringing all 14 standards to parity. Refs: F42, Wave 12.

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
