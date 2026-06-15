# Standards Quick Card

Fast-scan reference for the Critical Friend check. Each entry shows the most critical BLOCK triggers only.
For full rules, WARN/INFO triggers, and scope guidance → read the full standard.

> **How to use:** Scan this card first. If a red flag matches → load the full standard → cite `{standard}.md §{N} → BLOCK` in your finding.

---

## security.md — Red Flags (BLOCK)
- Hardcoded secret, API key, or credential in source code → §3
- Rolling custom authentication or cryptography → §2
- External input reaching SQL, shell command, or LDAP without validation → §1, §4
- Sensitive tokens stored in `localStorage` / `sessionStorage` → §2
- No authentication on an endpoint that mutates or exposes private data → §2
- Stack traces / internal paths in API error responses → §6

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
- Fire-and-forget async task with no error handling where failure = data loss → §4

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
- Exception caught and silently swallowed — neither logged nor rethrown → §5
- Full auth headers / request bodies logged on a sensitive-data path → §3

## project-design.md — Red Flags (BLOCK)
- Business logic in entry point (main/index) → §3
- Circular dependency between modules with no resolution path → §3

## ui-design.md — Red Flags (BLOCK)
- Interactive element (button, link, form field) not keyboard-accessible or missing ARIA → §8
- Hardcoded secret or sensitive data rendered in UI template → §3 + security.md §3

---

## Quick Routing

| Finding | Action |
|---------|--------|
| 🔴 BLOCK | STOP. Present to user: ✅ Accept risk, ✏️ Revise approach, ❌ Cancel |
| 🟡 WARN | Present, then continue |
| 🟢 INFO | Add to Additional Recommendations, continue |
| None | Proceed silently |

Citation format: `"{violation}" → {standard}.md §{N} → BLOCK`
