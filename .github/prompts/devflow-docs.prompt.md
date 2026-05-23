---
description: "Documentation agent — generates and maintains project documentation (README, API docs, CHANGELOG, architecture) from accumulated DevFlow artifacts. Standalone agent. Never modifies source code."
agent: workspace
---

# DevFlow — Documentation Generation

Run the Documentation Agent to generate project docs from DevFlow artifacts.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-docs/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Scan `docs/devflow/` for existing artifacts (specs, plans, reviews, summaries).
2. Determine documentation scope (README, API, CHANGELOG, Architecture).
3. Load stack profile to understand tech stack.
4. Generate documentation files, merging with existing content.
5. Save documentation report to `docs/devflow/documentation/YYYY-MM-DD-{slug}-docs.md`.
6. Auto-invoke Reviewer in Standalone Mode.

**NEVER modify source code.** Only documentation files.

## Scope or Context

${input}
