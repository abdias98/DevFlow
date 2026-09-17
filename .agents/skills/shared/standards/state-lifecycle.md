# DevFlow Engineering Standards: State & Data Lifecycle (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-09-17

> **Note on examples:** "State" here means any value that outlives a single function call and is read again later — a UI store, a server-side cache, a session, a in-memory registry, a subscription's last-seen value. All code-like fragments are illustrative; adapt them to the detected stack (a React/Vue store, a backend cache layer, a mobile view-model, a CLI's in-process registry).

Apply this standard whenever the change introduces or modifies state that outlives a single call. It is the transversal counterpart to `concurrency.md` (which owns *thread/process-level* races) and `performance.md` §3 (which owns *server-side cache* mechanics): this standard owns the *lifecycle* of a stored value — who owns it, when it resets, what happens to a result that arrives after it stopped being relevant.

## 1. Single Source of Truth & Ownership

- **What:** Every piece of state has exactly one owner responsible for writing it; every other place that displays or uses it reads a copy or a reference, never a second independent write path.
- **DO:**
  - Name the owner of each state value explicitly (a store, a service, a single component) before any code writes to it.
  - Let consumers read the current value or subscribe to changes — never let two independent code paths write the same conceptual value out of band with each other.
  - When a value logically has one source but is cached in multiple places for performance, define the propagation path from the source to every cache explicitly.
- **DON'T:**
  - Let a value be set directly in more than one place (e.g., a UI updates its own local copy *and* a shared store independently, without one deriving from the other).
  - Duplicate the same fact into two state containers with no defined relationship between them — they will drift.

## 2. Derived vs. Stored State

- **What:** A value that can be computed from other state should not also be stored — two copies of the same fact are a bug waiting for the update that touches only one of them.
- **DO:**
  - Compute derived values (totals, filtered lists, "is valid" flags, formatted strings) on read, or memoize them explicitly with a documented invalidation trigger.
  - Store only the state that cannot be recomputed from something else already held.
- **DON'T:**
  - Store a value alongside the inputs it was computed from without a mechanism that keeps them in sync — this is the most common source of "the UI shows stale totals" defects.
  - Introduce a memoization layer with no defined invalidation event, betting that "it will probably still be fresh."

## 3. Invalidation on Dependency Change

- **What:** When something a piece of state depends on changes, that state must be recomputed, refetched, or explicitly marked stale — never left showing the old dependency's answer under the new dependency's identity.
- **DO:**
  - For every stored or cached value, name what it depends on (a parameter, a selection, another piece of state) and the exact point where a change to that dependency triggers invalidation.
  - Prefer deriving the value fresh over caching it, unless a measured cost justifies the cache — then document the invalidation trigger next to the cache itself (`performance.md` §3 owns the mechanics of that cache; this section owns *whether an invalidation trigger exists at all*).
- **DON'T:**
  - Change what a piece of state depends on (a filter, a selected entity, a config value) without auditing what reads that state — an untouched cache now silently answers on behalf of the wrong dependency.

## 4. Scope & Reset Tied to Context

- **What:** State that is meaningful only within a context (a selected entity, a session, an open dialog, a request) must be reset or discarded when that context ends or changes — otherwise the next context inherits state left over from the previous one.
- **DO:**
  - For every piece of context-scoped state, define explicitly what resets, what persists across the context change, and what is recomputed for the new context.
  - Reset *before* starting the new context's work, not only after the new context's data arrives — a reader between the two moments must not see the old context's data under the new context's identity.
- **DON'T:**
  - Leave a context-scoped value populated with the previous context's data while the new context's data is loading, unless that is a deliberate, documented choice (e.g., "keep showing the old list while the new one loads" is sometimes correct — but it must be a decision, not an oversight).
  - Assume "the component/handler for the old context was torn down" is enough — state that lives in a shared store or process outlives any single component/handler instance.

## 5. Subscriptions, Timers & Resource Lifecycle

- **What:** Anything a piece of state starts to keep itself current — a subscription, a polling timer, a listener, an open connection — must be tied to the lifetime of whatever depends on that state, and released when nothing depends on it anymore.
- **DO:**
  - Release every subscription, timer, and listener when its owner is disposed, navigated away from, or no longer relevant — symmetrically with how it was acquired.
  - When state has multiple concurrent subscribers, share one underlying subscription rather than opening one per subscriber, and tear it down only when the last subscriber leaves.
