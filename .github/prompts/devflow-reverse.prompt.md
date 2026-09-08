---
description: "Reverse-engineering agent — analyzes undocumented or legacy projects to discover their architecture, tech stack, dependencies, API endpoints, and technical debt. Produces AGENTS.md, Stack Profile, Architecture Spec, and Project Template. Read-only, standalone agent. Never modifies source code."
agent: workspace
---

# DevFlow — Reverse Engineering

Run the Reverse Engineering Agent to discover and document an undocumented or legacy codebase.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-reverse/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Select mode: `--quick` (AGENTS.md + Stack Profile), full (default, +Architecture Spec + Project Template), or `--deep` (+Technical Debt + Vulnerability Audit).
2. Explore project structure and detect the tech stack.
3. Analyze the architecture — layers, patterns, data flow.
4. Generate `AGENTS.md` documenting conventions for future agents.
5. *(Full + Deep)* Discover API endpoints and map dependencies.
6. *(Deep)* Detect technical debt and scan for OWASP Top 10 (2021) vulnerability patterns.
7. *(Full + Deep)* Generate the Architecture Spec and Project Template.
8. Save the reverse-engineering report to `docs/devflow/reverse/YYYY-MM-DD-{slug}-reverse.md`.
9. Auto-invoke Reviewer in Standalone Mode.

**NEVER modify source code.** Read-only analysis — only documentation artifacts are produced.

## Project or Context

${input}
