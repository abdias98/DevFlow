---
description: "Analyze requirements, explore the codebase, and produce an architecture design spec. Phase 2 of the DevFlow lifecycle."
agent: workspace
---

# DevFlow — Architect Phase

Run the Architect phase of the DevFlow lifecycle.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-architect/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Read the Problem Statement from session memory (`context.md`).
2. Explore the codebase (or use `AGENTS.md` if present).
3. Define architecture: components, data structures, data flow, integration points.
4. Save the design spec to `docs/devflow/specs/YYYY-MM-DD-{slug}-design.md`.
5. Update `context.md` with Stack Profile and Architect Findings.
6. If invoked as part of the full lifecycle, hand control back to the Orchestrator. If invoked standalone, present the spec to the user and STOP.

**NEVER** write implementation code — only architecture and design.

## Feature/Requirement

${input}