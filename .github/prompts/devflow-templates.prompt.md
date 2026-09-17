---
description: "Template agent — generates and maintains project-specific architecture templates from accumulated DevFlow artifacts and pre-defined reference guides. Speeds up future cycles by reusing discovered patterns. Standalone agent."
agent: workspace
---

# DevFlow — Project Templates

Run the Template Agent to generate project-specific architecture templates.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-templates/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Discover project patterns from accumulated DevFlow artifacts.
2. Determine project type (API REST, Frontend, Fullstack, CLI, Library, Mobile).
3. Load matching pre-defined reference template from `shared/templates/`.
4. Generate `docs/devflow/templates/project-architecture.md` from real patterns.
5. Auto-invoke Reviewer in Standalone Mode.

With `standards-profile`: generate or update `docs/devflow/knowledge-base/standards-profile.md` — how this project expresses each applicable standard (where responsibilities live, idioms, primitives, known deviations), every row backed by a real file — with its own approval gate.

**NEVER modify source code.** Only template and knowledge-base files.

## Project Type or Context

${input}
