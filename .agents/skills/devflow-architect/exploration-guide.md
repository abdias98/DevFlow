# Codebase Exploration Guide

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

**MANDATORY OUTPUT:** After detection, populate the `## Stack Profile` table in `context.md` (session memory) with:
- Language, Runtime, Framework, Package Manager
- Build Command, Lint Command, Source Root

Use [stack-detection.md](../shared/stack-detection.md) as the detection reference for any stack not listed below.

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

**MANDATORY OUTPUT:** After discovery, populate the following fields in the `## Stack Profile` table in `context.md`:
- Test Runner, Test Command, Test Command (single file), Test Root, Test Utilities

These values are used by ALL downstream agents (Implementer, Tester, Refactorer, Bug-Fixer, Feature) to determine how to run tests. If any value cannot be detected, write `unknown` and note it.

## Tech Stack-Specific Patterns

### PHP / Laravel
- Detect installed packages from `composer.json` (spatie permissions, filament, sanctum, etc.)
- Layered: Request → Controller → FormRequest → Service → Repository → Model
- Use FormRequest for validation, Policy for auth, Gate/@can for UI permissions
- Eloquent: singular PascalCase models, relationships, scopes, observers
- Filament: check existing Resources before creating new ones

### JavaScript / TypeScript
- Detect framework from `package.json`: React/Next.js, Vue/Nuxt, Angular, Svelte
- Detect UI lib, data fetching lib, state management, form lib, auth
- Use existing primitives — do NOT create custom alternatives

### .NET (C# / ASP.NET Core)
- DI registration patterns, middleware pipeline, ORM (EF Core/Dapper), base classes

### Python
- Django, FastAPI, Flask — detect and follow existing structure, serializers, ORM

### Go
- Detect HTTP framework, project structure, ORM/query tool, interfaces

### Java / Spring Boot
- Layered: Controller → Service → Repository → Entity (JPA)
- DI, validation annotations, Lombok, Spring Security

### Android (Kotlin)
- Architecture: MVVM/MVI, Room, Retrofit, DataStore, Compose vs XML, Hilt/Dagger

### Ruby / Rails
- Detect gems (devise, pundit), service objects, form objects

> ⚠️ For ANY stack not listed: read config files, explore the codebase, use the project's own vocabulary.
