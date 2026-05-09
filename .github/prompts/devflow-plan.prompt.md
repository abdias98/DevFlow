---
description: "Break down a spec into atomic implementation tasks with checkboxes, file maps, code snippets, commit messages, and complete test code per task. Phase 3 of the DevFlow lifecycle."
agent: workspace
---

# DevFlow — Plan Phase

Run the Planner phase of the DevFlow lifecycle.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-plan/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Read the Architecture Spec from session memory or `docs/devflow/specs/`.
2. Ask the Stack Mode question (conditional — only if the feature is large and spans multiple layers).
3. Explore existing code patterns, test conventions, and reference implementations.
4. Generate HTML mockups (if UI feature).
5. Break down the spec into atomic, ordered tasks with complete code snippets, test code, and commit messages.
6. Save the plan to `docs/devflow/plans/YYYY-MM-DD-{slug}.md`.
7. If invoked as part of the full lifecycle, hand control back to the Orchestrator for the Confirmation Gate. If invoked standalone, present the plan to the user for approval and STOP.

**NEVER** write implementation code — only plan documents and mockups.

## Spec or Feature Description

${input}