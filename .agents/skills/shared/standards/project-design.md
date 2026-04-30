# DevFlow Engineering Standards: Project Design Patterns (Technology-Agnostic)

> **Note on examples:** All file names, patterns, and tool references are illustrative. Adapt terminology and conventions to the detected stack.

Apply these principles when designing or reviewing the structural architecture of a project.

## 1. For Existing Projects — Detect, Evaluate, and Act

Before proposing any design, explore the codebase to identify the architectural pattern in use. Then evaluate it using the following decision tree:

| Situation | Action |
|-----------|--------|
| Pattern is **consistent and valid** (Layered, Hexagonal, Feature-Based, etc.) | **DO:** Follow and extend it — consistency outweighs personal preference. |
| Pattern is **different from what you would choose** but does not violate core principles | **DO:** Follow it — respect intentional decisions. Document it in the Architecture Spec. |
| Pattern has **structural problems** (god objects, business logic in controllers/routes, no layer separation, circular dependencies) | **DO:** Flag it in the Architecture Spec as a finding. Explain the violation and propose a migration path. **DON'T** change the existing structure unilaterally — wait for user approval. |

- **DON'T:** Silently follow a broken pattern without surfacing it.
- **DON'T:** Refactor the entire existing structure without explicit user approval, even if it violates principles.

## 2. For New Projects — Select the Right Pattern

Based on the `Feature Type` in session memory, apply the following **reasoning principles** to select the most appropriate architectural pattern. Use your knowledge of the detected stack — this list is **non-exhaustive**.

### Reasoning Principles

| Principle | Apply when... |
|-----------|---------------|
| **Separate by layers** (Controller → Service → Repository) | The project is a backend service, API, or monolith that needs clear testability boundaries |
| **Ports & Adapters (Hexagonal)** | The project needs to be decoupled from its infrastructure (DB, HTTP, messaging) — especially microservices |
| **Feature-Based grouping** | The project is a full-stack or large application that will grow beyond ~10 features |
| **Component-Driven** | The project has a UI — each visual unit is a self-contained, reusable component |
| **Command Pattern** | The project is a CLI — each command is an isolated, independently testable unit |
| **Event-Driven** | The project communicates via events, queues, or streams |
| **Facade + Strategy** | The project is a library or SDK — hide internal complexity behind a clean public API |
| **MVVM / MVI (or equivalent reactive pattern)** | The project is a mobile or desktop app with reactive UI state |

### Reference Examples *(illustrative, not exhaustive)*

| Feature Type | Common Pattern Choice |
|--------------|-----------------------|
| REST API / Backend Service | Layered or Hexagonal |
| Microservice | Hexagonal + Domain Events |
| Full-Stack Web App | Feature-Based |
| Frontend SPA | Component-Driven + State Management |
| CLI Tool | Command Pattern |
| Library / SDK | Facade + Strategy |
| Event-Driven Worker | Event-Driven Architecture |
| Mobile / Desktop App | MVVM or MVI (or framework‑equivalent) |

> If the detected project type is not listed above, apply the **Reasoning Principles** table to determine the best fit using your knowledge of the stack. Document your reasoning in the Architecture Spec.

- **DO:** Justify the chosen pattern in the Architecture Spec, including alternatives considered and why they were rejected.
- **DON'T:** Apply a pattern mechanically without considering the project's actual complexity, team size, and growth expectations. Over‑engineering is as harmful as under‑engineering.
- **DON'T:** Select a pattern solely because it is popular — match the pattern to the problem, not the problem to the pattern.

## 3. Universal Design Rules
- **DO:** Keep the entry point (main / index / app) thin — it only wires dependencies together (composition root).
- **DON'T:** Put business logic in controllers, routes, UI components, or the entry point.
- **DO:** Group code by domain/feature for projects expected to grow beyond ~10 modules.
- **DON'T:** Create dumping grounds for miscellaneous code (e.g., `utils`, `helpers`, `common` directories or modules). Name modules by what they do, not by how generic they are.
- **DO:** Design for testability from the start — if a unit is hard to test, it is a design smell.
- **DON'T:** Let any single module or class become a "god object" that knows too much about the system.
- **DO:** Establish clear module boundaries with explicit public APIs. Avoid circular dependencies between modules; use dependency inversion to break cycles when they appear.
- **DON'T:** Allow infrastructure code to leak into domain or application logic. The direction of dependency should always be from outer layers (UI, DB) toward inner layers (business rules).

## 4. Architecture Documentation
- **DO:** Maintain an Architecture Spec (or equivalent document) that captures:
  - The chosen architectural pattern(s) and their rationale.
  - Layer responsibilities and module boundaries.
  - Key design decisions and rejected alternatives.
  - Known technical debt and migration paths for structural violations.
- **DO:** Update the Architecture Spec when the pattern evolves or when a significant refactor changes the structure.
- **DON'T:** Let the Architecture Spec become stale — it should reflect the current state of the codebase, not the original plan.

## 5. Code Review Checklist
When reviewing project structure, verify:
- [ ] The architectural pattern is consistently applied; new code extends the pattern, not fights it.
- [ ] No business logic resides in controllers, routes, or UI components.
- [ ] Module boundaries are clear; no circular dependencies.
- [ ] No `utils`, `helpers`, or `common` dumping grounds exist — all modules have clear, domain‑specific names.
- [ ] The entry point is thin and only wires dependencies.
- [ ] The Architecture Spec is up to date with the current structure.
- [ ] For existing projects, structural violations are flagged and a migration path is proposed (not silently applied).

## 6. Applying This Standard with a Limited Scope

When applying project design rules to a **specific set of files or modules** (the declared scope), follow these constraints:

1. **Do not restructure the entire project.**  
   - If a file within scope violates a design rule (e.g., business logic in a controller), refactor that file only. Do not move files to new directories, rename modules globally, or reorganize the folder structure unless those changes are explicitly within the scope and approved.
2. **Respect the existing architectural pattern.**  
   - If the project uses Layered architecture, do not introduce Hexagonal patterns in a single module without approval. Consistency within the scope is paramount; flag inconsistencies as INFO notes if they cannot be resolved locally.
3. **Module naming and organization.**  
   - If you identify a `utils` or `helpers` module that should be split, but splitting would create new files outside the scope, leave a comment in the in‑scope file recommending the extraction and describing the target modules.
4. **Dependency direction.**  
   - If you find an inward dependency violation (e.g., a domain entity importing an ORM class) and fixing it requires changes outside the scope, apply the fix only to the in‑scope file (e.g., remove the import, add a port interface) and leave a TODO/INFO comment for the outer‑layer file that must implement the adapter.
5. **Architecture Spec updates.**  
   - Do not create or modify the Architecture Spec unless it is explicitly within the approved scope. If the refactor changes the project structure in a way that warrants a Spec update, mention this to the user as a follow‑up task.