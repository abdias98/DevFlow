# DevFlow Engineering Standards: Error Handling (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-06-15

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
  - When intentionally ignoring an error, make it explicit with a comment stating *why* it is safe to ignore.
- **DON'T:**
  - Write empty catch blocks, or catch-and-continue that discards the error (no log, no rethrow). *(Blocker.)*
  - Catch a broad/base error type to suppress all failures indiscriminately.
  - Return success after an operation failed, producing misleading downstream state.

## 3. Catch Specifically; Preserve the Cause

- **What:** Handle the errors you understand; let the rest propagate. Never lose the original failure.
- **DO:**
  - Catch the narrowest error type that you can meaningfully handle.
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
  - Log the full technical detail internally (see [logging.md](./logging.md) §5) instead of returning it.
- **DON'T:**
  - Return stack traces, exception messages, internal paths, or SQL to external clients. *(Blocker — also `security.md`.)*
  - Use the same error body for "invalid input" and "internal failure" — callers cannot react correctly.

## 6. Resource Cleanup & Consistency

- **What:** Failures must not leak resources or leave data half-written.
- **DO:**
  - Release resources (connections, files, locks, handles) deterministically on every path, using the language's scope-guard / finally / using / defer mechanism.
  - Keep multi-step state changes atomic — use a transaction or a compensating action so a mid-way failure does not leave inconsistent state.
- **DON'T:**
  - Rely on the success path alone to free resources — an exception will skip it.
  - Leave a partially-mutated aggregate when one of several writes fails.

## 7. Errors vs. Control Flow

- **What:** Exceptions are for exceptional conditions, not normal branching.
- **DO:**
  - Use return values / result types / optionals for expected outcomes (not found, validation failed) where that is idiomatic for the stack.
  - Reserve thrown exceptions for genuinely unexpected or unrecoverable conditions.
- **DON'T:**
  - Use exceptions to implement ordinary control flow (e.g., throwing to break a loop).
  - Swing to the opposite extreme and encode failures as magic numbers/strings the caller may forget to check.

## 8. Retries & Transient Failures

- **What:** Transient failures may be retried — but carelessly.
- **DO:**
  - Retry only **idempotent** operations, with bounded attempts and backoff (prefer jitter); give up with a clear terminal error.
  - Distinguish retryable (timeout, 503) from non-retryable (validation, auth) failures.
- **DON'T:**
  - Retry a non-idempotent operation (e.g., "charge card") without an idempotency key — it can duplicate effects.
  - Retry in a tight unbounded loop with no backoff or cap.

## 9. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `error-handling.md §2`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Empty catch / catch-and-continue that discards the error — no log, no rethrow (§2); raw stack trace, exception message, or internal detail returned to an external caller (§5); failure path leaves a resource leaked or data in an inconsistent/partially-written state (§6); non-idempotent operation retried with no idempotency guard (§8) |
| 🟡 **WARN** | Catching the base/broadest error type to handle, without rethrow (§3); wrapping an error without chaining the original cause (§3); infrastructure error leaking raw across a layer boundary (§4); exceptions used for ordinary control flow (§7); unbounded or backoff-less retry (§8); continuing with a default/sentinel after a failure instead of failing fast (§1) |
| 🟢 **INFO** | Generic error message could be more actionable (§5); expected outcome modeled as a thrown exception where a result type would read better (§7); missing correlation ID in the surfaced error (§5) |

## 10. Applying This Standard with a Limited Scope

When reviewing or modifying error handling in a **specific set of files**, follow these constraints:

1. **Only change error handling within the approved scope.** If out-of-scope code swallows errors or leaks internals, flag it as a finding (WARN/BLOCK note) rather than editing it.
2. **Fixing a swallowed error or an internal-detail leak is always in scope** when it occurs in a file you are already modifying — it is a required fix, not an opportunistic change.
3. **Do not introduce a new global error model, middleware, or result-type library** unless that file is explicitly in scope; conform to the existing error-handling pattern.
4. **When adding error handling to satisfy this standard**, match the project's existing error types, boundary-translation pattern, and surfacing conventions rather than inventing new ones.
