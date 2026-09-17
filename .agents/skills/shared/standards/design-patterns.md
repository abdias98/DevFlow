# DevFlow Engineering Standards: Design Patterns (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-09-17

> **Apply when:** the change introduces a new abstraction, extension point, or a structure for handling variants of behavior (a new class hierarchy, a strategy, a factory, a decorator, or similar) — or extends an existing one. A change that only adds a case to logic that already has a settled shape (a new branch matching an existing pattern) does not need this standard reconsidered from scratch; it needs to follow the pattern already chosen.

`solid.md` §2 (Open/Closed) says new behavior should be added by extension rather than by editing tested code; `project-design.md` §1–2 says which *architectural* pattern the whole project follows. This standard sits between them: which *tactical* pattern solves a specific recurring design problem, and — the part most often skipped — when **not** to reach for one. A pattern applied where a plain conditional would do is not simpler for being "proper OOP"; it is the KISS violation `design-principles.md` §5 already prohibits, wearing a design-pattern's name.

## 1. Problem → Pattern → When Not To

Each pattern below is named for the recurring problem it solves — not applied because a tutorial mentioned it.

| Pattern | Solves | Don't use when |
|---|---|---|
| **Strategy** | Multiple interchangeable algorithms/behaviors selected at runtime | There is exactly one implementation today and no concrete second one is planned — a plain function suffices |
| **Factory (Method/Abstract)** | Object construction that varies by type/config and must stay decoupled from the concrete classes | Construction is a single `new` with no variation — a factory around it adds a layer with nothing to decide |
| **Adapter** | Making an incompatible external/legacy interface conform to the shape your code expects | You control both sides of the interface — just make them match directly |
| **Repository** | Abstracting persistence access behind a domain-shaped interface (`clean-architecture.md` owns the layering this enables) | The data access is a single trivial query with no anticipated swap of storage technology or need for a test double |
| **Observer / Pub-Sub** | Multiple independent consumers must react to a change without the producer knowing who they are | There is exactly one consumer — call it directly; an event bus for one subscriber is indirection with no payer |
| **State** | An object's behavior changes based on a well-defined set of internal states with distinct transition rules | The "states" are just a few boolean flags with no real transition logic — a simple status field with `if` checks is clearer |
| **Command** | Encapsulating a request (with undo/redo, queuing, or logging of the action) as an object | The action is invoked once, synchronously, with no need to queue, log, or undo it |
| **Decorator** | Adding behavior to an object transparently, combinable, without subclassing every combination | Only one variant of the behavior will ever exist — add the behavior directly |
| **Facade** | Providing a simple entry point over a genuinely complex subsystem with many interacting parts | The "subsystem" is one or two calls — a facade around them is a pass-through with no simplification |
| **Builder** | Constructing a complex object with many optional parts step by step | The object has few fields and a constructor/literal already reads clearly |

## 2. Follow the Existing Pattern First

- **What:** If the codebase already solves this class of problem with a pattern, a new instance of the same problem should use it too — a second, different solution to the same problem is a maintenance burden regardless of which one is "more correct" in isolation.
- **DO:**
  - Check the project's [standards profile](../../devflow-templates/standards-profile-template.md) (`docs/devflow/knowledge-base/standards-profile.md`) and existing code for how this class of problem is already solved before choosing an approach.
  - When following the existing pattern, match its shape (naming, method signatures, registration mechanism) rather than reinventing a parallel version of the same idea.
  - When the existing pattern is a poor fit for the new case, say so explicitly in the spec's Design Decisions rather than silently diverging.
- **DON'T:**
  - Introduce a second, different solution to a problem the codebase already has a pattern for, without recording why the existing one didn't fit.

## 3. Real Variation, Not Anticipated Variation

- **What:** A pattern built to accommodate future variants earns its complexity only when a second concrete variant exists or is a stated, near-term requirement — not "in case we need it later" (`design-principles.md` §2, YAGNI, is the general form of this rule; this section is its application to pattern selection specifically).
- **DO:**
  - Introduce a Strategy/Factory/Decorator-style extension point when a second concrete case exists now, or is explicitly on the plan.
  - Start with the plain, direct implementation and extract the pattern at the point a genuine second variant appears — this is usually cheap; guessing the wrong abstraction upfront is not.
- **DON'T:**
  - Build an extension point, plugin system, or strategy interface for a single current implementation "for flexibility."

## 4. Composition Over Inheritance for Variant Behavior

