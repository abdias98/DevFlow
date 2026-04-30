# Codebase Exploration Guide (Technology-Agnostic)

> **Note on examples:** All patterns and conventions mentioned are illustrative. Always adapt to the actual stack, tools, and conventions detected in the project. Use [stack-detection.md](<{{SKILLS_DIR}}/shared/stack-detection.md>) as the primary reference for any technology not explicitly covered below.

This guide is used by the **Architect** during Phase 2. Exploration is **read-only** — never modify any file during this step.

## When to Skip

If `AGENTS.md` was found → skip sub-steps 1, 2, 4, 5, 6. Run only **sub-steps 3, 7, and 8**.

## Sub-steps

### 1. Full Project Structure
Map every significant directory and file. Understand folder hierarchy, module boundaries, and organization.

### 2. Naming Conventions
Identify how files, classes, functions, variables, and routes are named. New components must follow the same conventions.

### 3. Reference Implementation
Find the existing feature closest to what will be built. Study its complete file structure, layers, naming, and data flow.

### 4. Tech Stack Details ⚠️ WRITES STACK PROFILE
Auto-detect from config files: frameworks, test runners, build tools, ORM, DI, state management, custom abstractions.

**MANDATORY OUTPUT:** After detection, **merge** (do not overwrite) the following fields into the `## Stack Profile` table in `context.md` (session memory):
- Language, Runtime, Framework, Package Manager
- Build Command, Lint Command, Source Root

Use [stack-detection.md](<{{SKILLS_DIR}}/shared/stack-detection.md>) as the detection reference for any stack not listed in the examples below.

### 5. Architecture Patterns
Identify: layered, clean, feature-based, MVC, CQRS, repository pattern, etc. Design must align with what exists.

### 6. Conventions for Similar Features
Find at least one existing feature similar to what will be built. Study its file structure, interfaces, and flow.

### 7. Reusability Inventory ⚠️ MANDATORY
Before proposing ANY new component, exhaustively map everything that already exists. For each area the feature touches, verify: does something already solve this? **Rule:** *If something similar exists → reuse or extend. Create new only when exploration confirms no match.*

### 8. Deep Test Architecture Analysis ⚠️ MANDATORY — WRITES STACK PROFILE
Exhaustively explore how the project tests. Discover:
- Test file structure, naming, organization
- Test frameworks and runners (from config/dependency files)
- Test utilities: helpers, factories, fixtures, wrappers, seeds
- Imports, shared dependencies, test-specific config
- Exact commands to run tests (full suite, subset, single file, coverage)

**MANDATORY OUTPUT:** After discovery, **merge** (do not overwrite) the following fields into the `## Stack Profile` table in `context.md`:
- Test Runner, Test Command, Test Command (single file), Test Root, Test Utilities

These values are used by ALL downstream agents (Implementer, Tester, Refactorer, Bug-Fixer, Feature) to determine how to run tests. If any value cannot be detected, write `unknown` and note it.

---

## Tech Stack-Specific Patterns (Illustrative)

> These are common patterns found in projects using these technologies. They are **not prescriptive**. Always defer to the actual codebase and `AGENTS.md`. If the project follows different conventions, document those instead.

### Backend (General)
- Common layered pattern: Request/Controller → Validation → Service/Use Case → Repository → Model/Entity
- Look for: middleware pipeline, dependency injection patterns, ORM conventions, authentication/authorization mechanisms.
- If the framework has an official way (e.g., FormRequest, Policies, Guards), check if the project uses them.

### Frontend (General)
- Detect framework from package manager config files.
- Identify: UI component library, data fetching library, state management, routing, form handling.
- Use existing primitives — do NOT create custom alternatives unless necessary.

### Mobile (General)
- Identify: architecture pattern (MVVM, MVI, MVP), UI framework (declarative or imperative), networking, local storage.
- Follow platform-specific conventions if native; shared token conventions if cross-platform.

### CLI / Library / SDK
- Identify: command/argument parsing, public API surface, error handling conventions, distribution method.

> ⚠️ For ANY stack not explicitly described above: read config files, explore the codebase, use the project's own vocabulary and conventions. The [stack-detection.md](<{{SKILLS_DIR}}/shared/stack-detection.md>) reference covers additional stacks and provides detection strategies.