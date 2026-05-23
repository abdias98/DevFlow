---
description: "API contract testing agent — validates endpoints against architecture spec, checks method/path/response/status/headers, generates contract tests, and reports discrepancies. Standalone agent. Never modifies code."
agent: workspace
---

# DevFlow — API Contract Testing

Run the Contract Agent to validate API endpoints against the spec contract.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-contract/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Load the API contract from the architecture spec.
2. Extract endpoints: method, path, request/response shapes, status codes, auth.
3. Analyze implementation against contract for each endpoint.
4. Generate contract tests (happy path, validation, auth, edge cases).
5. Analyze test results and classify discrepancies (🔴🟡🟢).
6. Save contract report to `docs/devflow/contracts/YYYY-MM-DD-{slug}-contract.md`.
7. Auto-invoke Reviewer in Standalone Mode.

**NEVER modify production code.** Only validate and report.

## API Contract or Context

${input}