- **What:** Deep inheritance hierarchies built to express variation tend to become rigid (a subclass locked into its parent's shape) and fragile (a change to a shared base ripples unpredictably to every descendant).
- **DO:**
  - Prefer composing small, focused collaborators (strategies, injected dependencies) over inheriting to reuse or vary behavior.
  - Reserve inheritance for genuine "is-a" relationships where every subtype must satisfy the full contract of the base (`solid.md` §3, LSP).
- **DON'T:**
  - Add a new subclass to express a behavioral variant when a composed strategy would let the same object support multiple behaviors without a rigid class hierarchy.

## 5. Code Review Checklist
When reviewing, verify:
- [ ] The pattern chosen solves a problem the code actually has, matching the table in §1 — not applied because it's a recognizable name (§1).
- [ ] Where the codebase already has a pattern for this class of problem, the new code follows it or explicitly justifies diverging (§2).
- [ ] An extension point/strategy/factory was introduced only where a second concrete variant exists or is a stated near-term requirement (§3).
- [ ] Variant behavior is composed rather than expressed through a new subclass unless a genuine "is-a" relationship exists (§4).

## 6. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `design-patterns.md §3`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | *(none by default — pattern selection is a design-quality concern, not a correctness or safety invariant on its own; a specific project may declare its own BLOCK trigger in `AGENTS.md` for a pattern its architecture depends on)* |
| 🟡 **WARN** | A Strategy/Factory/Decorator-style extension point introduced for a single current implementation with no stated second variant (§3, canonical citation `design-principles.md §2`); a second, different solution to a problem the codebase already solves with an established pattern, with no recorded reason for diverging (§2); a new subclass added to express a behavioral variant where composition would avoid a rigid hierarchy (§4) |
| 🟢 **INFO** | A pattern applied correctly but with a name/shape that doesn't match the project's existing convention for the same pattern (§2); a plain conditional that is starting to accumulate cases and may warrant extraction to a pattern soon, but isn't yet causing harm (§1, cross-ref `solid.md §2`) |

## 7. Applying This Standard with a Limited Scope

When applying this standard to a **specific set of files or modules** (the declared Core scope), follow these constraints:

1. **Only modify files inside Core directly.** If a pattern-misuse finding applies to a file outside Core, apply the Impact Zone / backlog handling below rather than editing it unconditionally.
2. **Introducing a pattern within a file already in Core, justified by a real second variant in this task, is always allowed.**
3. **Retrofitting an existing pattern onto unrelated code outside this task's scope is not a scope-safe improvement** — even when it would clearly help; propose it separately so the diff is reviewable on its own (mirrors `design-principles.md §8`, item 4).
4. **Do not introduce a new architectural-level pattern** (a new layering scheme, a new plugin/module system) as a side effect of a tactical pattern decision — that is `project-design.md`'s domain and requires its own decision.

**Handling violations outside the Core scope** (per [`rules.md`](../rules.md) → Scope-Locking — Three Zones): a file is either in the **Impact Zone** (a dependent or dependency of a file already in Core, discoverable via `devflow-ctl scope impact <file>`) or **Outside**.
- **Impact Zone + one of the six closed coherence reasons** (broken caller, broken import, contract violation, duplicated logic the task just introduced, a test that now fails, a type/schema that must change together): fix it, then record `devflow-ctl scope justify <file> "<reason>"`.
- **Impact Zone without a closed coherence reason, or Outside entirely:** do not edit it. Defer it instead: `devflow-ctl backlog add <file> "<reason>" --severity {incomplete|info}` — use `incomplete` if the in-scope change is functionally incoherent without that follow-up, `info` if it is a separate improvement.

## 8. Design-Time Decisions

Record these in the spec's **Design Decisions** section:

- **Pattern selected, if any** — which entry from §1's table, and the concrete recurring problem it addresses (§1).
- **Existing precedent checked** — whether the codebase/standards profile already solves this class of problem, and the outcome of that check (§2).
- **Variance evidence** — the concrete second variant (existing or stated near-term) that justifies an extension point, if one is introduced (§3).
- **Composition vs. inheritance** — for any new subclass expressing a behavioral variant, why it is a genuine "is-a" relationship rather than a composable strategy (§4).

## 9. Implementation Self-Check

Before marking a task done:

- [ ] The pattern used (if any) matches a real, current problem from §1 — not introduced speculatively (§1, §3).
- [ ] Existing code/the standards profile was checked for a precedent before introducing a new solution shape (§2).
- [ ] No new subclass was added to express a variant where composition was available and appropriate (§4).
- [ ] Nothing was over-generalized beyond what this task's concrete requirement needs (§3, cross-ref `design-principles.md §5`).
