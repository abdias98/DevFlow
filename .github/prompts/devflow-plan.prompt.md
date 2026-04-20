---
description: "Break down a spec into atomic implementation tasks with checkboxes, file maps, code snippets, commit messages, and complete test code per task. Phase 3 of the DevFlow lifecycle."
agent: workspace
---

# DevFlow — Plan Phase

Run ONLY the Planner phase of the DevFlow lifecycle.

## Instructions

Invoke the `devflow-plan` skill to:

1. Locate and read the spec document (from session memory or `docs/devflow/specs/`)
2. Explore the codebase — including test framework, test conventions, and run commands
3. Decompose into atomic, ordered tasks grouped by logical unit
4. Map each task to specific files (modify/create)
5. Write complete, ready-to-paste code snippets for each step
6. For each task, include a `🧪 Tests for this Task` section with:
   - Complete, ready-to-paste test code using the project's actual test framework and conventions
   - All required imports/annotations/setup following project conventions
   - At least one test per scenario: happy path, edge case, failure scenario
   - The exact command to run only those tests
   - Assertions designed to FAIL until production code is written
7. Include commit messages at each task checkpoint
8. Save plan to `docs/devflow/plans/YYYY-MM-DD-{slug}.md`

Read session memory first if prior context exists (`/memories/session/devflow/`).

## Spec or Feature Description

${input}
