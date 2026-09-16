# Spec Document Template

The spec document saved to `docs/devflow/specs/YYYY-MM-DD-{slug}-design.md` MUST include these sections:

## Required Sections

### Spec Digest

> **Purpose:** a 10-20 line structured summary that downstream agents (Planner, Implementer, Reviewer) read FIRST. If the digest answers their questions, they skip reading the full spec. If it raises questions, they read the specific full section. Saves ~60-80% of spec read cost.

```markdown
## Spec Digest
- **Components:** {list of new/modified components}
- **Data flow:** {Request → Middleware → Service → Repository → DB}
- **Key decisions:** {2-3 most important design decisions with one-line rationale}
- **Risk:** {HIGH/MEDIUM/LOW — one-line summary}
- **Test strategy:** {unit/integration/e2e — one line}
- **API changes:** {endpoints added/modified, or "none"}
- **UI changes:** {components added/modified, or "none"}
- **Stateful units:** {units in the State & Interaction Matrix, or "none — stateless"}
```

### Context
Business problem and why the feature exists.

### Architecture
High-level system design with data flow. Components, data structures, interfaces, and how data moves through layers.

### Data Structures
Complete definitions using the detected stack's terminology and naming conventions. Include code snippets.

### Reusability Decisions

| Existing component | Current purpose | Reusable for | Decision | Justification |
|--------------------|-----------------|--------------|----------|---------------|

### Impact Analysis

From `devflow-ctl scope impact` (exploration-guide.md sub-step 9) — one row per existing component the design modifies:

| Component | Dependents (who calls it) | Likely coherence change needed? | Notes |
|-----------|---------------------------|----------------------------------|-------|

If the design introduces no changes to existing files, state "N/A — no existing components modified" instead of an empty table.

### Concurrency Strategy *(if `concurrency.md` applies — shared mutable state, race-prone operations, background/async work)*

The mechanism chosen to make the critical invariant(s) safe under concurrent access, stated explicitly rather than left implicit in the code:

| Invariant to protect | Mechanism (lock / conditional-update / queue / actor / other) | Why this one, not the alternatives | Failure mode if violated |
|-----------------------|------------------------------------------------------------|-------------------------------------|---------------------------|

Per `concurrency.md` §2: prefer a conditional/compare-and-set update at the data-store level over an in-process lock whenever the invariant must hold across multiple processes/workers — an in-memory lock only protects a single process. State which one applies here and why. This decision flows into Test Architecture below: a critical concurrency invariant requires a real concurrency test (see `concurrency.md` §2), not only a sequential unit test.

If the feature has no shared mutable state or race-prone operation, state "N/A — no concurrency-sensitive invariant" instead of an empty table.

### State & Interaction Matrix

**Required.** For every stateful unit the design adds or changes (UI component or view with state, service/store holding state, workflow or state machine, job, consumer, cache): states × events → observable expected result, each row with its source (DoD, Edge Case, Behavior Scenario from `context.md`, spec section, or existing convention). Cover the normal transitions and every [Transition Prompt](<{{SKILLS_DIR}}/shared/behavior-scenarios.md>) the unit can exhibit — change while in flight, repetition, order, interruption, partial failure, reset vs keep, other actors.

| # | Unit | State (before) | Event | Expected result | Source |
|---|------|----------------|-------|-----------------|--------|

If the design has no stateful unit, write exactly `N/A — stateless: {one-line reason}`. An empty section fails `devflow-ctl artifacts check spec`.

### Test Architecture

| Layer/Area | Test types used | Tool | Available utilities | Reference test |
|------------|-----------------|------|---------------------|----------------|

### UI Mockups *(if frontend feature)*
ASCII wireframes with component annotations using the detected stack's syntax. Include: default state, loading state, error state, empty state — plus every state the State & Interaction Matrix defines for the component (e.g., the state shown while a new selection loads, or after a failure following a success).

### API Contract *(if backend/API feature)*

**REST endpoint template:**

| Field | Value |
|-------|-------|
| Method | {HTTP verb} |
| Path | /api/v{version}/{resource} |
| Auth | {detect from project} |

Request body, response body, error responses (400, 401, 403, 404, 409, 422, 500).

**GraphQL** *(if project uses GraphQL)*: operation name, input variables, returned fields.

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| {description} | 🔴 HIGH / 🟡 MEDIUM / 🟢 LOW | {how to reduce it} |

### Rollback Strategy *(for HIGH-risk changes)*
Steps to undo migration/revert API, restore previous behavior, verify rollback succeeded.

### Performance Budget *(if performance-sensitive)*

| Metric | Target | Current Baseline |
|--------|--------|------------------|

### Design Decisions

| Decision | Alternatives | Reasoning |
|----------|-------------|-----------|

### Constraints
Technical or business limitations.

## Auth Detection

Detect from the project — never assume:
- Laravel Sanctum (token/web mode)
- Passport, next-auth, Clerk, Auth0, Supabase Auth
- API Key header/query param
- No auth → state explicitly
