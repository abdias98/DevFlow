# DevFlow Engineering Standards: Clean Architecture (Technology-Agnostic)

> **Note on examples:** All code-like fragments and tool references are illustrative. Replace them with the actual libraries, frameworks, and naming conventions of the detected stack.

Apply these patterns to all code you design, generate, or review.

## 1. The Dependency Rule
- **What:** Source code dependencies must point **inward** toward higher-level policies.  
  Inner layers (Entities, Use Cases) must be *deployment units* that do not reference any outer layer package/module.
- **DO:**  
  - Define abstractions (interfaces/abstract classes) in inner layers.  
  - Inject implementations via constructor injection at composition root (startup / DI container).  
- **DON'T:**  
  - Import or reference classes from databases, web frameworks, or UI libraries in inner layers.  
  - Use static service locators or direct instantiation (`new`) on infrastructure types inside domain/application code.

> This is the architectural expression of SOLID's Dependency Inversion Principle (DIP). See `solid.md` § 5.

## 2. Layer Responsibilities

### Entities (Domain)
- **DO:**  
  - Model core business concepts as plain objects (simple data structures without framework dependencies) with behavior (methods).  
  - Express domain invariants inside constructors or self‑contained methods.  
  - Use value objects for primitive obsession (e.g., `Email`, `Money`).  
  - Throw domain‑specific exceptions only.  
- **DON'T:**  
  - Import HTTP, ORM, serialization or UI libraries.  
  - Depend on application‑layer DTOs or infrastructure concerns.

### Use Cases (Application)
- **DO:**  
  - Define a single public method that accepts an **input** (a DTO or command) and returns an **output** (a DTO) or calls a presenter interface.  
  - Orchestrate: fetch entities from repository interfaces, invoke business methods, save changes.  
  - Keep the flow explicit; avoid “god” use cases.  
  - Rely on port interfaces (e.g., `OrderRepository`, `EmailService`) declared in this layer.  
- **DON'T:**  
  - Use framework‑specific types (e.g., HTTP request/response objects provided by the web framework, ORM-specific collection types).  
  - Catch exceptions unless translating to domain/custom application exceptions.  
  - Write SQL (or any database query language), HTTP clients, or file I/O — delegate through ports entirely.

### Interface Adapters (Controllers / Presenters / Gateways)
- **DO:**  
  - Controllers: validate request shape, call a single use case, map response DTO to HTTP/UI format.  
  - Presenters: implement output port interfaces to transform use‑case responses into view models.  
  - Gateways/Adapters: implement ports defined in Application layer (e.g., repository that uses an ORM).  
- **DON'T:**  
  - Contain business rules — only transformation, serialization, and delegation.  
  - Expose domain entities or ORM entities through public APIs — always project to DTOs.

### Frameworks & Drivers (Infrastructure)
- **DO:**  
  - Wire dependencies at startup (composition root).  
  - Keep implementations thin: a repository method should be a single query/command, not contain business logic.  
  - Implement logging, caching, messaging adapters here, behind interfaces from inner layers.  
- **DON'T:**  
  - Let infrastructure concerns (e.g., connection strings, web‑specific attributes) leak into inner layers.  
  - Bypass use cases by calling repositories directly from controllers.

## 3. Strict Prohibitions
- **DON'T:** Pass ORM entities (database models) directly to the UI or return them from API endpoints — always map to a DTO.
- **DON'T:** Write database queries or framework‑specific code inside Use Cases or Domain Entities.
- **DO:** Define interfaces (ports) in the inner layers and implement them (adapters) in the outer layers.
- **DON'T:** Use domain exceptions that inherit from infrastructure‑specific base classes (e.g., exceptions that carry transport-level status codes). Domain exceptions must be framework‑agnostic.
- **DON'T:** Sprinkle validation logic in controllers that should belong to the domain (e.g., “email is valid” → value object; “order amount > 0” → entity invariant).

## 4. Cross‑Cutting Concerns & Conventions
- **Logging & Monitoring:**  
  - Inner layers may depend on a simple logger abstraction (e.g., `LoggerInterface`) if it is defined in the application/domain layer.  
  - Infrastructure provides the concrete logger (e.g., structured logging library, observability framework).  
- **Caching / Transaction Management:**  
  - Define abstractions (e.g., a `UnitOfWork` interface) in Application layer; implement in Infrastructure.  
  - Use decorators or pipeline behaviors for concerns like retry, transaction, authorization.  
- **Asynchronous / Messaging:**  
  - Domain events (if used) should live in Domain layer; handlers in Application layer.  
  - Event dispatchers must be abstracted behind an interface to avoid framework lock‑in.  
- **Folder/Module Structure:**  
  - Each layer gets its own package/module: `Domain`, `Application`, `Infrastructure`, `Presentation`.  
  - Inside `Application`, group by feature (e.g., `Orders/CreateOrder`, `Orders/GetOrderHistory`) rather than by type.  

## 5. Testing Requirements
- **Entities:** Must be unit testable with zero mocks — just instantiate and assert behaviour.  
- **Use Cases:** Test with mocked ports (repositories, services). Verify orchestration, exception paths, and mapping.  
- **Adapters:** Integration/contract tests against real or emulated infrastructure (database, HTTP).  
- **Coding for Testability:**  
  - All dependencies injected via constructor.  
  - No static state or thread‑local context that complicates test isolation.

## 6. Code Review Checklist
When reviewing, verify:
- [ ] Dependencies only point inward (analyze imports/package references).
- [ ] Domain model has no framework annotations (e.g., ORM mapping annotations, HTTP routing attributes).
- [ ] Use cases expose only ports or application‑defined DTOs.
- [ ] Controllers/Adapters only translate; no `if` statements that represent business rules.
- [ ] External service boundaries have clear contracts (interface definitions in Application).
- [ ] New functionality follows feature‑folder organization.

## 7. Applying This Standard with a Limited Scope

When you are asked to apply Clean Architecture rules to a **specific set of files or modules** (the declared scope), follow these additional constraints to avoid breaking the principle of “never touch files outside the scope”:

1. **Only modify files inside the scope.**  
   - If a violation is found in a file outside the scope, **do not edit it**. Instead, add a comment (in the files you *can* edit) mentioning the architectural issue and the recommended change in the other file.  
   - Use the same style as the skill's INFO notes.

2. **Do not introduce new abstractions that would break the build.**  
   - If a change requires extracting an interface and implementing it in an outer layer, but that outer layer is not in scope, **put the interface definition in scope (as a port)** and leave a TODO/INFO comment explaining that an adapter is needed elsewhere.  
   - Do not modify DI registrations unless the composition root is explicitly in scope.

3. **If removing a forbidden dependency would break compilation, pause.**  
   - Example: A Use Case imports an ORM entity. Removing that import might require rewriting the method, which could need a repository interface and a DTO. If those new files fall outside the scope, **do not proceed**. Instead, document the violation as an INFO note and explain the refactoring path.

4. **Scope‑safe transformations are always allowed:**  
   - Removing framework annotations from domain entities (only if that entity file is in scope).  
   - Extracting value objects within the same file/module.  
   - Moving business logic from a controller to a use case if both are in scope.  
   - Adding input/output DTOs inside the application layer if it is within scope.

5. **The clean architecture rules still apply *in full* during design or full‑project review.**  
   - When the scope is the whole project, follow the above rules without any softening.