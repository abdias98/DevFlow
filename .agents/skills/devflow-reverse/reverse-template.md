# Reverse Engineering Report Template

Save to `docs/devflow/reverse/YYYY-MM-DD-{slug}-reverse-design.md`:

```markdown
# Reverse Engineering Report — {Project Name}

**Date:** YYYY-MM-DD
**Agent:** DevFlow Reverse Engineering Agent 🔍
**Mode:** {Quick | Full | Deep}
**Duration:** ~{N} minutes

## Project Overview

**Purpose:** {inferred from README, package.json, or code analysis}
**Language:** {detected}
**Framework:** {detected}
**Database:** {detected}
**Files analyzed:** {N}

## Generated Artifacts

| Artifact | Path | Status |
|----------|------|:------:|
| AGENTS.md | `AGENTS.md` | ✅ Created / Updated |
| Stack Profile | In `context.md` | ✅ Populated ({N} fields) |
| Architecture Spec | `docs/devflow/reverse/{filename}` | ✅ |
| Project Template | `docs/devflow/templates/project-architecture.md` | ✅ |
| Dependency Graph | In spec | ✅ ({N} nodes, {N} edges) |

## Architecture Discovered

**Pattern:** {MVC / Clean / Hexagonal / Feature-based / Custom}
**Layers:** {list with file counts per layer}

### Data Flow
```
{ASCII flow diagram from entry point to database}
```

### Key Patterns
| Pattern | Where found | Description |
|---------|-------------|-------------|
| JWT Auth middleware | `middleware/auth.js` | Applied to all /api routes |
| Centralized error handler | `middleware/errorHandler.js` | Catches all thrown errors |
| Repository pattern | `repositories/` | Abstract DB access behind interfaces |

## API Endpoints Discovered

| # | Method | Path | Auth | Handler | File |
|---|--------|------|:----:|---------|------|
{...from route analysis...}

## Dependency Analysis

### Core Modules (high fan-in — imported by many)
| Module | Imported by (N) | Risk if changed |
|--------|:--------------:|----------------|
| `config/database.js` | 15 | 🔴 HIGH |
| `middleware/auth.js` | 8 | 🟡 MEDIUM |

### Orphan Modules (not imported by production code)
| Module | Last modified | Recommendation |
|--------|:------------:|----------------|
| `utils/legacy-parser.js` | 2024-03-15 | Safe to remove? Verify first |

### Circular Dependencies
| Cycle | Files involved |
|-------|---------------|
| (none detected) | — |

## Tech Debt Analysis *(Deep mode only)*

| # | Severity | Location | Issue | Recommendation |
|---|----------|----------|-------|----------------|
{...from deep scan...}

## Stack Profile (Complete)

| Key | Value |
|-----|-------|
| Language | {detected} |
| Runtime | {detected} |
| Framework | {detected} |
| Database | {detected} |
| ORM | {detected} |
| Package Manager | {detected} |
| Test Runner | {detected} |
| Test Command | {command} |
| Test Command (single file) | {command} |
| Build Command | {command} |
| Lint Command | {command} |
| Audit Command | {command} |
| Watch Command | {command} |
| Source Root | {path} |
| Test Root | {path} |
| Test Utilities | {list} |

## Known Unknowns

| Question | Why couldn't be determined |
|----------|---------------------------|
{...things the agent couldn't figure out...}

## Next Steps

1. Run `/devflow <new feature>` — the Architect will use the generated AGENTS.md
2. Fix critical tech debt items identified above
3. Verify the AI-generated AGENTS.md and correct any inaccuracies
4. Run `/devflow-templates` to keep the project template updated
```
