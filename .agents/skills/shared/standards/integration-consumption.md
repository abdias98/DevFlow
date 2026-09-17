# DevFlow Engineering Standards: Integration Consumption (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-09-17

> **Apply when:** the code *calls out* to an external service, API, or integration it does not control — a third-party HTTP API, another team's service, a payment gateway, a cloud provider SDK. This standard is the **client (consumer) side**; `rest-api.md` owns the *server* side of exposing an endpoint, and `event-driven-architecture.md` owns asynchronous producer/consumer contracts. A call to your own service's other internal layer (e.g., a use case calling a repository in the same process) is not an "integration" in this sense unless it crosses a network boundary.

Most of what makes an integration fail in production is invisible in a quick manual test against a fast, healthy dependency: a slow provider, a provider that is down, a provider that returns a shape slightly different from the happy-path example. This standard covers what a call to something outside your control must handle regardless of how well-behaved that dependency looked during development.

## 1. Timeouts on Every Call

- **What:** A call with no timeout can hang the caller for as long as the remote side takes — which, for a degraded dependency, can be indefinitely.
- **DO:**
  - Set an explicit timeout on every outbound call, sized to what the caller can actually tolerate (not the client library's default, which is often unbounded or far too generous).
  - Distinguish connect timeout from total-response timeout where the client library allows it.
- **DON'T:**
  - Rely on the underlying transport's default (or absence of a default) as the timeout policy.
  - Set a timeout so long that a single slow dependency call exhausts the caller's own resources (threads, connections, request budget) before it fires.

## 2. Cancellation Propagates

- **What:** When the caller no longer needs the result (the user navigated away, the parent request was cancelled, a newer request superseded this one), the outbound call should stop consuming resources rather than run to completion for nothing.
- **DO:**
  - Propagate cancellation (an `AbortController`/`CancellationToken`/context deadline, or the stack's equivalent) from the caller's own cancellation source into the outbound call.
  - Treat this as the network-crossing instance of `state-lifecycle.md` §7 ("work performed only when consumed") — cancel the call, don't just discard its eventual result.
- **DON'T:**
  - Let an outbound call run to completion after the caller has moved on, "since it'll finish soon anyway" — under load, it won't.

## 3. Retries Only on Idempotent Operations

- **What:** Retrying a failed call can duplicate its effect if the operation is not safe to run twice.
- **DO:**
  - Retry only operations that are idempotent, or that carry an idempotency key the provider honors (`concurrency.md` §5 owns the idempotency mechanism itself; this section owns *when a client-side retry is safe to attempt at all*).
  - Retry with a bounded attempt count and backoff (with jitter) for transient failures (timeout, 502/503, connection reset); never in a tight unbounded loop.
  - Distinguish retryable failures (transient) from non-retryable ones (validation error, auth failure, 4xx client errors that won't change on retry) — see `error-handling.md` §8 for the general retry rule this section applies at the integration boundary.
- **DON'T:**
  - Retry a non-idempotent operation (charge, send, create) with no idempotency guard — a retried "create payment" call can create two payments.
  - Retry indefinitely with no cap, turning a transient outage into a self-inflicted traffic amplification against the failing dependency.

## 4. Observable States During the Wait

- **What:** A caller — a UI, another service, an operator — needs to know whether an integration call is in flight, succeeded, or failed; leaving no signal until the call resolves makes a slow or hung dependency indistinguishable from the caller itself being broken.
- **DO:**
  - Expose a loading/pending state for the duration of an outbound call that a user-facing caller can render.
  - Surface a distinct state for "the dependency failed" versus "no data exists" — these are different facts and callers that conflate them mislead whoever reads the result.
- **DON'T:**
  - Leave the caller with no way to tell "still waiting" from "silently stuck."

## 5. Partial, Slow, and Stale Responses

- **What:** A dependency can return a response that is technically successful but incomplete, degraded, or delayed enough that it is no longer the most current answer.
- **DO:**
  - Handle a paginated or partial response explicitly — decide whether the caller needs the full set before proceeding, or can act on a partial one.
  - Where the dependency supports it, prefer an approach that lets a fast, current response win over a slow, superseded one for the same logical request (`state-lifecycle.md` §6 owns discarding a superseded response once one has already been applied to state).
- **DON'T:**
  - Assume every successful response is complete just because it returned a 2xx / success status.

## 6. Degradation Strategy

- **What:** When the integration cannot be reached or exhausts its retries, the caller needs a defined fallback rather than an unhandled failure propagating arbitrarily.
- **DO:**
  - Decide explicitly, per integration point, whether a failure should: fail the caller's operation visibly, fall back to a cached/default value, or degrade a feature gracefully (e.g., hide a recommendation panel rather than fail the whole page).
  - Apply a circuit breaker or similar backpressure mechanism for a dependency that is known to fail repeatedly, so the caller stops hammering a service that is already down.
- **DON'T:**
  - Let a single failing non-critical integration take down an operation that does not actually depend on its result.

## 7. Typed Contracts at the Boundary

- **What:** The shape an external provider returns is that provider's shape, not your domain's — code that reaches deep into a raw provider response couples the caller to a contract it does not own and cannot version.
- **DO:**
  - Parse and validate the provider's response into a type/shape the caller's own code defines, at the boundary, before the data enters domain or application logic (`clean-architecture.md` owns keeping this translated shape out of inner layers once it crosses the boundary; this section owns performing the translation at all).
  - Treat an unexpected field, a missing field, or a changed enum value from the provider as a handled case, not a crash.
- **DON'T:**
  - Pass the provider's raw response object through several layers of your own code, letting its field names and quirks leak into business logic.
  - Assume the external contract is stable just because it hasn't changed yet.

## 8. Code Review Checklist
When reviewing, verify:
- [ ] Every outbound call to an external integration has an explicit timeout (§1).
- [ ] Cancellation from the caller propagates into the outbound call where the client library and protocol support it (§2).
- [ ] Retries only happen on idempotent operations or ones with an idempotency key, are bounded, and use backoff (§3).
- [ ] A loading/pending state and a distinct failure state are exposed to callers for the duration of the call (§4).
- [ ] Partial or paginated responses are handled explicitly, not silently treated as complete (§5).
- [ ] A degradation strategy exists for when the integration is unreachable or exhausted its retries (§6).
- [ ] The external response is parsed into an owned type at the boundary before reaching domain/application code (§7).

## 9. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `integration-consumption.md §3`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | A non-idempotent operation (charge, send, create) is retried with no idempotency guard (§3, canonical citation `concurrency.md §5`); no timeout on a call whose hang can exhaust a shared resource pool (e.g., a request-handling thread pool) (§1); a raw, unvalidated provider response is passed directly into domain/business logic with no boundary translation, and a malformed field would crash it (§7) |
| 🟡 **WARN** | No explicit timeout on an outbound call, even without a demonstrated pool-exhaustion path (§1); cancellation from the caller does not propagate into the outbound call (§2); an unbounded/uncapped retry loop with no backoff for a non-critical retry (§3); no distinct failure state exposed to the caller — errors are indistinguishable from "still loading" (§4); no degradation strategy defined for a non-critical integration whose failure currently fails the whole operation (§6) |
| 🟢 **INFO** | A partial/paginated response is handled but not explicitly documented as a design decision (§5); provider response validated but the failure path for an unexpected shape only logs rather than degrading gracefully (§7) |

## 10. Applying This Standard with a Limited Scope

When applying this standard to a **specific set of files or modules** (the declared Core scope), follow these constraints:

1. **Only modify files inside Core directly.** If an integration-consumption violation is found in a client outside Core, apply the Impact Zone / backlog handling below rather than editing it unconditionally.
2. **Adding a missing timeout, cancellation propagation, or idempotency guard within a file already in Core is always allowed** — required fixes for code already being touched.
3. **Introducing a circuit breaker or new resilience library is not automatically in scope** — if the project already has one, use it; if it doesn't and this task doesn't call for adding one, prefer a bounded retry/timeout as the minimal fix and backlog the broader resilience story.
4. **Boundary translation types belong in Core** if the integration client itself is in Core; if the raw-shape leak originates in a shared client outside Core, defer per the handling below.
5. **Do not change the external provider's contract usage (a different API version, a different endpoint) as a side effect** of a consumption-hardening fix — that is a separate, deliberate change.

**Handling violations outside the Core scope** (per [`rules.md`](../rules.md) → Scope-Locking — Three Zones): a file is either in the **Impact Zone** (a dependent or dependency of a file already in Core, discoverable via `devflow-ctl scope impact <file>`) or **Outside**.
- **Impact Zone + one of the six closed coherence reasons** (broken caller, broken import, contract violation, duplicated logic the task just introduced, a test that now fails, a type/schema that must change together): fix it, then record `devflow-ctl scope justify <file> "<reason>"`.
- **Impact Zone without a closed coherence reason, or Outside entirely:** do not edit it. Defer it instead: `devflow-ctl backlog add <file> "<reason>" --severity {incomplete|info}` — use `incomplete` if the in-scope change is functionally incoherent without that follow-up, `info` if it is a separate improvement.

## 11. Design-Time Decisions

Record these in the spec's **Standards Applied** table, typically materialized in the **API Contract** section (for the provider side of the boundary) and **Design Decisions**:

- **Timeout budget** — the timeout for each outbound call, and how it fits within the caller's own SLA/timeout budget (§1).
- **Cancellation path** — whether and how the caller's own cancellation source reaches this call (§2).
- **Retry policy** — which operations are safe to retry, their idempotency mechanism, attempt bound, and backoff (§3).
- **Observable states** — the loading/success/error/degraded states this integration point exposes (§4).
- **Response completeness handling** — how partial/paginated/stale responses are handled (§5).
- **Degradation decision** — fail visibly, fall back, or degrade gracefully — per integration point (§6).
- **Boundary type** — the shape this integration's response is translated into before entering domain code (§7).

## 12. Implementation Self-Check

Before marking a task done:

- [ ] Every new outbound call has an explicit timeout (§1).
- [ ] Cancellation propagates where the design decided it should (§2).
- [ ] No non-idempotent call was made retryable without an idempotency guard (§3).
- [ ] The caller can distinguish loading, success, error and (if applicable) degraded states (§4).
- [ ] Partial/paginated responses are handled per the design decision, not assumed complete (§5).
- [ ] The degradation path decided at design time is implemented, not left as an unhandled exception (§6).
- [ ] The provider's raw response never reaches domain/application code unparsed (§7).
