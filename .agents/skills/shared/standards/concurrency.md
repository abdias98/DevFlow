# DevFlow Engineering Standards: Concurrency & Async (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-06-15

> **Note on examples:** All primitives (locks, queues, atomics, async constructs) are illustrative. Replace them with the actual concurrency model and libraries of the detected stack (threads, async/await, actors, goroutines, event loop, etc.).

Apply these principles to all code you design, generate, or review that runs concurrently, in parallel, or asynchronously, or that mutates state reachable by more than one execution context.

## 1. Shared Mutable State

- **What:** Data reachable by two execution contexts at once is the root of most concurrency bugs.
- **DO:**
  - Prefer immutability and message passing over shared mutable state. The safest shared state is no shared state.
  - Confine mutable state to a single owner (one thread/actor/task) and communicate via queues/channels.
  - When state must be shared, protect every access (read and write) with the same synchronization primitive.
- **DON'T:**
  - Read or write shared mutable variables from multiple contexts without synchronization.
  - Assume that operations which look atomic in source (`count++`, check-then-act) are atomic at runtime — they usually are not.
  - Share a non-thread-safe object (many collections, ORM sessions, HTTP clients with mutable config) across contexts assuming it is safe.

## 2. Atomicity & Race Conditions

- **What:** A race condition is when correctness depends on the unpredictable ordering of concurrent operations.
- **DO:**
  - Make compound "check-then-act" / "read-modify-write" sequences atomic — via a lock, a transaction, an atomic primitive, or a conditional/compare-and-set update.
  - Push invariants into the data store where possible (unique constraints, conditional/optimistic updates with a version column).
  - Treat "it worked in testing" as no evidence of correctness — races are timing-dependent and intermittent.
- **DON'T:**
  - Implement reserve/decrement-stock, balance updates, or unique-slug allocation as a non-atomic read-then-write.
  - Rely on the order in which concurrent tasks happen to run.

## 3. Locking Discipline

- **What:** Locks prevent races but introduce deadlocks, contention, and latency if used carelessly.
- **DO:**
  - Hold locks for the shortest critical section possible; do no slow/blocking work (I/O, network) while holding a lock.
  - Acquire multiple locks in a consistent global order to prevent deadlock; prefer a single lock or a lock-free structure where feasible.
  - Always release locks on every exit path (use the language's scope-guard / finally / defer).
- **DON'T:**
  - Perform blocking I/O or call external/unknown code while holding a lock.
  - Acquire nested locks in inconsistent orders across call sites (classic deadlock).
  - Leave a lock held on an error path.

## 4. Async Discipline

- **What:** Asynchronous code has its own hazards: lost results, blocked event loops, and swallowed failures.
- **DO:**
  - Await / join / observe every asynchronous operation whose result or failure matters; propagate cancellation.
  - Keep blocking or CPU-bound work off the event loop / request thread — offload to a worker or thread pool.
  - Bound concurrency (pools, semaphores, batching) instead of spawning unbounded parallel work.
- **DON'T:**
  - Fire-and-forget an async task where a failure means data loss, with no error handling (see also `performance.md` §4 and `error-handling.md` §2). *(Blocker.)*
  - Block a thread waiting on async work in a way that can exhaust the pool or deadlock (sync-over-async).
  - Mix blocking and non-blocking calls on the same hot path without understanding the runtime.

## 5. Idempotency & Exactly-Once Illusions

- **What:** In a concurrent/distributed system, messages and requests can arrive more than once or out of order.
- **DO:**
  - Make operations that may be retried or redelivered **idempotent** (idempotency key, dedup table, conditional write).
  - Design consumers to tolerate at-least-once delivery and reordering.
- **DON'T:**
  - Assume a message/request is processed exactly once.
  - Apply a non-idempotent side effect (charge, ship, send email) without a dedup guard (see also `error-handling.md` §8).

## 6. Safe Publication & Visibility

- **What:** A value written by one context is not guaranteed visible to another without proper synchronization.
- **DO:**
  - Publish shared data through the proper memory-visibility primitive (the platform's volatile/atomic/lock/happens-before mechanism).
  - Fully construct objects before making them visible to other contexts.
- **DON'T:**
  - Assume a plain write is immediately visible to other threads.
  - Leak a reference to a partially-initialized object (e.g., from within its own constructor) to another context.

## 7. Background Work & Lifecycle

- **What:** Long-running and background tasks need orderly startup, shutdown, and failure handling.
- **DO:**
  - Support graceful shutdown: stop accepting new work, drain or cancel in-flight work, release resources.
  - Supervise background tasks — detect and restart or surface failures rather than letting them die silently.
- **DON'T:**
  - Spawn detached background tasks with no ownership, cancellation, or failure visibility.
  - Leave timers/pollers/threads running after the component that owns them is disposed.

## 8. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `concurrency.md §2`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Non-atomic check-then-act / read-modify-write on shared state where a race causes data loss, overselling, double-spend, or corruption (§2); fire-and-forget async task with no error handling where failure = data loss (§4); non-idempotent side effect applied with no dedup under at-least-once delivery (§5); blocking I/O or external call performed while holding a lock, or inconsistent lock ordering that can deadlock (§3) |
| 🟡 **WARN** | Shared mutable state accessed from multiple contexts without clear synchronization (§1); unbounded parallel task spawning (§4); sync-over-async that can exhaust the pool (§4); lock held across slow work, or critical section larger than necessary (§3); background task spawned with no cancellation/shutdown handling (§7); reliance on plain writes for cross-context visibility (§6) |
| 🟢 **INFO** | Mutable shared structure where an immutable or message-passing design would be simpler (§1); missing graceful-shutdown drain (§7); opportunity to replace a lock with an atomic/lock-free primitive (§3) |

## 9. Applying This Standard with a Limited Scope

When reviewing or modifying concurrent code in a **specific set of files**, follow these constraints:

1. **Only change synchronization within the approved scope.** If out-of-scope code has an unguarded race, flag it as a finding (WARN/BLOCK note) rather than editing it.
2. **Fixing a data-corrupting race or a data-loss fire-and-forget is always in scope** when it occurs in a file you are already modifying — it is a required fix, not an opportunistic change.
3. **Do not introduce a new concurrency model, threading framework, or message broker** unless that integration is explicitly in scope; use the existing primitives.
4. **When adding synchronization to satisfy this standard**, match the project's existing concurrency conventions (its lock types, async style, idempotency mechanism) rather than introducing a new approach.
