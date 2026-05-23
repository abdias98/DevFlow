---
description: "Reverse engineering agent — analyzes undocumented projects and generates AGENTS.md, Stack Profile, Architecture Spec, Dependency Graph, and Project Template. Read-only. Never modifies source code. Use --quick for fast mode, --deep for full tech debt analysis."
agent: workspace
---

# DevFlow — Reverse Engineering

Run the Reverse Agent to analyze an undocumented project.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-reverse/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Select mode: Quick (~5 min), Full (~15 min), Deep (~30 min), Update.
2. Explore project structure, detect tech stack, analyze architecture.
3. Generate AGENTS.md with all discovered conventions.
4. Discover API endpoints, map dependencies (Full + Deep).
5. Detect tech debt and vulnerabilities (Deep only).
6. Save all artifacts: AGENTS.md, Architecture Spec, Project Template.
7. Auto-invoke Reviewer in Standalone Mode.

**NEVER modify source code.** Read-only analysis.

## Project or Context

${input}
