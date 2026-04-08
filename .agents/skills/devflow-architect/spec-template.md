# Spec Document Template

The spec document saved to `docs/devflow/specs/YYYY-MM-DD-{slug}-design.md` MUST include these sections:

## Required Sections

### Context
Business problem and why the feature exists.

### Architecture
High-level system design with data flow. Components, data structures, interfaces, and how data moves through layers.

### Data Structures
Complete definitions using the detected stack's terminology and naming conventions. Include code snippets.

### Reusability Decisions

| Existing component | Current purpose | Reusable for | Decision | Justification |
|--------------------|-----------------|--------------|----------|---------------|

### Test Architecture

| Layer/Area | Test types used | Tool | Available utilities | Reference test |
|------------|-----------------|------|---------------------|----------------|

### UI Mockups *(if frontend feature)*
ASCII wireframes with component annotations using the detected stack's syntax. Include: default state, loading state, error state, empty state.

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
