# Artifact Validation Checklist

Every DevFlow artifact MUST be validated against its template before being saved. The agent that produces the artifact runs this checklist as a final step before calling `create_file`.

## Validation Gate (`docs/devflow/session/{slug}/validation-report.md`)

Validated by: **Validator** (before Step 2 — Architect)

- [ ] **Goal & Constraints Review** — goal is achievable within stated constraints
- [ ] **Standards Scan** — checked against SOLID, Clean Architecture, Security, Performance, REST API (if applicable), UI Design (if applicable)
- [ ] **Assumptions Challenged** — at least one assumption questioned with alternative proposed
- [ ] **Contradictions Flagged** — any internal contradictions in requirements surfaced
- [ ] **Security Scan** — potential vulnerabilities identified (input validation, auth, injection, secrets)
- [ ] **Architecture Risks** — architectural concerns or scope risks documented
- [ ] **Alternatives Proposed** — at least one better approach suggested if applicable
- [ ] **Recommendations** — Additional Recommendations section populated with out-of-scope improvements
- [ ] **Validation Report saved** — report at `docs/devflow/session/{slug}/validation-report.md`

## Spec Document (`docs/devflow/specs/*.md`)

Validated by: **Architect** (before Step 5 — save)

- [ ] **Context** section present — explains the business problem
- [ ] **Architecture** section present — high-level design with data flow
- [ ] **Data Structures** section present — definitions with code snippets (stack-specific terminology)
- [ ] **Reusability Decisions** table present — at least 1 row (can be "None — new component")
- [ ] **Test Architecture** table present — layers, tools, utilities, reference tests
- [ ] **Risk Assessment** table present — at least 1 risk identified (can be LOW)
- [ ] **Design Decisions** table present — key decisions with alternatives and reasoning
- [ ] **Constraints** section present — technical or business limitations
- [ ] **UI Mockups** section present (if frontend/UI feature)
- [ ] **API Contract** section present (if backend/API feature)
- [ ] **Auth Detection** section present — mechanism detected or explicitly stated "No auth"

## Plan Document (`docs/devflow/plans/*.md`)

Validated by: **Planner** (before Step 8 — persist)

- [ ] **Goal** stated — one-sentence summary
- [ ] **Architecture reference** — path to spec document
- [ ] **File Map** section present — Modify: + Create: lists
- [ ] **At least 1 task** defined with numbered title
- [ ] **Each task has commit checkpoint** — `git commit -m "..."` message
- [ ] **Each task has test code** — `🧪 Tests for this Task` with complete, runnable code
- [ ] **Each test has happy path, edge case, and failure scenario**
- [ ] **Each test includes run command** — exact `{Test Command (single file)}` syntax
- [ ] **Self-Review Checklist** present — all items checked
- [ ] **Mockup paths** listed (if UI feature)
- [ ] **Stack Plan** table present (if Stack Mode = yes)
- [ ] **Task dependencies** respected — no forward references

## Review Document (`docs/devflow/reviews/*.md`)

Validated by: **Reviewer** (before Step 4 — save)

- [ ] **Summary** section present — 1-2 sentence overall assessment
- [ ] **Findings** section present with severity classification
- [ ] **🔴 BLOCK** section — even if empty (state "None")
- [ ] **🟡 WARN** section — even if empty (state "None")
- [ ] **🟢 INFO** section — even if empty (state "None")
- [ ] **Every finding has file + line reference** — no vague "somewhere in X"
- [ ] **Every BLOCK finding has a specific suggestion** — actionable fix
- [ ] **Verdict** section present — ✅ APPROVED or 🔄 CHANGES REQUESTED with blocker count
- [ ] **Review Mode** declared — Cycle or Standalone
- [ ] **Reference artifact** path present — spec, plan, feature, refactor, or bug-fix document

## Traceability Matrix (`docs/devflow/session/{slug}/traceability.md`)

Validated by: **Planner** (after generation), **Orchestrator** (Step 8 entry)

- [ ] **All DoD criteria** have at least 1 row
- [ ] **All Edge Cases** have at least 1 row
- [ ] **Each row has** Source, Requirement, Task, Test File, Test Scenario
- [ ] **Coverage Summary** computed — totals per source
- [ ] **Uncovered Items** table — lists items with 0% coverage + justification

## Validation Rules

1. **Run BEFORE saving.** The agent producing the artifact validates before `create_file`.
2. **Missing required sections = BLOCK.** Do not save an incomplete artifact.
3. **Conditional sections** (UI, API, Stack Mode) are only required when the feature type matches.
4. **Empty tables are acceptable** for non-applicable sections (e.g., "No existing reusable components") — but the section must exist.
5. **The Orchestrator re-validates** at phase transitions: verify the artifact from the previous phase has all required sections before proceeding.
