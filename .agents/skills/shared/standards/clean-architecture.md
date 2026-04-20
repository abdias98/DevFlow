# DevFlow Engineering Standards: Clean Architecture

Apply these patterns to all code you design, generate, or review.

## 1. The Dependency Rule
- **What:** Source code dependencies must point **inward** toward higher-level policies.
- **DO:** Use Dependency Injection at layer boundaries so inner layers define interfaces and outer layers implement them.
- **DON'T:** Let inner layers (Entities, Use Cases) import or reference outer layers (Database, UI, Frameworks).

> This is the architectural expression of SOLID's Dependency Inversion Principle (DIP). See `solid.md` § 5.

## 2. Layer Responsibilities
- **Entities (Domain):**
  - **DO:** Encapsulate core business rules and objects. Keep them as pure logic with zero framework dependencies.
  - **DON'T:** Import HTTP libraries, ORMs, or UI components.
- **Use Cases (Application):**
  - **DO:** Orchestrate data flow between Entities and the outside world via interfaces (ports).
  - **DON'T:** Write SQL queries, HTTP calls, or framework-specific code here.
- **Interface Adapters (Controllers / Presenters / Gateways):**
  - **DO:** Transform data from Use Case format to the format required by UI or external services (DTOs).
  - **DON'T:** Contain business rules — only mapping and translation logic.
- **Frameworks & Drivers (Infrastructure):**
  - **DO:** Keep this layer as thin as possible — it wires together the rest of the system.
  - **DON'T:** Let infrastructure concerns leak into inner layers.

## 3. Strict Prohibitions
- **DON'T:** Pass ORM entities (database models) directly to the UI or return them from API endpoints — always map to a DTO.
- **DON'T:** Write SQL queries or framework-specific code inside Use Cases or Domain Entities.
- **DO:** Define interfaces (ports) in the inner layers and implement them (adapters) in the outer layers.
