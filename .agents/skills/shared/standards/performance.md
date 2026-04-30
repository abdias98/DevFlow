# DevFlow Engineering Standards: Performance (Technology-Agnostic)

> **Note on examples:** All patterns and code fragments are illustrative. Adapt syntax and tool names to the detected stack.

Apply these principles to all code you design, generate, or review.

## 1. Algorithmic Efficiency
- **What:** The choice of algorithm and data structure determines the scalability ceiling.
- **DO:**
  - Choose data structures and algorithms appropriate to the expected input size. Consider time and space complexity for every loop and collection operation.
  - Prefer hash-based lookups (O(1)) over linear scans (O(n)) for frequent searches.
  - Use lazy evaluation or streaming where full materialization of a collection is unnecessary.
  - Reuse computed results when the input hasn't changed (memoization / caching at the function level).
- **DON'T:**
  - Use O(n²) or worse solutions when an O(n log n) or O(n) alternative exists at comparable implementation complexity.
  - Perform unnecessary copies of large data structures; pass by reference or move where possible.
  - Apply algorithmic optimizations blindly on non‑hot‑path code; always measure first (see Principle 6).

## 2. Database Access
- **What:** Database round-trips are the most common performance bottleneck.
- **DO:**
  - Use indexed queries and verify query plans for slow queries.
  - Paginate large result sets — never return unbounded collections from an API or repository.
  - Prefer batch operations (bulk inserts/updates) over row-by-row processing.
  - Fetch only the columns needed (projection) rather than full entities when the consumer requires a subset of fields.
  - Consider read‑only replicas for heavy read loads where eventual consistency is acceptable.
- **DON'T:**
  - Execute database queries inside loops (N+1 problem).
  - Fetch entire tables when only a subset is needed; always apply filters at the database level.
  - Use eager loading of deep object graphs when the caller rarely needs the related data — offer flexible loading strategies (eager/lazy) through the repository interface.
  - Chain multiple sequential queries that could be combined into a single round‑trip using joins or batch endpoints.

## 3. Caching
- **What:** Caching trades memory for speed — use it strategically on proven hot paths.
- **DO:**
  - Cache expensive computations, external API calls, and frequently‑read, rarely‑changed data at the appropriate layer (application‑level, distributed cache, CDN).
  - Define an explicit Time‑To‑Live (TTL) for every cached item, based on business staleness tolerance.
  - Implement a fallback strategy for cache failures (e.g., stale‑while‑revalidate, graceful degradation to the source).
  - Measure hit rate, miss rate, and eviction rate before and after introducing a cache.
- **DON'T:**
  - Cache mutable state without an explicit invalidation strategy — every write to the source must evict or update the cache.
  - Cache at every layer simultaneously (stacked caching) without understanding the combined invalidation complexity.
  - Assume caching is faster — some data sources (e.g., local memory) can be faster than a remote cache.
  - Use caching as a substitute for fixing an inefficient query or algorithm; fix the root cause first.

## 4. Asynchronous Operations
- **What:** Blocking I/O wastes threads and degrades throughput under load.
- **DO:**
  - Use async/non‑blocking patterns for all I/O‑bound operations (network, disk, database).
  - Apply back‑pressure when the incoming request rate exceeds the processing capacity (e.g., bounded queues, circuit breakers).
  - Configure appropriate timeouts for every async operation — never let a call hang indefinitely.
  - Parallelize independent I/O operations (e.g., fire multiple API calls concurrently and await them all).
- **DON'T:**
  - Block the main thread or event loop with synchronous I/O in environments where async is available.
  - Mix sync‑over‑async or async‑over‑sync patterns, which can cause thread‑pool starvation.
  - Fire‑and‑forget async work without error handling — unobserved exceptions can crash the process or leave data inconsistent.
  - Use async for CPU‑bound work expecting it to become faster — offload CPU‑bound tasks to a background worker pool instead.

