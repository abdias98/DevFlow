# DevFlow Engineering Standards: Design Principles (Technology-Agnostic)

> **Version:** 1.1.0 | **Last Updated:** 2026-09-09

> **Note on examples:** All code-like fragments are illustrative. Replace them with the actual language/framework conventions of the detected stack.

Apply these five transversal principles to **every** DevFlow cycle — lifecycle and standalone alike, in every phase from Brainstorm through Finalize. Unlike domain-specific standards (REST API, UI Design), none of these five is conditional on stack or feature type: they apply to every request, every review, every refactor.

## 1. DRY — Don't Repeat Yourself

- **What:** Knowledge duplicated in two places drifts — one copy gets updated, the other doesn't, and now there are two answers to the same question.
- **DO:**
  - Extract a shared abstraction once a piece of logic or knowledge is duplicated a **third** time (the "rule of three"). Extracting on the second occurrence often guesses the wrong abstraction before the pattern is clear; waiting past the third lets drift set in.
  - Prefer duplicating simple, unlikely-to-change code over introducing a premature abstraction that couples two callers that don't actually share a reason to change together.
  - Treat two standards, two SKILL.md files, or two config files explaining the same rule the same way as duplication — DRY applies to documentation and configuration, not only to code (see [standards-dry-policy.md](../standards-dry-policy.md) for how this applies to DevFlow's own standards).
- **DON'T:**
  - Apply DRY to **coincidental** similarity — two pieces of code that look alike today but represent different business rules that will diverge later should stay separate. Merging them creates a false coupling that breaks the moment one rule changes and the other doesn't. Prefer duplication over the wrong abstraction.
  - Chase 100% DRY at the cost of indirection (a generic helper with five boolean flags) that is harder to follow than the duplication it replaced.

## 2. YAGNI — You Aren't Gonna Need It

- **What:** Building for a hypothetical future requirement costs real complexity now for a benefit that may never materialize.
- **DO:**
  - Implement only what the current, concrete requirement needs. Add the extension point, the configuration option, or the abstraction layer when a **second real use case** appears — not in anticipation of one.
  - When tempted to add a flag, parameter, or layer "in case we need it later," ask: is there a concrete, currently-known requirement for this, or is it speculative? If speculative, don't build it.
- **DON'T:**
  - Add a plugin system, a generic configuration layer, or a heavier architectural pattern (e.g., CQRS, event sourcing — see [event-driven-architecture.md](./event-driven-architecture.md) § CQRS) because it "might scale better," with no concrete, current need driving it.
  - Use YAGNI as an excuse to skip design work that a foreseeable, already-committed near-term requirement makes necessary — YAGNI is about hypothetical futures, not about ignoring stated requirements.

## 3. SoC — Separation of Concerns

- **What:** A unit of code should have one reason to change, and that reason should be intelligible without also understanding unrelated concerns folded into it.
- **DO:**
  - Separate what varies for different reasons: business rules from I/O, presentation from domain logic, configuration from behavior. This is the general principle that SOLID's Single Responsibility Principle (`solid.md` §1) and Clean Architecture's layering (`clean-architecture.md` §1) are specific applications of.
  - Draw the boundary at the **axis of change**, not at an arbitrary technical layer — two things that always change together for the same business reason belong together, even if one looks like "validation" and the other "persistence."
- **DON'T:**
  - Split code into layers or modules that always change in lockstep — that isn't separation, it's the same concern spread across files, adding navigation cost with no isolation benefit.
  - Mix orthogonal concerns in one function or class because "it's convenient here" — a request handler that also contains business rules and raw queries is the same violation regardless of what the framework calls that file.

## 4. Technology Agnosticism

- **What:** A decision that only works with today's specific database, framework, or vendor is a decision the project pays to undo the moment that dependency needs to change — even when no change is currently planned.
- **DO:**
  - Define domain/business logic against abstractions (ports/interfaces) the project owns, not against a specific library's types — see `clean-architecture.md` §1 (the Dependency Rule) for the architectural mechanism that enforces this.
  - Shape the abstraction from the **problem domain**, not by mirroring whatever the current framework/library happens to expose — an interface that is just a copy of the vendor SDK's shape doesn't buy independence from it.
- **DON'T:**
  - Let a specific database's query language, a specific cloud provider's SDK types, or a specific framework's request/response objects leak into domain or business-logic code.
  - Treat "agnostic" as "reinvent everything from scratch" — using a framework's own tested primitives inside the infrastructure/adapter layer is correct; the constraint is on where the dependency is allowed to reach, not on avoiding frameworks altogether.

## 5. KISS — Keep It Simple

- **What:** Complexity the problem did not require is a tax paid on every future read, change, and debugging session by people who never chose to take on that debt. The relevant question is never "is this clever?" but "is this the least machinery that fully solves the stated problem?"
- **DO:**
  - Judge simplicity by the cost of **reading** the code cold — how many concepts someone must hold in their head at once to follow it — not by line count, and not by how sophisticated the technique is.
  - When two designs both satisfy the requirement, take the one with fewer moving parts (fewer layers of indirection, fewer new concepts introduced), even when the other is more general or more elegant. Generality that no current requirement uses is complexity without a payer.
  - Separate **essential** complexity, which is inherent to the problem and cannot be removed, from **accidental** complexity, which the chosen solution introduced. Only the second kind is worth attacking; trying to make an irreducibly hard problem look simple usually just hides it.
- **DON'T:**
  - Optimize before a measurement shows a real bottleneck — an unmeasured optimization pays complexity now for a benefit nobody has confirmed exists (`performance.md` §6 is the canonical owner of *how* to measure; the point here is that optimization without that evidence is unjustified complexity).
  - Confuse this with YAGNI (§2). YAGNI governs **whether** to build a thing at all; KISS governs the **form** of what does get built. A genuinely required feature implemented through three layers of dynamic dispatch satisfies YAGNI and violates KISS — and the reverse is just as possible.
  - Read "simple" as "short." A dense one-liner chaining five operations is not simpler than four named steps; it is the same complexity with the names removed, which makes it harder to read, not easier.

## 6. Code Review Checklist
When reviewing, verify:
- [ ] A given piece of business logic or knowledge exists in exactly one place — no independent reimplementation of the same rule (§1).
- [ ] No abstraction, configuration layer, or architectural pattern was introduced for a hypothetical future need with no concrete, current requirement driving it (§2).
- [ ] Each module/function has one axis of change; unrelated concerns (I/O, business rules, presentation) are not folded into the same unit (§3).
- [ ] Domain/business logic depends on interfaces the project owns, not directly on a specific framework/library/vendor's types (§4).
- [ ] No solution carries more machinery than the stated problem requires — no indirection layer, generality, or optimization that a current requirement or a measurement does not pay for (§5).

## 7. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `design-principles.md §1`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | *(none by default — these are design-quality principles, not correctness or safety invariants; a violation here degrades maintainability, it doesn't on its own cause data loss or a security breach. If a specific project's constraints make one of these non-negotiable, that project documents its own BLOCK trigger in `AGENTS.md`.)* |
| 🟡 **WARN** | The same business rule, validation, or calculation independently reimplemented in 2+ places and already diverging (§1); a new abstraction, config layer, or architectural pattern added with no current concrete requirement for it (§2); domain/business logic directly importing a specific ORM/framework/vendor SDK type (§4); an optimization that trades readability for speed with no profiling data or performance budget behind it (§5) |
| 🟢 **INFO** | A third near-identical occurrence of logic that hasn't been extracted yet — the rule-of-three threshold (§1); a module mixing two concerns that haven't caused a problem yet but will complicate the next change (§3); a vendor-specific type used correctly in an adapter/infrastructure file, flagged only to confirm the boundary is intentional (§4); a design that solves the requirement through noticeably more indirection than a simpler alternative would, where the extra machinery is not yet causing harm (§5) |

## 8. Applying This Standard with a Limited Scope

When reviewing or modifying code in a **specific set of files**, follow these constraints:

1. **Only apply these principles within the approved Core scope.** If a DRY/YAGNI/SoC/agnosticism/KISS violation exists outside Core, apply the Impact Zone / backlog handling below rather than editing it directly.
2. **Extracting a shared abstraction (DRY) that would live outside Core** is not automatically in scope — a third-occurrence duplication is real, but the extraction target may fall in the Impact Zone or Outside. Justify it as a coherence change only if leaving the duplication would make the Core change itself incoherent; otherwise, backlog it.
3. **Removing genuinely unused speculative code (YAGNI) is always in scope** when it's inside a file you're already modifying — deleting dead flexibility nobody uses is a required cleanup, not an opportunistic change.
4. **Simplifying (KISS) code you are already changing is in scope; simplifying code you are not is not.** Reducing the machinery of a function this task already modifies is ordinary cleanup. Rewriting an over-engineered module the task merely calls is a separate change — backlog it, so the simplification gets reviewed on its own merits rather than riding along inside an unrelated diff.
5. **Do not perform a large-scale SoC/agnosticism refactor** (splitting a module, introducing a new port/interface layer across many callers) as a side effect of an unrelated task — propose it separately so the diff is reviewable on its own.

**Handling violations outside the Core scope** (per [`rules.md`](../rules.md) → Scope-Locking — Three Zones): a file is either in the **Impact Zone** (a dependent or dependency of a file already in Core, discoverable via `devflow-ctl scope impact <file>`) or **Outside**.
- **Impact Zone + one of the six closed coherence reasons** (broken caller, broken import, contract violation, duplicated logic the task just introduced, a test that now fails, a type/schema that must change together): fix it, then record `devflow-ctl scope justify <file> "<reason>"`.
- **Impact Zone without a closed coherence reason, or Outside entirely:** do not edit it. Defer it instead: `devflow-ctl backlog add <file> "<reason>" --severity {incomplete|info}` — use `incomplete` if the in-scope change is functionally incoherent without that follow-up, `info` if it is a separate improvement.
