---
description: "Tutorial agent — interactive onboarding for new DevFlow users. Guides through a complete cycle step-by-step with explanations. Never skips phases. Always waits for user confirmation."
agent: workspace
---

# DevFlow — Interactive Tutorial

Run the Tutorial Agent for a guided walkthrough of DevFlow.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-tutorial/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Welcome the user and set up a demo feature.
2. Walk through all 7 phases: Brainstormer → Architect → Planner → Gate → Implementer → Reviewer → Finalizer.
3. Explain each phase: what it does, why it matters, what it outputs.
4. Wait for user confirmation between each phase.
5. Overview of standalone agents.
6. Save tutorial documentation + cheat sheet.

**It's designed to be interactive. The user learns by experiencing a real cycle.**

## Demo Feature (optional)

${input}
