---
description: "Database migration agent — analyzes schema changes, generates migration files, verifies forward/backward compatibility, and suggests zero-downtime strategies. Standalone agent. Never executes migrations."
agent: workspace
---

# DevFlow — Database Migration

Run the Migration Agent to generate and validate database schema changes.

## Active Instructions

1. **Read common rules:** `{{SKILLS_DIR}}/shared/rules.md`
2. **Read Skill:** `{{SKILLS_DIR}}/devflow-migrate/SKILL.md`
3. **Follow the procedure** defined in the SKILL.md

## Summary

1. Understand the schema change (from spec, plan, or user description).
2. Load stack profile — identify database type and migration tool.
3. Analyze impact: forward/backward compatibility, zero-downtime risks, data integrity.
4. Detect project migration conventions (naming, location, structure).
5. Generate migration files with up/down methods.
6. Save migration report to `docs/devflow/migrations/YYYY-MM-DD-{slug}-migration.md`.
7. Auto-invoke Reviewer in Standalone Mode.

**NEVER execute migrations.** Only generate files and provide commands.

## Schema Change or Context

${input}
