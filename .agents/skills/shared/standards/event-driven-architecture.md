# DevFlow Engineering Standards: Event-Driven Architecture (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-09-08

> **Apply only if:** the project communicates via events, message queues, a message broker, or streams (producers publishing, consumers subscribing) — including in-process domain events dispatched after a transaction commits.
> If the project has no asynchronous event/message flow, skip this standard entirely.

> **Note on examples:** All broker/queue names (Kafka, RabbitMQ, SQS, in-process event bus) are illustrative. Replace them with the actual messaging infrastructure of the detected stack.

Apply these principles to any producer, consumer, event schema, or messaging infrastructure you design, generate, or review.

## 1. Producers & Consumers

- **What:** An event is a public contract between whoever publishes it and everyone who might ever consume it — the producer usually doesn't know who's listening.
- **DO:**
  - Name events for the fact that occurred, in the past tense (`OrderPlaced`, `PaymentDeclined`), not for an instruction (`PlaceOrder`) — an event is a statement of fact, not a command.
  - Keep a producer ignorant of its consumers. A producer that reaches into consumer-specific logic ("if the email service is listening, format this differently") has turned a decoupled event into a disguised direct call.
  - Document the event's contract (schema, guaranteed fields) as a first-class artifact consumers can rely on, the same way an API endpoint's contract is documented.
- **DON'T:**
  - Let a consumer assume delivery order or timing relative to other events unless the transport explicitly guarantees it (see §4).
  - Publish an event as a side effect buried inside unrelated logic with no clear point in the code where "this is now public" happens.

## 2. Delivery Guarantees & Idempotency

- **What:** Most messaging infrastructure delivers **at-least-once** — a consumer may see the same event more than once (retries, redelivery after a crash, at-least-once brokers by design). Exactly-once delivery is not a real guarantee most systems provide; treating it as one is how duplicate side effects happen.
- **DO:**
  - Design every consumer to be safely re-runnable on the same event — see `concurrency.md` §5 (Idempotency & Exactly-Once Illusions) for the deduplication mechanism (idempotency key, dedup table, conditional write) this requires.
  - Make the side effect of processing an event idempotent at the point where it matters (charging a card, sending an email, decrementing stock), not just "hope the event only arrives once."
- **DON'T:**
  - Apply a non-idempotent side effect (charge, ship, notify) directly from an event handler with no dedup guard.
  - Assume a message broker's "exactly-once" marketing claim removes the need for consumer-side idempotency — most such guarantees only cover the broker's internal delivery, not your side effect.

## 3. Event Schema & Versioning

- **What:** An event schema is a contract with every current and future consumer — some of whom you may never know about, running code you can't redeploy in lockstep with the producer.
- **DO:**
  - Version event schemas explicitly (a version field, or a versioned event type name) from the first event, even before a breaking change is anticipated.
  - Evolve schemas additively when possible (new optional fields) so old consumers keep working unmodified.
  - Publish (or otherwise make discoverable) the schema for every event type, the same way `rest-api.md` requires for HTTP contracts.
- **DON'T:**
  - Remove or repurpose an existing field's meaning in place — that silently breaks every consumer that hasn't been redeployed, with no error at publish time to catch it.
  - Let internal domain types leak directly into the event payload — a domain refactor should not require renegotiating every consumer's contract (see `design-principles.md` §4, technology/implementation agnosticism, applied here to the producer's internals).

## 4. Ordering

- **What:** Most event transports do not guarantee global ordering across all events, only (at best) ordering within a single partition/key.
- **DO:**
  - Design consumers to tolerate out-of-order delivery by default — derive state from the event's own timestamp/version, not from "the order I received them in."
  - When order genuinely matters for a specific stream (e.g., all events for one order ID), use the transport's partitioning/ordering key for that entity, and document that this is a hard requirement of the design.
- **DON'T:**
  - Assume two events published close together will be *consumed* close together, or in the order they were published, without a partitioning key enforcing it.

## 5. Dead-Letter Queues & Poison Messages

- **What:** A consumer will eventually fail to process some event — a schema it doesn't understand, a downstream dependency that's down, a bug. Without a plan for that, one bad message can block an entire queue or retry forever.
- **DO:**
  - Route an event that fails processing after a bounded number of retries to a dead-letter queue (or equivalent) instead of retrying indefinitely or dropping it silently.
  - Alert on dead-letter arrivals — a silent dead-letter queue is a data-loss bug waiting to be discovered much later.
- **DON'T:**
  - Retry a poison message forever, blocking every event behind it in the same partition/queue.
  - Silently drop an event that fails processing with no record it ever existed.

## 6. Event Sourcing vs. Simple Notification

- **What:** Not every event-driven system needs to be event-sourced. Distinguish three increasingly heavy patterns and pick the lightest one the requirement actually needs:
  - **Notification event** — "something happened," minimal payload, the consumer re-fetches current state if it needs detail. Lowest coupling, lowest complexity.
  - **Event-carried state transfer** — the event carries enough state that consumers don't need to call back to the producer. More coupling to the payload shape, but fewer round-trips.
  - **Event sourcing** — the event log itself is the source of truth; current state is a projection replayed from it. Enables full audit history and time-travel, at the cost of real complexity (replay logic, snapshotting, schema evolution across the entire history).
