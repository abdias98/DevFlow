# Standards Loading — Canonical Policy

> **Framework-centric principle:** a standard is loaded because its **domain applies to the change**, not because a red flag was already spotted. The Quick Card lists BLOCK triggers only; using it as the gate that decides whether a standard is read means every WARN-level rule — most of design, structure and testing — is never in front of the agent that should apply it.

This document is the single definition of **when a full standard is loaded**. An agent that adopts it references this file instead of stating its own loading rule.

---

## The Rule

1. **Decide which domains apply** using the signals in the table below, read from the diff (review) or from the planned change (design, planning, implementation).
2. **Load the full standard** for every domain that applies. Do not load standards whose domain does not apply.
3. **Use the [Standards Quick Card](./standards-quick-card.md) for what it is:** a fast list of BLOCK triggers to scan first, so the most severe findings are never missed. A Quick Card with no matching red flag is **not** a reason to skip a standard whose domain applies.
4. **When unsure whether a domain applies, load it.** The cost of reading a standard is bounded; the cost of a missed rule is a correction after the PR.
5. **Apply it through the project's idioms.** If `docs/devflow/knowledge-base/standards-profile.md` exists, it says how each standard is expressed in this codebase — which primitive, which location, which canonical example. A standard applied generically, in a shape the project does not use, is a consistency finding even when the rule itself is met.

"Clearly does not apply" means a signal is absent, not that the change looks small or routine.

---

## Domain Signals

| Standard | Load when the change… |
|----------|------------------------|
| [design-principles.md](./standards/design-principles.md) | adds or modifies production code (always — transversal) |
| [solid.md](./standards/solid.md) | adds or modifies a class, module, function or component with behavior |
| [clean-architecture.md](./standards/clean-architecture.md) | adds or moves code across layers, adds an import between layers, or introduces a port/adapter |
| [project-design.md](./standards/project-design.md) | adds a file, module or folder, or changes where a responsibility lives |
| [testing.md](./standards/testing.md) | adds or modifies tests, or modifies production logic (which needs tests) |
| [security.md](./standards/security.md) | handles external input, authentication/authorization, secrets, sensitive data, queries or commands built from input, file paths, deserialization, or exposes data (always consider — scan its Quick Card triggers on every change) |
| [error-handling.md](./standards/error-handling.md) | performs anything that can fail — I/O, parsing, external calls, throws/catches, retries, resource acquisition |
| [performance.md](./standards/performance.md) | accesses data, loops over collections, performs I/O on a request/render path, caches, or renders collections |
| [concurrency.md](./standards/concurrency.md) | uses async work, promises/futures, threads, locks, background jobs, timers, shared mutable state, or message consumers |
| [logging.md](./standards/logging.md) | emits logs, traces or metrics, or adds a catch block |
| [state-lifecycle.md](./standards/state-lifecycle.md) | introduces or modifies state that outlives a single call: a store, cache, session, subscription, or registry |
| [integration-consumption.md](./standards/integration-consumption.md) | calls an external service, API, or integration the project does not control |
| [dependencies.md](./standards/dependencies.md) | changes a dependency manifest, lockfile, or build/CI dependency configuration |
| [rest-api.md](./standards/rest-api.md) | adds or changes an HTTP/RPC endpoint, route, or request/response contract |
| [event-driven-architecture.md](./standards/event-driven-architecture.md) | produces or consumes events, messages, queues or streams (including in-process domain events) |
| [ui-design.md](./standards/ui-design.md) · [accessibility.md](./standards/accessibility.md) | adds or changes a UI component, view, template, style or user-facing interaction |
| [git-conventions.md](./standards/git-conventions.md) | creates commits or a branch (the Reviewer checks the change's own branch and commits) |

A review subagent applies this table **only to the standards in its own dispatch row** (`devflow-review/SKILL.md` → Step 3): it loads the full text of each of its standards whose signal is present.

---

## Anti-Patterns

- ❌ **Quick Card as a gate** — "no red flag matched, so I didn't read the standard" skips every WARN rule by construction.
- ❌ **Loading by feature type alone** — "it's a backend feature, so SOLID + Security + Performance" misses the error-handling, logging and concurrency rules the actual diff touches.
- ❌ **Loading everything** — standards whose signal is absent add cost and dilute attention without adding findings.
- ❌ **Restating a loading rule in a SKILL.md** — reference this file; a second copy drifts.

---

## Agents That Apply This Policy

| Agent | Application |
|-------|-------------|
| **Orchestrator** (Validation Gate) | Loads every standard the request's domain applies to before scanning for BLOCKs |
| **Critical Friend** (all standalone agents) | Check 1 loads every standard whose *Apply when* condition the request meets |
| **Architect** | Loads the standards whose conditions the design meets, including Testing for the Test Architecture and the State & Interaction Matrix |
| **Planner** | Loads the standards the design applies to, to write per-task constraints |
| **Implementer** | Decides the applicable standards per task and passes them in each task subagent's brief |
| **Feature Agent · Bug-Fixer · Refactorer** | Load the standards their change applies to; inline self-review covers all of them |
| **Reviewer** (Phase 6 / standalone review) | Each review subagent loads the full standards of its dispatch row whose signals are present; the inline path loads all standards whose signals are present |
