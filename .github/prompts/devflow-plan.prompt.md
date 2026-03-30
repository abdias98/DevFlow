---
description: "Break down a spec into atomic implementation tasks with checkboxes, file maps, code snippets, and commit messages. Phase 2 of the DevFlow lifecycle."
agent: agent
---

# DevFlow — Plan Phase

Run ONLY the Planner phase of the DevFlow lifecycle.

## Instructions

Invoke the `devflow-planner` skill to:

1. Locate and read the spec document (from session memory or `docs/devflow/specs/`)
2. Decompose into atomic, ordered tasks grouped by logical unit
3. Map each task to specific files (modify/create)
4. Write complete, ready-to-paste code snippets for each step
5. Include commit messages at each task checkpoint
6. Save plan to `docs/devflow/plans/YYYY-MM-DD-{slug}.md`

Read session memory first if prior context exists (`/memories/session/devflow/`).

## Spec or Feature Description

${input}