- **DON'T:**
  - Start a subscription or timer with no corresponding teardown path.
  - Assume garbage collection will stop a timer or close a connection — most runtimes need it stopped explicitly (cross-reference: `concurrency.md` §7 owns supervision of *background processes*; this section owns the *state-holding* subscription/timer regardless of whether it runs in its own process).

## 6. Out-of-Order Async Results

- **What:** When state is updated by an asynchronous operation, a result that arrives after a newer request for the same state has already started (or superseded it) must not overwrite the newer state.
- **DO:**
  - Tag each asynchronous request for a piece of state with an identifier (a token, a generation counter, an AbortController) and apply the result only if it is still the latest request for that state.
  - Treat this as a coverage requirement wherever the [Behavior Scenarios](../behavior-scenarios.md) "Order" and "Change while in flight" Transition Prompts apply to stateful code.
- **DON'T:**
  - Assume requests resolve in the order they were sent — network timing, retries, and cancellation all reorder them in practice.
  - Rely on "the old request will just take longer, that's unlikely" — this is exactly the class of defect that only appears in production under real network variance, never in a quick manual check.

## 7. Work Performed Only When Consumed

- **What:** Loading, computing, or fetching data that nothing currently reads is wasted work and a hidden source of the stale/duplicate-state defects above.
- **DO:**
  - Load or compute a piece of state only when something active (a visible view, an active tab, a subscriber) will consume it.
  - Cancel or ignore in-flight work for state that stopped being relevant (a tab that was switched away from, a component that unmounted) rather than letting it complete and silently discarding the result — cancelling also frees the resource earlier (`performance.md` §4 owns the throughput angle of unnecessary async work).
- **DON'T:**
  - Eagerly load every tab's or panel's data regardless of which one is currently visible, "in case the user switches to it."
  - Leave a loading operation running to completion for state that no longer has any subscriber, when cancellation is available.

## 8. Cache Keys & Completeness

- **What:** A cache or memoization key that omits a parameter the cached value actually depends on will serve one context's answer to another context that happens to share the incomplete part of the key.
- **DO:**
  - Include every input the cached computation depends on in its key — a selected entity, a filter, a locale, a permission level, a pagination cursor.
  - When in doubt about whether a parameter belongs in the key, include it — an over-specific key costs a cache miss; an under-specific key costs a correctness defect.
- **DON'T:**
  - Key a cache only by the parameter that is easiest to obtain (e.g., a resource id) when the value actually also depends on who is asking or in what mode.

## 9. Code Review Checklist
When reviewing, verify:
- [ ] Each piece of state has one identified owner; no second independent write path exists (§1).
- [ ] No value is both stored and kept in sync with its computable inputs by hand — it is derived, or its invalidation trigger is documented (§2).
- [ ] Every stored/cached value's dependencies are named, and there is a concrete point where a dependency change invalidates it (§3).
- [ ] Every context-scoped value's reset behavior on context change is defined and implemented (§4).
- [ ] Every subscription, timer, or listener a piece of state opens has a matching teardown (§5).
- [ ] Asynchronous updates to state are tagged and superseded results are discarded (§6).
- [ ] State is loaded/computed only for what is currently consumed, and stale in-flight work is cancelled or ignored, not raced against (§7).
- [ ] Cache/memoization keys include every parameter the cached value depends on (§8).

## 10. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `state-lifecycle.md §4`). Severity for a demonstrated behavioral instance of these defects may also be assessed under `rules.md` → Behavioral Impact Severity when a reproducible scenario is available; the triggers below apply to the rule violation itself.

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | An out-of-order or superseded async result is applied and overwrites newer state, observably showing data from the wrong context (§6); context-scoped state is not reset on a context change and a reader can observe the previous context's data attributed to the new context (§4); a cache/memoization key omits a parameter the value depends on, causing one context's cached answer to be served to another (§8) |
| 🟡 **WARN** | A derived value is stored and hand-synchronized with its inputs instead of computed or memoized with a documented invalidation trigger (§2); a stored/cached value has no defined invalidation trigger for a named dependency (§3); a subscription, timer, or listener has no teardown path (§5); state is eagerly loaded for content that is not currently visible/consumed, with a real resource cost (§7) |
| 🟢 **INFO** | Two state containers hold the same fact with an informal (not enforced) relationship between them, not yet causing drift (§1); a cache/memoization opportunity exists but the current computation cost is low enough that adding one would be premature (§2, cross-ref `design-principles.md` §5) |

