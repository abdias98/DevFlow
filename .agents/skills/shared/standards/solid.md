# DevFlow Engineering Standards: SOLID Principles (Technology-Agnostic)

> **Note on examples:** All code-like fragments use generic pseudo-code or abstract concepts (e.g., “HTTP client”, “ORM entity”, “service locator”) to avoid dependence on any specific language or framework. Adapt the concrete syntax to the detected stack.

Apply these principles to all code you design, generate, or review.

## 1. Single Responsibility Principle (SRP)
- **What:** A class, function, or module must have one, and only one, reason to change.
- **DO:**  
  - Split large classes/modules into smaller, focused units. Each unit owns one concern.  
  - Name classes and functions so that their single responsibility is obvious (e.g., `InvoicePrinter`, `PasswordHasher`). If you struggle to name it, it probably has multiple responsibilities.  
  - Extract cross-cutting concerns (logging, caching, authorization) into decorators or middleware—don't mix them with business logic.  
- **DON'T:**  
  - Combine database access, business logic, and UI formatting in the same class.  
  - Use “and” or “or” in class/function names (`UserRegistrationAndEmailSender`).  
  - Create “god classes” that centralize all logic for a concept (e.g., a single `OrderManager` that calculates totals, saves to DB, sends emails, and renders views).

## 2. Open/Closed Principle (OCP)
- **What:** Code should be open for extension but closed for modification.
- **DO:**  
  - Add new functionality by implementing a new class or strategy, not by adding `if/else` or `switch` branches to existing code.  
  - Use polymorphism (interfaces, abstract classes) to allow new behaviors to be plugged in.  
  - Apply the Strategy, Template Method, or Decorator pattern when you anticipate variant behaviors.  
- **DON'T:**  
  - Modify a working, tested class every time a new business rule is added.  
  - Add a new `case` to a `switch` statement inside a core business method to support a new variant.  
  - Use conditional logic that checks a type code or enum to determine behavior—replace with polymorphic dispatch.

## 3. Liskov Substitution Principle (LSP)
- **What:** Subtypes must be fully substitutable for their base types without breaking behavior.
- **DO:**  
  - Ensure every subclass honors the full contract defined by its base class (preconditions cannot be stronger, postconditions cannot be weaker).  
  - Design by contract: if the base class guarantees a return value is never null, subclasses must not return null.  
  - Use language features that prevent unintended overrides (e.g., `final` methods or sealed classes, where available) and document expected behavior explicitly.  
- **DON'T:**  
  - Throw an unsupported-operation exception (like `NotImplementedException`) or use no‑op overrides that silently break the contract.  
  - Override a method in a way that changes its semantics (e.g., a `Square` that mutates width when height is set, breaking the contract of a `Rectangle`).  
  - Accept a narrower range of inputs than the base class allows (e.g., base accepts any string, subclass throws on empty strings).

## 4. Interface Segregation Principle (ISP)
- **What:** Clients must not be forced to depend on methods they do not use.
- **DO:**  
  - Create small, role-specific interfaces with only the methods that belong together (e.g., `Readable<T>`, `Writable<T>` rather than a monolithic `Repository<T>`).  
  - Split interfaces when a client only needs a subset of the methods. Prefer multiple small interfaces over one large one.  
  - Group methods by the clients that call them. If two different consumers use different subsets, the interface should probably be split.  
- **DON'T:**  
  - Create large monolithic interfaces that force classes to implement irrelevant methods.  
  - Add a new method to an existing interface if only some of its implementers can support it—create a new interface instead and have the capable classes implement it.  
  - Use “header interfaces” (interfaces that mirror every public method of a single class). Interface design should be driven by client needs, not implementation convenience.

## 5. Dependency Inversion Principle (DIP)
- **What:** High-level modules must not depend on low-level modules. Both depend on abstractions.
- **DO:**  
  - Inject services, repositories, and clients as constructor arguments (Dependency Injection).  
  - Depend on interfaces defined in the same layer or an inner layer, never on concrete classes from outer layers.  
  - Use factories or DI containers to resolve complex dependency graphs, but keep the container out of domain/business logic.  
- **DON'T:**  
  - Instantiate concrete implementations (e.g., `new DatabaseConnection()`, `new ExternalApiClient()`) inside business logic classes.  
  - Depend directly on static methods or global service locators that bind you to a specific implementation (e.g., a call like `GlobalLocator.getDatabase()`).  
  - Import or reference framework-specific base classes (e.g., an HTTP request/response object provided by the web framework, an ORM entity collection type) inside high-level policy modules.

> At the architectural level, DIP is expressed as Clean Architecture's Dependency Rule. See `clean-architecture.md` § 1.

## 6. SOLID Interactions & Tensions
- **SRP + OCP:** A class with a single responsibility is easier to extend via OCP because it only does one thing. Adding new behavior means adding a new class that wraps or replaces it.  
- **LSP + OCP:** OCP relies on LSP. If subclasses are not substitutable, you cannot safely extend behavior without modifying existing code.  
- **ISP + DIP:** Small interfaces (ISP) make DIP easier to apply because clients only depend on the narrow contracts they need. Large interfaces lead to unnecessary coupling.  
- **Do not over-engineer:** For a simple `if/else` that will never grow, a class hierarchy for OCP may be overkill. Use judgment. Abstract only when the variation is real and the cost of change is high.

## 7. Code Review Checklist
When reviewing, verify:
- [ ] Classes and functions have a single, well-named responsibility (SRP).  
- [ ] New behavior is added via new classes, not by modifying existing `switch`/`if-else` blocks (OCP).  
- [ ] Subclasses can be used anywhere their parent is expected without surprises (LSP).  
- [ ] Interfaces are small and client-specific; no implementer is forced to stub irrelevant methods (ISP).  
- [ ] High-level code depends on abstractions, not concrete low-level details; dependencies are injected (DIP).  
- [ ] No direct instantiation (e.g., `new`) of infrastructure or external service classes inside domain/application code.  
- [ ] No unsupported-operation exceptions or no-op overrides in production subclasses.

## 8. Applying This Standard with a Limited Scope

When you are asked to apply SOLID principles to a **specific set of files or modules** (the declared scope), follow these constraints to respect the “never touch files outside the scope” rule:

1. **Only modify files inside the scope.**  
   - If an SRP violation requires splitting a class, but the new class would be outside the scope, **do not create it**. Instead, add a comment in the original file recommending the split and describing the responsibility that should be extracted.
2. **Interface extraction when the implementer is outside scope.**  
   - If DIP requires depending on an abstraction but the existing concrete class is outside scope, define the interface (port) in scope and leave a TODO/INFO comment stating that the outer class should implement it.
3. **OCP refactors limiting new classes.**  
   - If replacing a `switch` with polymorphism would require creating multiple new strategy files outside scope, document the pattern in a comment instead of partially refactoring.
4. **Avoid breaking the build.**  
   - Removing a direct instantiation to replace with injected dependency may break DI registration if the composition root is out of scope. In that case, leave the `new` call but add a comment explaining how it should be refactored to full DIP.
5. **Small scope-safe improvements are always allowed:**  
   - Renaming a class for clarity (if the user approved it).  
   - Extracting a private method to reduce duplication within the same file.  
   - Replacing magic numbers with constants within the same file.  
   - Adding documentation comments that clarify the contract (LSP).