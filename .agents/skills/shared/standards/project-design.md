# DevFlow Engineering Standards: Project Design Patterns

Apply these principles when designing or reviewing the structural architecture of a project.

## 1. For Existing Projects — Detect, Evaluate, and Act

Before proposing any design, explore the codebase to identify the architectural pattern in use. Then evaluate it using the following decision tree:

| Situation | Action |
|-----------|--------|
| Pattern is **consistent and valid** (Layered, Hexagonal, Feature-Based, etc.) | **DO:** Follow and extend it — consistency outweighs personal preference. |
| Pattern is **different from what you would choose** but does not violate core principles | **DO:** Follow it — respect intentional decisions. Document it in the Spec. |
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
| **Feature-Based grouping** | The project is a full-stack or large frontend that will grow beyond ~10 features |
| **Component-Driven** | The project has a UI — each visual unit is a self-contained, reusable component |
| **Command Pattern** | The project is a CLI — each command is an isolated, independently testable unit |
| **Event-Driven** | The project communicates via events, queues, or streams |
| **Facade + Strategy** | The project is a library or SDK — hide internal complexity behind a clean public API |
| **MVVM / MVI** | The project is a mobile or desktop app with reactive UI state |

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
| Mobile / Desktop App | MVVM or MVI |

> If the detected project type is not listed above, apply the **Reasoning Principles** table above to determine the best fit using your knowledge of the stack.

- **DO:** Justify the chosen pattern in the Architecture Spec, including alternatives considered.
- **DON'T:** Apply a pattern mechanically without considering the project's actual complexity, team size, and growth expectations.

## 3. Universal Design Rules
- **DO:** Keep the entry point (main / index / app) thin — it only wires dependencies together (composition root).
- **DON'T:** Put business logic in controllers, routes, UI components, or the entry point.
- **DO:** Group code by domain/feature for projects expected to grow beyond ~10 modules.
- **DON'T:** Create `utils.ts`, `helpers.ts`, or `common.ts` dumping grounds — name modules by what they do, not by how generic they are.
- **DO:** Design for testability from the start — if a unit is hard to test, it is a design smell.
- **DON'T:** Let any single module or class become a "god object" that knows too much about the system.