## 11. Applying This Standard with a Limited Scope

When applying this standard to a **specific set of files or modules** (the declared Core scope), follow these constraints:

1. **Only modify files inside Core directly.** If a state-lifecycle violation is found in a file outside Core, apply the Impact Zone / backlog handling below rather than editing it unconditionally.
2. **Adding a missing reset, invalidation trigger, teardown, or async-result guard within a file already in Core is always allowed** — these are required fixes for code already being touched, not opportunistic changes.
3. **Extending a cache key to include a missing parameter is in scope** when the cache implementation itself lives in Core. If the cache lives outside Core, defer via the handling below rather than editing a shared cache module unilaterally.
4. **Do not introduce a new state-management library, store pattern, or subscription framework** as a side effect of fixing a lifecycle defect — use the project's existing primitives (see the project's standards profile, `docs/devflow/knowledge-base/standards-profile.md`, if one exists).
5. **A defect that requires touching a shared/global store outside Core to fix correctly** (e.g., the invalidation must happen where the dependency actually changes, and that code is Outside) is deferred per the handling below with `incomplete` severity if leaving it unfixed makes the Core change functionally incoherent.

**Handling violations outside the Core scope** (per [`rules.md`](../rules.md) → Scope-Locking — Three Zones): a file is either in the **Impact Zone** (a dependent or dependency of a file already in Core, discoverable via `devflow-ctl scope impact <file>`) or **Outside**.
- **Impact Zone + one of the six closed coherence reasons** (broken caller, broken import, contract violation, duplicated logic the task just introduced, a test that now fails, a type/schema that must change together): fix it, then record `devflow-ctl scope justify <file> "<reason>"`.
- **Impact Zone without a closed coherence reason, or Outside entirely:** do not edit it. Defer it instead: `devflow-ctl backlog add <file> "<reason>" --severity {incomplete|info}` — use `incomplete` if the in-scope change is functionally incoherent without that follow-up, `info` if it is a separate improvement.

## 12. Design-Time Decisions

Record these in the spec's **Standards Applied** table, pointing at the section below that materializes each one (typically the **State & Interaction Matrix**, which is the concrete mechanism this standard's design-time decisions feed):

- **Ownership map** — for each piece of new or modified state, its single owner and every place that reads it (§1).
- **Derived vs. stored** — which values are computed on read versus stored, and the invalidation trigger for anything stored or cached (§2, §3).
- **Context scope** — what resets, what persists, and what is recomputed on every context change named in the [State & Interaction Matrix](../behavior-scenarios.md) (§4, context-scoped reset).
- **Resource lifecycle** — which subscriptions, timers, or listeners this state opens, and their teardown trigger (§5).
- **Async ordering guard** — the mechanism (token, generation counter, cancellation) that discards superseded async results, for every state updated asynchronously (§6).
- **Consumption gating** — confirmation that loading/computation is gated on active consumption, not performed unconditionally (§7).
- **Cache key completeness** — the full list of parameters any new cache or memoization key includes (§8).

## 13. Implementation Self-Check

Before marking a task done:

- [ ] Every new or modified piece of state has exactly one write path (§1).
- [ ] No hand-synchronized derived value was introduced without a documented invalidation trigger (§2, §3).
- [ ] Context-scoped state resets before the new context's data arrives, not only after (§4).
- [ ] Every subscription, timer, or listener added is torn down on the same path that acquired it (§5).
- [ ] An async-result guard was added wherever a request for state can be superseded before it resolves (§6).
- [ ] No state is loaded or computed for something that is not currently consumed (§7).
- [ ] Any new cache or memoization key includes every parameter the cached value depends on (§8).
