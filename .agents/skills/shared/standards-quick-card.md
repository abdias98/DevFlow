# Standards Quick Card

Fast-scan list of the most critical **BLOCK triggers** per standard. It is a first pass so the most severe problems are never missed — **not** a gate that decides whether a standard is read.

> **How to use:**
> 1. Decide which standards apply with the domain signals in [standards-loading.md](./standards-loading.md), and load the **full** text of each one — whether or not anything below matches. Most design, structure and testing rules are WARN and never appear on this card.
> 2. Scan this card for the applicable standards first. A match is cited as `{standard}.md §{N} → BLOCK`.
> 3. Apply the rest of each loaded standard for WARN/INFO findings.

---

## security.md — Red Flags (BLOCK)
- Hardcoded secret, API key, or credential in source code → §3
- Rolling custom authentication or cryptography → §2
- External input reaching SQL, shell command, or LDAP without validation → §1, §4
- Sensitive tokens stored in `localStorage` / `sessionStorage` → §2
- No authentication on an endpoint that mutates or exposes private data → §2
- Stack traces / internal paths in API error responses → §6
- State-changing endpoint with no CSRF token or `SameSite` cookie defense → §8
- Untrusted input deserialized with a mechanism that can instantiate arbitrary types or execute code → §8
- Request body bound directly onto a domain/persistence entity with no allowlisted DTO (mass assignment) → §8

## solid.md — Red Flags (BLOCK)
- LSP: subclass silently breaks runtime substitution (no-op override, `NotImplementedException` in production) → §3
- DIP: `new DatabaseConnection()`, `new ExternalApiClient()` inside domain / use-case code → §5

## clean-architecture.md — Red Flags (BLOCK)
- Inner layer (Domain/UseCase) imports from HTTP framework, ORM, or DB driver → §1
- ORM entity returned directly from API endpoint or passed to UI → §3
- SQL / DB queries written inside Use Cases or Domain Entities → §2
- Domain exception inherits from a framework-specific base class → §3

## performance.md — Red Flags (BLOCK)
- Database query inside a loop with unbounded input (N+1) → §2
- API / repository returns an unbounded collection (no pagination) → §2
- Fire-and-forget async task with no error handling where failure = data loss → concurrency.md §4

## rest-api.md — Red Flags (BLOCK)
- `200 OK` returned with an error body → §3
- State-changing operation exposed via `GET` → §2
- No authentication on a private-data endpoint → §8
- Unvalidated client input used directly in a query or command → §8

## testing.md — Red Flags (BLOCK)
- Bug fix applied with no regression test → §5
- Test always passes regardless of production code behavior (empty assertion) → §4
- New feature with domain logic and no test file → §4

## logging.md — Red Flags (BLOCK)
- Secret, credential, token, password, or PII written to a log (any level) → §3
- Exception caught and silently swallowed — neither logged nor rethrown → §6
- Full auth headers / request bodies logged on a sensitive-data path → §3

## error-handling.md — Red Flags (BLOCK)
- Empty catch / catch-and-continue that discards the error (no log, no rethrow) → §2
- Raw stack trace, exception message, or internal detail returned to an external caller → §5
- Failure path leaks a resource or leaves data in an inconsistent/partially-written state → §6
- Non-idempotent operation retried with no idempotency guard → §8

## concurrency.md — Red Flags (BLOCK)
- Non-atomic check-then-act / read-modify-write on shared state (oversell, double-spend, corruption) → §2
- Fire-and-forget async task with no error handling where failure = data loss → §4
- Non-idempotent side effect with no dedup under at-least-once delivery → §5
- Blocking I/O / external call while holding a lock, or inconsistent lock ordering (deadlock) → §3

## state-lifecycle.md — Red Flags (BLOCK)
- An out-of-order or superseded async result overwrites newer state, showing data from the wrong context → §6
- Context-scoped state not reset on a context change — the previous context's data is attributed to the new one → §4
- A cache/memoization key omits a parameter the value depends on, serving one context's answer to another → §8

## dependencies.md — Red Flags (BLOCK)
- Release with a known critical/high dependency vulnerability and no documented mitigation → §3
- Dependency installed from an untrusted source or with integrity verification disabled → §4
- Dependency with a license incompatible with the product's distribution model → §5
- Lockfile removed/ignored so builds are non-reproducible → §2

## event-driven-architecture.md — Red Flags (BLOCK) *(apply only if the project uses events/queues/streams)*
- Non-idempotent side effect (charge, ship, notify) triggered directly from an event handler with no dedup guard → §2
- Failed event retried forever with no dead-letter path, blocking the queue/partition behind it → §5

## project-design.md — Red Flags (BLOCK)
- Business logic in entry point (main/index) → §3
- Circular dependency between modules with no resolution path → §3

## ui-design.md — Red Flags (BLOCK)
- Hardcoded secret or sensitive data rendered in UI template → §16 + security.md §3

## accessibility.md — Red Flags (BLOCK)
- Interactive element (button, link, form field, control) not keyboard-operable, or missing accessible name/role, blocking a core flow → §3, §5
- `aria-hidden="true"` (or equivalent) on a focusable element — unreachable focus trap → §5
- Keyboard trap with no exit → §3
- Critical form input with no programmatic label → §6

## git-conventions.md — Red Flags
- Direct commit to a protected branch (`main`/`master`) without a PR → §2 → BLOCK
- Vague commit message with no scope or actionable description → §1 → WARN
- Multiple unrelated changes bundled in one commit → §1 → WARN

## design-principles.md — Red Flags *(always applies — every request, every cycle)*
- The same business rule/validation/calculation reimplemented in 2+ places, already diverging → §1 → WARN
- A new abstraction, config layer, or architectural pattern added with no current concrete requirement → §2 → WARN
- Domain/business logic directly importing a specific ORM/framework/vendor SDK type → §4 → WARN
- An optimization trading readability for speed with no profiling data or performance budget behind it → §5 → WARN

---

## Quick Routing

| Finding | Action |
|---------|--------|
| 🔴 BLOCK | STOP. Present to user: ✅ Accept risk, ✏️ Revise approach, ❌ Cancel |
| 🟡 WARN | Present, then continue |
| 🟢 INFO | Add to Additional Recommendations, continue |
| None | Proceed silently |

Citation format: `"{violation}" → {standard}.md §{N} → BLOCK`
