# Artifact Validation Checklist

Every DevFlow artifact MUST be validated against its template before being saved. The agent that produces the artifact runs this checklist as a final step before calling `create_file`.

## Validation Gate (`docs/devflow/session/{slug}/validation-report.md`)

Validated by: **Orchestrator** (before Step 3 — Architect)

- [ ] **Goal & Constraints Review** — goal is achievable within stated constraints
- [ ] **Standards Scan** — checked against SOLID, Clean Architecture, Security, Performance, REST API (if applicable), UI Design (if applicable). Each finding cites `{standard}.md §{N} → {BLOCK|WARN|INFO}`
- [ ] **Assumptions Challenged** — all fragile or unverified assumptions questioned. If no fragile assumptions exist, state "No fragile assumptions — justification: {reason}" (do NOT invent challenges)
- [ ] **Contradictions Flagged** — any internal contradictions in requirements surfaced
- [ ] **Security Scan** — potential vulnerabilities identified (input validation, auth, injection, secrets). Any finding matching the BLOCK triggers below raises a BLOCK immediately
- [ ] **Architecture Risks** — architectural concerns or scope risks documented
- [ ] **Alternatives Proposed** — better approaches suggested when applicable. If none, state "No better alternative identified — justification: {reason}"
- [ ] **Recommendations** — Additional Recommendations section populated with out-of-scope improvements
- [ ] **Validation Report saved** — report at `docs/devflow/session/{slug}/validation-report.md`
- [ ] **Validation Report archived** — copy saved to `docs/devflow/validations/YYYY-MM-DD-{slug}-validation.md` (persists beyond session cleanup)

### Validation Gate — Explicit BLOCK Triggers

The following conditions ALWAYS raise a 🔴 BLOCK regardless of user intent. They must be resolved or explicitly accepted before proceeding:

| Trigger | Standard Reference |
|---------|-------------------|
| Request includes hardcoded secrets, API keys, or credentials | security.md §3 |
| Request asks to roll custom authentication or cryptography | security.md §2 |
| Request would expose unvalidated external input to system commands, SQL, or shell | security.md §1, §4 |
| Request violates the Dependency Rule (infrastructure code in domain/use-case layer) | clean-architecture.md §1 |
| Internal contradiction — two requirements that cannot both be satisfied | (internal) |
| Request requires storing sensitive tokens in client-accessible browser storage | security.md §2 |
| Request asks for SQL or DB queries inside Use Cases or Domain Entities | clean-architecture.md §2 |
| No authentication on an endpoint that modifies or exposes private data | security.md §2 |

### Validation Gate — WARN Triggers

| Trigger | Standard Reference |
|---------|-------------------|
| Missing pagination on a collection endpoint | performance.md §2, rest-api.md §6 |
| Synchronous I/O where async is available | performance.md §4 |
| God class / god object in design | solid.md §1, project-design.md §3 |
| Pattern inconsistency with existing project structure | project-design.md §1 |
| REST verb misuse (e.g., GET for state change) | rest-api.md §2 |
| Missing error response structure | rest-api.md §7 |

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
- [ ] **Rigor** level stated — `light | standard | deep | maximum`
- [ ] **File Map** section present — Modify: + Create: lists
- [ ] **At least 1 task** defined with numbered title
- [ ] **Each task is a work packet** — has **Goal**, **Context**, **Constraints**, **Acceptance criteria**, and **Deliverables**
- [ ] **Each task has an Implementation guide** with complete code snippets
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
