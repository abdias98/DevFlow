---
description: "Perform automated code review against the spec and plan. Check quality, security, performance. Classify findings as BLOCK/WARN/INFO. Phase 5 of the DevFlow lifecycle."
agent: devflow
---

# DevFlow — Review Phase

Run ONLY the Reviewer phase of the DevFlow lifecycle.

## Instructions

Invoke the `devflow-reviewer` skill to:

1. Load context from session memory (spec path, plan path, test results)
2. Get the git diff of implemented changes
3. Read each changed file completely
4. Apply the review checklist: code quality, security (OWASP), architecture alignment, plan compliance, test coverage, performance
5. Classify findings: BLOCK (must fix), WARN (should fix), INFO (optional)
6. Save review to `docs/devflow/reviews/YYYY-MM-DD-{slug}-review.md`
7. If BLOCK findings → route back to Implementer

Read session memory first (`/memories/session/devflow/`).

## Scope to Review

${input}
