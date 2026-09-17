# DRY Policy for the Standards Themselves

> This is a meta-policy about the engineering standards under `shared/standards/` as documents — it governs how *DevFlow's own documentation* stays DRY. For the DRY principle applied to the *code a cycle produces*, see the DRY section of the design-principles standard (transversal principles, loaded by every cycle — see `standards-quick-card.md`).

## The problem this solves

Two standards independently explaining the same rule inevitably drift: one gets updated, the other doesn't, and a citation to either becomes ambiguous about which is "correct." This has happened concretely in this framework — `security.md` and `error-handling.md` both explained "don't return stack traces to callers" until one PR (F17) declared a canonical owner and made the other a cross-reference; the same happened for `dependencies.md`/`security.md`, `performance.md`/`concurrency.md`, and `clean-architecture.md`/`testing.md`. Those fixes were applied ad hoc, one pair at a time, with no general rule written down — so the next overlap (a new standard, or a new section in an existing one) has nothing to check itself against.

## The rule

When a topic is covered by more than one standard:

1. **Exactly one standard is the canonical owner** — the one whose subject matter the topic most specifically belongs to. It gets the full explanation: the DO/DON'T rules, the examples, the Severity Classification trigger.
2. **Every other standard that touches the same topic gets a one-line cross-reference**, not a re-explanation: `"see {standard}.md §{N} for the full rule"`. It may still cite the topic in its own Severity table (a security-angle citation of an error-handling rule is legitimate), but the citation notes which one is canonical, so a reviewer never logs the same finding under two unrelated section numbers.
3. **Prose duplication is a smell, not automatically a violation.** A short shared vocabulary word or a boilerplate phrase ("apply to all code you design, generate, or review") is fine. What must never happen is two standards independently explaining the *same rule* — the same DO/DON'T pair, the same rationale — in different words that will drift.

## Existing canonical-owner pairs (for reference — not exhaustive)

| Topic | Canonical owner | Cross-references from |
|---|---|---|
| Stack trace / internal detail exposed to a caller | `error-handling.md` §5 | `security.md` §6 |
| Supply-chain / dependency vulnerability depth | `dependencies.md` | `security.md` §5 |
| Fire-and-forget error handling, sync-over-async | `concurrency.md` §4 | `performance.md` §4 |
| Per-layer architectural testability | `clean-architecture.md` §5 | `testing.md` (intro) |
| Consumer-side idempotency / dedup mechanism | `concurrency.md` §5 | `event-driven-architecture.md` §2 |
| How to measure before optimizing (profiling, budgets) | `performance.md` §6 | `design-principles.md` §5 |
| Server-side cache mechanics (TTL, eviction, invalidation strategy) vs. general state invalidation | `performance.md` §3 | `state-lifecycle.md` §3 |
| Background/process-level task lifecycle vs. state-holding subscriptions/timers | `concurrency.md` §7 | `state-lifecycle.md` §5 |
| Async throughput cost of unnecessary work vs. state loaded/computed with no consumer | `performance.md` §4 | `state-lifecycle.md` §7 |
| Client-side retry safety / idempotency mechanism vs. when a retry is appropriate at all | `concurrency.md` §5 | `integration-consumption.md` §3 |
| General transient-failure retry rule vs. the integration-boundary application of it | `error-handling.md` §8 | `integration-consumption.md` §3 |
| Keeping a translated boundary shape out of inner layers vs. performing the translation | `clean-architecture.md` | `integration-consumption.md` §7 |
| Query-efficiency judgment (N+1, unbounded results) vs. the indexing that access patterns require | `performance.md` §2 | `data-persistence.md` §5 |
| Authorization for who may see a tenant's data vs. the schema/query mechanism enforcing isolation | `security.md` §2 | `data-persistence.md` §7 |
| Short-critical-section discipline for in-process locks vs. the same discipline for database transactions | `concurrency.md` §3 | `data-persistence.md` §3 |
| YAGNI (general: don't build for a hypothetical need) vs. its application to pattern/extension-point selection specifically | `design-principles.md` §2 | `design-patterns.md` §3 |
| Architectural pattern selection (layering, feature-based, hexagonal) vs. tactical pattern selection within a layer | `project-design.md` §2 | `design-patterns.md` §1 |
| OCP: extend rather than modify tested code vs. which tactical pattern implements that extension | `solid.md` §2 | `design-patterns.md` §1 |

When you find a new overlap, add the pair here after resolving it — this table is the audit trail of "who owns what," so the next overlap has precedent to follow instead of reinventing the resolution.

## How this is checked

`scripts/validate-framework.sh` §14 flags any two standards sharing a long, near-identical line of prose (not just a heading or a short phrase) as a WARN — a duplicated *sentence* is the concrete symptom of an unresolved overlap. It cannot tell you which one should be canonical; that judgment call is yours, guided by the rule above.