- **DO:**
  - Default to the notification event — it's the least commitment and the easiest to evolve.
  - Reach for event-carried state transfer only when the round-trip cost of re-fetching is a proven, measured problem (`performance.md` §6 — measure before optimizing).
  - Reach for event sourcing only when the audit-trail/replay requirement is real and stated, not speculative — this is exactly the kind of heavier pattern `design-principles.md` §2 (YAGNI) warns against adopting "because it might be useful."
- **DON'T:**
  - Adopt event sourcing as the default architecture for a new event-driven feature without a concrete requirement (full audit history, temporal queries, replay-based recovery) driving that choice specifically.

## 7. CQRS (Command Query Responsibility Segregation)

- **What:** CQRS separates the model that handles writes (commands) from the model that serves reads (queries) — often, though not necessarily, synchronized via the events this standard governs. It solves a specific problem: when the read and write models have genuinely different shapes, or read and write load need to scale independently.
- **DO:**
  - Apply CQRS only when there's a concrete, current reason: read and write models have diverged significantly (a write model normalized for consistency, a read model denormalized for a specific UI), or read/write load must scale independently and a single model can't serve both efficiently.
  - When applied, keep the write model as the single source of truth and treat the read model(s) as derived, rebuildable projections — never let a read model become an undocumented second source of truth.
  - State explicitly, in the design, how the read model is kept in sync (synchronously in the same transaction, or asynchronously via the events this standard governs) and what staleness window that implies.
- **DON'T:**
  - Introduce CQRS as a default "best practice" for a new feature with no concrete symptom (measured query complexity, measured scaling mismatch) driving it — this is the single most common instance of `design-principles.md` §2 (YAGNI) being violated in event-driven designs. The added complexity (two models, synchronization logic, eventual consistency the UI must account for) is real and paid immediately; the benefit is often speculative.
  - Let the read side silently diverge from the write side with no reconciliation or rebuild path — an unrebuildable read model is a data-loss risk disguised as a performance optimization.

## 8. Code Review Checklist
When reviewing, verify:
- [ ] Event names describe a fact that occurred (past tense), and producers have no consumer-specific logic (§1).
- [ ] Every consumer is idempotent against redelivery of the same event, per the dedup mechanism `concurrency.md` §5 requires (§2).
- [ ] Event schemas are versioned, and a change is additive rather than repurposing an existing field (§3).
- [ ] Consumers don't assume delivery order unless a partitioning/ordering key explicitly guarantees it for that stream (§4).
- [ ] A failed event has a dead-letter path with alerting — not infinite retry or a silent drop (§5).
- [ ] The lightest pattern (notification event) was chosen unless a concrete requirement justified event-carried state transfer or event sourcing (§6).
- [ ] If CQRS is used, there's a concrete, stated reason for it, and the read model has a documented rebuild path from the write model (§7).

## 9. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `event-driven-architecture.md §2`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Non-idempotent side effect (charge, ship, notify) triggered directly from an event handler with no dedup guard (§2); a failed event retried forever with no dead-letter path, blocking the queue/partition behind it (§5) |
| 🟡 **WARN** | Event schema change that repurposes or removes an existing field in place, breaking undeployed consumers (§3); consumer logic that assumes delivery order with no partitioning/ordering key backing that assumption (§4); dead-letter queue with no alerting configured (§5); event sourcing or CQRS adopted with no concrete, stated requirement driving it — see `design-principles.md` §2 (§6, §7) |
| 🟢 **INFO** | Event name phrased as a command rather than a fact (§1); event payload carries more state than any current consumer needs (event-carried state transfer chosen without a measured round-trip cost) (§6); read model in a CQRS design with no documented staleness window (§7) |

## 10. Applying This Standard with a Limited Scope

When reviewing or modifying event-driven code in a **specific set of files**, follow these constraints:

1. **Only change producers/consumers within the approved Core scope.** If an out-of-scope consumer has no idempotency guard, apply the Impact Zone / backlog handling below rather than editing it directly.
2. **Adding an idempotency guard to a consumer you're already modifying is always in scope** — it's a required fix, not an opportunistic change, per §2.
3. **Do not introduce a new message broker, event bus, or messaging pattern (event sourcing, CQRS)** unless that integration is explicitly in scope; use the project's existing transport and pattern.
4. **A schema version bump for an event you're already modifying is in scope**; renegotiating every other consumer's contract as a result is not — flag those consumers via the Impact Zone / backlog handling below instead of updating them unconditionally.

**Handling violations outside the Core scope** (per [`rules.md`](../rules.md) → Scope-Locking — Three Zones): a file is either in the **Impact Zone** (a dependent or dependency of a file already in Core, discoverable via `devflow-ctl scope impact <file>`) or **Outside**.
- **Impact Zone + one of the six closed coherence reasons** (broken caller, broken import, contract violation, duplicated logic the task just introduced, a test that now fails, a type/schema that must change together): fix it, then record `devflow-ctl scope justify <file> "<reason>"`.
- **Impact Zone without a closed coherence reason, or Outside entirely:** do not edit it. Defer it instead: `devflow-ctl backlog add <file> "<reason>" --severity {incomplete|info}` — use `incomplete` if the in-scope change is functionally incoherent without that follow-up, `info` if it is a separate improvement.
