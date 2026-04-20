# DevFlow Engineering Standards: SOLID Principles

Apply these principles to all code you design, generate, or review.

## 1. Single Responsibility Principle (SRP)
- **What:** A class, function, or module must have one, and only one, reason to change.
- **DO:** Split large classes/modules into smaller, focused units. Each unit owns one concern.
- **DON'T:** Combine database access, business logic, and UI formatting in the same class.

## 2. Open/Closed Principle (OCP)
- **What:** Code should be open for extension but closed for modification.
- **DO:** Add new functionality by implementing a new class or strategy, not by adding `if/else` branches to existing code.
- **DON'T:** Modify a working class every time a new business rule is added.

## 3. Liskov Substitution Principle (LSP)
- **What:** Subtypes must be fully substitutable for their base types without breaking behavior.
- **DO:** Ensure every subclass honors the full contract defined by its base class.
- **DON'T:** Throw `NotImplementedException` or silently ignore inherited methods in subclasses.

## 4. Interface Segregation Principle (ISP)
- **What:** Clients must not be forced to depend on methods they do not use.
- **DO:** Create small, role-specific interfaces with only the methods that belong together.
- **DON'T:** Create large monolithic interfaces that force classes to implement irrelevant methods.

## 5. Dependency Inversion Principle (DIP)
- **What:** High-level modules must not depend on low-level modules. Both depend on abstractions.
- **DO:** Inject services, repositories, and clients as constructor arguments (Dependency Injection).
- **DON'T:** Instantiate concrete implementations (`new Database()`, `new HttpClient()`) inside business logic classes.

> At the architectural level, DIP is expressed as Clean Architecture's Dependency Rule. See `clean-architecture.md` § 1.