## 5. Resource Management
- **What:** Leaked resources accumulate and eventually cause failures.
- **DO:**
  - Release resources explicitly (connections, file handles, streams) after use. Prefer language constructs that guarantee disposal (`using`, `try‑with‑resources`, context managers).
  - Use connection pooling for databases and HTTP clients — creating a new connection per request is extremely costly.
  - Set maximum pool sizes and timeouts to bound resource usage and fail gracefully under overload.
  - Close long‑lived resources on application shutdown via graceful shutdown hooks.
- **DON'T:**
  - Create new connections per request or leave resources open indefinitely.
  - Assume the garbage collector will clean up unmanaged resources in a timely manner — explicit disposal is required.
  - Share non‑thread‑safe resources across threads without synchronization.

## 6. Measure Before Optimizing
- **What:** Premature optimization wastes time and reduces readability.
- **DO:**
  - Profile and measure first. Fix proven bottlenecks with data (flame graphs, query plans, load‑test results), not intuition.
  - Set a performance budget (e.g., p95 latency < 200ms, throughput > 1000 req/s) and only optimize when it is exceeded.
  - Write a benchmark or load test that reproduces the slowness before making changes, and re‑run it after to confirm improvement.
  - Keep a record of optimizations in a changelog or refactor report, including the before/after metrics.
- **DON'T:**
  - Optimize code that is not on the hot path — prioritize correctness, readability, and maintainability until performance is demonstrably insufficient.
  - Micro‑optimize at the language level (e.g., loop unrolling) unless a profiler pinpoints that line as the bottleneck.
  - Optimize in isolation — always test under realistic multi‑user load to detect contention and cascading effects.

## 7. Performance Interactions & Trade‑offs
- **Async + Database:** Non‑blocking database drivers (if available) prevent thread starvation under high concurrency. Batch async queries for independent fetches.
- **Caching + Asynchronous Operations:** A cache hit can turn an async I/O call into a synchronous memory access. Ensure the cache access itself is non‑blocking if used in a fully async pipeline.
- **Resource Management + Pooling:** Pooling improves performance by reusing expensive connections, but misconfigured pool limits can create bottlenecks (waiting for a free connection) while unbounded pools can exhaust database connections.
- **Measuring + Caching:** A caching layer hides the true cost of the underlying operation. When profiling, always measure the end‑to‑end latency including cache miss scenarios.

## 8. Code Review Checklist
When reviewing, verify:
- [ ] Algorithms match the expected data scale; no O(n²) on potentially large collections without justification.
- [ ] Database queries are batched, paginated, and indexed; no N+1 or unbounded result sets.
- [ ] Caching has explicit TTL, invalidation strategy, and fallback behavior.
- [ ] All I/O operations are async where the runtime supports it; timeouts are set.
- [ ] Resources (connections, files) are explicitly released; pooling is used for expensive resources.
- [ ] Optimizations are backed by profiling data or a clear performance budget.
- [ ] No async‑over‑sync or sync‑over‑async anti‑patterns.

## 9. Applying This Standard with a Limited Scope

When applying performance rules to a **specific set of files or modules** (the declared scope), follow these constraints:

1. **Only modify files inside the scope.**
   - If a performance issue (e.g., N+1 query) originates from code outside the scope, document it as an INFO note in the in‑scope file and recommend the fix for the external caller.
2. **Async transformations require careful scope boundaries.**
   - Changing a method from sync to async changes its signature and forces all callers to adopt async. If callers are outside scope, **do not change the signature**. Instead, leave a comment explaining the async opportunity and the required call‑chain migration.
3. **Caching introductions.**
   - Adding a cache layer may require configuration or DI registration outside scope. Define the cache interface within scope, implement a no‑op or in‑memory version for now, and leave a TODO for the composition root registration.
4. **Resource management fixes.**
   - Adding a `using`/`try‑with‑resources` block is always safe within scope if the resource acquisition is already present. Do not change the resource acquisition method (e.g., connection factory) if it belongs to a different module.
5. **Profiling evidence.**
   - When a performance claim is made in a review or refactor context, mention that profiling would be required to confirm, but do not run profilers yourself. The user is responsible for providing the metrics.