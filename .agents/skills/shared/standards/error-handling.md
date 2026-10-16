# DevFlow Engineering Standards: Error Handling (Technology-Agnostic)

> **Version:** 1.4.1 | **Last Updated:** 2026-10-12

> **Note on examples:** All exception types, result wrappers, and code fragments are illustrative. Replace them with the actual error model, libraries, and conventions of the detected stack.

Apply these principles to all code you design, generate, or review that can fail. This standard governs how errors are raised, propagated, surfaced, and recovered from. For how errors are *recorded*, see [logging.md](./logging.md).

## 1. Fail Fast, Fail Loud

- **What:** Detect invalid state at the earliest point and stop, rather than continuing on bad data.
- **DO:**
  - Validate preconditions and inputs at the boundary and raise immediately when they are violated.
  - Make illegal states unrepresentable where the type system allows (non-null, value objects, enums) so whole error classes cannot occur.
  - Treat a partially-applied operation as a failure, not a partial success.
- **DON'T:**
  - Continue executing with `null`/default/sentinel values hoping the problem resolves itself downstream.
  - Mask a failure by returning an empty result that the caller cannot distinguish from a legitimate empty result.

## 2. Never Swallow Errors

- **What:** Every error must be handled, propagated, or deliberately and visibly ignored — never silently dropped.
- **DO:**
  - Catch only when you can add value: recover, translate, enrich with context, or log-and-rethrow at a boundary.
  - When intentionally ignoring an error, use an explicit API that states the intent in code (`void` operator, `catch (_ignored)` with an underscore-prefixed binding, or the stack's documented "intentionally unhandled" marker) plus a comment stating *why* it is safe to ignore — a bare comment next to an empty catch is not sufficient.
  - In stacks without typed catch (JS/TS), catch `unknown` and narrow explicitly (`typeof` checks, `instanceof`, discriminated-union guards) before handling — never assume the caught value is an `Error` with a message and stack.
- **DON'T:**
  - Write empty catch blocks, or catch-and-continue that discards the error (no log, no rethrow). *(Blocker.)*
  - Catch a broad/base error type to suppress all failures indiscriminately.
  - Return success after an operation failed, producing misleading downstream state.

## 3. Catch Specifically; Preserve the Cause

- **What:** Handle the errors you understand; let the rest propagate. Never lose the original failure.
- **DO:**
  - Catch the narrowest error type that you can meaningfully handle.
  - In JS/TS there is no typed catch to narrow with: the catch clause receives `unknown`, so the narrowing happens in the body — discriminate before use, and re-raise whatever the guards do not recognize.
  - When wrapping/translating an error into a domain or layer-appropriate type, **chain the original cause** (inner exception / `cause`) so the stack trace is preserved.
  - Re-raise unknown errors unchanged rather than absorbing them.
- **DON'T:**
  - Catch the base exception type unless you immediately rethrow.
  - Throw away the original error when wrapping — a new message with no cause destroys diagnosability.

## 4. Translate Errors at Layer Boundaries

- **What:** Each layer should expose errors in its own vocabulary, not leak lower-layer details.
- **DO:**
  - Convert infrastructure errors (DB, network, file) into domain or use-case errors at the boundary, preserving the cause.
  - Keep error types meaningful to the layer that receives them.
- **DON'T:**
  - Let a database/driver exception propagate raw to the UI or API surface.
  - Expose internal implementation details (SQL, file paths, library internals) to outer layers or callers.

## 5. Safe Error Surfaces (User / API)

- **What:** What the caller or end user sees must be helpful but must not leak internals.
- **DO:**
  - Return generic, actionable messages to external callers ("Unable to process payment") plus a correlation ID for support.
  - Map error categories to the right transport semantics (e.g., validation vs. auth vs. not-found vs. server error) — see [rest-api.md](./rest-api.md) where APIs are involved.
  - Log the full technical detail internally (see [logging.md](./logging.md) §6) instead of returning it.
- **DON'T:**
  - Return stack traces, exception messages, internal paths, or SQL to external clients. *(Blocker — canonical citation: this section, `error-handling.md §5`; `security.md §6` cross-references it as the security angle on the same finding.)*
  - Use the same error body for "invalid input" and "internal failure" — callers cannot react correctly.

## 6. Resource Cleanup & Consistency

- **What:** Failures must not leak resources or leave data half-written.
- **DO:**
  - Release resources (connections, files, locks, handles) deterministically on every path, using the language's scope-guard / finally / using / defer mechanism.
  - Keep multi-step state changes atomic — use a transaction or a compensating action so a mid-way failure does not leave inconsistent state.
  - Handle a failure that occurs *during* cleanup/rollback itself explicitly (log it, chain it, or surface it) — a cleanup action is not guaranteed to succeed just because it runs in a `finally`/`catch` block.
- **DON'T:**
  - Rely on the success path alone to free resources — an exception will skip it.
  - Leave a partially-mutated aggregate when one of several writes fails.
  - Let a secondary exception thrown while cleaning up after the original failure silently replace or discard the original error with no trace of either.

## 7. Errors vs. Control Flow

- **What:** Exceptions are for exceptional conditions, not normal branching.
- **DO:**
  - Use return values / result types / optionals for expected outcomes (not found, validation failed) where that is idiomatic for the stack.
  - Reserve thrown exceptions for genuinely unexpected or unrecoverable conditions.
- **DON'T:**
  - Use exceptions to implement ordinary control flow (e.g., throwing to break a loop).
  - Swing to the opposite extreme and encode failures as magic numbers/strings the caller may forget to check.

## 8. Retries & Transient Failures

- **What:** Transient failures may be retried — but carelessly. The idempotency mechanism that makes a retry safe (idempotency key, dedup table, conditional write) is owned canonically by `concurrency.md` §5 — this section owns *when* a retry is appropriate, not the mechanism itself.
- **DO:**
  - Retry only **idempotent** operations, with bounded attempts and backoff (prefer jitter); give up with a clear terminal error.
  - Distinguish retryable (timeout, 503) from non-retryable (validation, auth) failures.
  - Classify every failure before retrying: retryable means the operation may succeed unchanged on a later attempt (timeout, 503, throttling); fatal means retrying the same payload can never succeed (validation, auth, malformed request) — fatal failures must surface immediately, never enter the retry loop.
  - Give retried operations stable, documented error codes so callers can distinguish "failed after retries" from "never attempted" without parsing messages.
- **DON'T:**
  - Retry a non-idempotent operation (e.g., "charge card") without the idempotency guard defined in `concurrency.md` §5 — it can duplicate effects.
  - Retry in a tight unbounded loop with no backoff or cap.
  - Call `panic`/`unwrap`/`expect` (or the stack's equivalent crash-on-error) on recoverable paths — reserve crashing for violated invariants the program cannot meaningfully continue from, never for input, I/O, or remote-call failures.

## 9. Code Review Checklist
When reviewing, verify:
- [ ] Invalid state is rejected at the boundary — no continuing on `null`/default/sentinel values hoping it resolves downstream (§1).
- [ ] No empty catch blocks or catch-and-continue that discards the error (§2).
- [ ] Caught errors are narrowly typed (or `unknown` narrowed explicitly where the stack has no typed catch), and the original cause is chained when wrapped/translated (§3).
- [ ] Intentionally ignored errors use an explicit API (`void`, `catch (_ignored)`, or the stack marker) with a why-comment — no bare empty catch (§2).
- [ ] Infrastructure errors are translated to domain/layer-appropriate types at boundaries — no raw DB/network exception leaking outward (§4).
- [ ] External-facing errors are generic and actionable — no stack trace, internal detail, or SQL returned to a caller (§5).
- [ ] Resources are released on every path (success and failure); multi-step state changes are atomic or compensated (§6).
- [ ] Exceptions are reserved for exceptional conditions, not used for ordinary control flow (§7).
- [ ] Retries apply only to idempotent operations, are bounded, and use backoff (§8).

## 10. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `error-handling.md §2`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Empty catch / catch-and-continue that discards the error — no log, no rethrow (§2); raw stack trace, exception message, or internal detail returned to an external caller (§5); failure path leaves a resource leaked or data in an inconsistent/partially-written state (§6) |
| 🟡 **WARN** | Catching the base/broadest error type to handle, without rethrow (§3); catching without narrowing an `unknown` value before use in stacks with no typed catch (§3); wrapping an error without chaining the original cause (§3); infrastructure error leaking raw across a layer boundary (§4); exceptions used for ordinary control flow (§7); unbounded or backoff-less retry (§8); retrying without an idempotency guard — judged under the canonical rule in `concurrency.md` §5 and recorded there, never as a second BLOCK here for this retry rule (§8); `panic`/`unwrap` on a recoverable input, I/O, or remote-call failure path (§8); continuing with a default/sentinel after a failure instead of failing fast (§1); a failure during cleanup/rollback itself is neither logged nor chained, silently losing either the original or the cleanup error (§6) |

| 🟢 **INFO** | Generic error message could be more actionable (§5); expected outcome modeled as a thrown exception where a result type would read better (§7); missing correlation ID in the surfaced error (§5) |

## 11. Applying This Standard with a Limited Scope

When reviewing or modifying error handling in a **specific set of files**, follow these constraints:

1. **Only change error handling within the approved Core scope.** If out-of-scope code swallows errors or leaks internals, apply the Impact Zone / backlog handling below rather than editing it directly.
2. **Fixing a swallowed error or an internal-detail leak is always in scope** when it occurs in a file you are already modifying — it is a required fix, not an opportunistic change.
3. **Do not introduce a new global error model, middleware, or result-type library** unless that file is explicitly in scope; conform to the existing error-handling pattern.
4. **When adding error handling to satisfy this standard**, match the project's existing error types, boundary-translation pattern, and surfacing conventions rather than inventing new ones.

**Handling violations outside the Core scope** (per [`rules.md`](../rules.md) → Scope-Locking — Three Zones): a file is either in the **Impact Zone** (a dependent or dependency of a file already in Core, discoverable via `devflow-ctl scope impact <file>`) or **Outside**.
- **Impact Zone + one of the six closed coherence reasons** (broken caller, broken import, contract violation, duplicated logic the task just introduced, a test that now fails, a type/schema that must change together): fix it, then record `devflow-ctl scope justify <file> "<reason>"`.
- **Impact Zone without a closed coherence reason, or Outside entirely:** do not edit it. Defer it instead: `devflow-ctl backlog add <file> "<reason>" --severity {incomplete|info}` — use `incomplete` if the in-scope change is functionally incoherent without that follow-up, `info` if it is a separate improvement.

## 12. Design-Time Decisions

The spec should state these alongside the data flow — error behavior that is not designed gets improvised differently in every handler.

- **Failure modes** — for each operation, the expected outcomes (validation failure, not found, conflict) versus the unexpected ones (§1, §7).
- **Error vocabulary per layer** — the error types each layer exposes and the points where lower-layer errors are translated (§4).
- **Caller-facing surface** — what the user or API caller sees for each error category, and how each maps to transport semantics (§5).
- **Atomicity** — which multi-step changes need a transaction or a compensating action (§6).
- **Retry policy** — which operations may be retried, how their idempotency is guaranteed (mechanism per the canonical rule in `concurrency.md` §5), and the attempt bound (§8).
- **Raise-vs-result choice** — for each expected outcome, whether it raises or returns a Result/Optional value, per the decision table (§14).

## 13. Implementation Self-Check

Before marking a task done:

- [ ] Every catch recovers, translates with the cause chained, or rethrows — none silently discards (§2, §3).
- [ ] Expected outcomes use the stack's idiom for results or typed errors, not generic exceptions (§7).
- [ ] Every failure path releases the resources acquired before it (§6).
- [ ] A failure halfway through leaves no partial write visible to readers (§6).
- [ ] Retries run only on idempotent operations, with a cap and backoff (§8).
- [ ] No external response carries a stack trace or internal message (§5).

## 14. Fail-Fast vs. Result/Optional Decision

- **What:** Callers must know whether an expected outcome raises or returns — mixing both for the same case forces every caller to handle it twice.
- **Decision table:**

| Situation | Model it as | Rationale |
|---|---|---|
| Invalid input or violated precondition at a boundary | Raise (fail fast, §1) | The caller broke the contract — stop immediately rather than returning a value the caller may forget to check |
| Sought entity does not exist (NotFound) and absence is an expected outcome | Result/Optional (absent value) | Lookup misses are ordinary flow (unknown id, empty relation) — the caller branches on presence, not on a catch block |
| Validation of user-supplied data with multiple reportable problems | Result carrying all failures | Raising on the first failure hides the remaining problems from the caller |
| Unexpected infrastructure failure (I/O, remote call, persistence) | Raise | The caller cannot proceed meaningfully — propagate with the cause chained per §3 |
| Outcome the caller must always handle explicitly | Result/Optional, never a sentinel | A magic value or `null` return is silently ignorable; a Result type forces handling at the type level |

- **DON'T:**
  - Return `null` or a sentinel for NotFound in one function and raise NotFoundError for the same case in another — pick one per operation and document it.
  - Raise for expected lookup absence on a hot path where catching costs more than branching — prefer the Optional return there.
