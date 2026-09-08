# DevFlow Engineering Standards: Logging & Observability (Technology-Agnostic)

> **Version:** 1.3.0 | **Last Updated:** 2026-09-08

> **Note on examples:** All logger names, field names, and code fragments are illustrative. Replace them with the actual logging library, format, and conventions of the detected stack.

Apply these principles to all code you design, generate, or review that emits logs, traces, or metrics.

## 1. Structured Logging

- **What:** Logs are data, not prose. Emit machine-parseable records (key/value or JSON), not interpolated free-text strings.
- **DO:**
  - Emit structured events with named fields (`event`, `user_id`, `duration_ms`, `status`) so logs can be filtered, aggregated, and alerted on.
  - Keep one event per log call. Put variable data in fields, not concatenated into the message.
  - Use a single shared logger configuration / factory so format, destination, and levels are consistent across the codebase.
- **DON'T:**
  - Build messages by string concatenation (`"user " + id + " failed " + err`) — the values become unsearchable.
  - Use `print` / `console.log` / `stdout` writes as the logging mechanism in production code. Route through the project's logger.
  - Invent a new ad-hoc log format per module.

## 2. Log Levels

- **What:** Levels let operators tune signal vs. noise. Use them deliberately.
- **DO:**
  - `ERROR` — a failure that needs attention (request failed, data not saved). `WARN` — recoverable or degraded condition. `INFO` — significant business events (user created, order placed). `DEBUG` — diagnostic detail for development/troubleshooting. `TRACE` — very fine-grained flow.
  - Make the level configurable per environment (verbose in dev, `INFO`+ in production).
  - Reserve `ERROR` for actionable failures so error dashboards stay meaningful.
- **DON'T:**
  - Log routine, expected flow at `ERROR` / `WARN` — it trains operators to ignore alerts.
  - Log everything at one level (all `INFO`, or all `DEBUG`).
  - Leave noisy `DEBUG` logging enabled by default in production.

## 3. What NOT to Log (Sensitive Data)

- **What:** Logs are widely accessible and long-lived. They must never become a data-leak vector.
- **DO:**
  - Redact or omit secrets, credentials, tokens, API keys, passwords, and session identifiers.
  - Mask or hash personal data (PII): full names, emails, phone numbers, government IDs, payment data — follow the applicable data-protection rules.
  - Log a stable, non-sensitive identifier (e.g., a user ID or correlation ID) instead of the sensitive value.
- **DON'T:**
  - Log full request/response bodies, headers (`Authorization`, `Cookie`), or query strings that may carry secrets or PII.
  - Log raw exceptions whose message embeds a secret (connection strings, signed URLs).
  - Assume "it's only DEBUG" makes sensitive logging safe — DEBUG output reaches files, aggregators, and crash reports.

## 4. Correlation & Context

- **What:** A single user action crosses many components. Logs must be stitchable back together.
- **DO:**
  - Propagate a correlation/request/trace ID through the call chain and attach it to every log line for that operation.
  - Attach stable context (tenant, operation name, entity ID) via the logger's context/MDC mechanism rather than repeating it in each message.
  - Adopt the platform's tracing conventions (e.g., W3C `traceparent`) when distributed tracing is available.
- **DON'T:**
  - Emit context-free logs that cannot be tied to a request or user action.
  - Generate a new correlation ID mid-flow, breaking the chain.

## 5. Business/Audit Event Logging

- **What:** A business event (a purchase confirmed, a payment declined, an account created, a permission changed) answers a different question than a technical log — not "what went wrong" but "what happened, to whom, and when," for traceability, dispute resolution, and compliance. Conflating the two loses the audit trail whenever someone tunes verbosity for debugging.
- **DO:**
  - Emit a distinct, structured event for every business-significant outcome (confirmed, declined, cancelled, changed) — not just its failures. Include the actor, the affected entity, the outcome, and a timestamp.
  - Treat business/audit events as a separate stream or a reserved level from technical/diagnostic logs, so raising the debug threshold in production never silences them.
  - Make audit events append-only in the store they land in when the domain requires non-repudiation (payments, permission changes, regulated data) — an audit trail that can be edited after the fact is not one.
- **DON'T:**
  - Log a business outcome only when it fails (e.g., only "payment declined," never "payment confirmed") — an audit trail with silent successes can't answer "did this happen" for the happy path.
  - Let a business-critical event depend solely on the general log level being `INFO` or above — a verbosity change should never erase what the business needs to prove happened.
  - Reuse the technical error logger for audit events with no way to distinguish or query them separately from debug noise.

## 6. Error Logging

- **What:** Errors must be observable with enough detail to diagnose, and must never be silently lost.
- **DO:**
  - Log caught errors that are not rethrown, including the exception type, message, and stack trace (or cause chain).
  - Log at the boundary where the error is handled — once — not at every layer it passes through.
  - Include the context needed to reproduce: operation, inputs (sanitized), and correlation ID.
- **DON'T:**
  - **Swallow exceptions** — catching an error and neither logging nor rethrowing hides failures. (This is a blocker; see also `error-handling` guidance where present.)
  - Log the same error repeatedly as it bubbles up (log-and-rethrow at every layer) — it creates duplicate noise.
  - Log an error and then continue as if it succeeded, producing misleading downstream logs.

## 7. Performance & Volume

- **What:** Logging is not free. Excessive or synchronous logging degrades the system it observes.
- **DO:**
  - Guard expensive log-message construction behind a level check (or use the logger's lazy/parameterized API).
  - Prefer asynchronous / buffered log appenders for high-throughput paths, accepting bounded loss on crash where appropriate.
  - Sample or rate-limit high-frequency events instead of logging every occurrence.
- **DON'T:**
  - Log inside tight or unbounded loops without sampling — it can dominate latency and flood storage.
  - Perform blocking I/O (network/disk) on the request thread to write logs in a hot path.
  - Serialize large objects/collections into a single log line.

## 8. Log Management

- **What:** Logs are an operational asset with a lifecycle.
- **DO:**
  - Send logs to a centralized aggregator (or at minimum a stable, rotated file) — not only to a developer's console.
  - Define retention and rotation so logs neither fill disks nor disappear before they are useful.
  - Emit timestamps in a consistent timezone (prefer UTC / ISO-8601) so cross-service correlation works.
- **DON'T:**
  - Rely on ephemeral container stdout with no aggregation in production.
  - Keep sensitive logs indefinitely "just in case".

## 9. Code Review Checklist
When reviewing, verify:
- [ ] No secrets, credentials, tokens, or PII are written to logs at any level (§3).
- [ ] Log levels are used deliberately — `ERROR` reserved for actionable failures, no routine flow logged at `WARN`/`ERROR` (§2).
- [ ] Logs are structured (named fields), not string-concatenated messages (§1).
- [ ] A correlation/request ID is attached to every log line for a traceable operation (§4).
- [ ] Business-significant outcomes (confirmed, declined, cancelled, changed) are logged as distinct audit events, not only their failures, and don't depend solely on the general log level (§5).
- [ ] A caught error that isn't rethrown is logged once, at the boundary, with type/message/stack (§6).
- [ ] No logging inside a tight or unbounded loop without sampling or rate-limiting (§7).
- [ ] Logs reach a centralized, rotated destination — not only console/stdout (§8).

## 10. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `logging.md §3`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Secret, credential, token, password, or PII written to a log at any level (§3); exception caught and silently swallowed — neither logged nor rethrown (§6); full auth headers / request bodies logged on a path handling sensitive data (§3) |
| 🟡 **WARN** | Routine/expected flow logged at `ERROR`/`WARN`, or failures logged below `ERROR` (§2); unstructured string-concatenated logs where the project uses structured logging (§1); a business-critical outcome (payment, permission change) logged only on failure with no corresponding success event (§5); same error logged at every layer as it propagates (§6); logging inside an unbounded loop with no sampling (§7); logs with no correlation/request ID in a multi-request service (§4) |
| 🟢 **INFO** | `print`/`console.log` used instead of the project logger (§1); expensive log construction not guarded by a level check (§7); inconsistent or non-UTC timestamps (§8); missing centralized aggregation (§8) |

## 11. Applying This Standard with a Limited Scope

When reviewing or modifying logging in a **specific set of files**, follow these constraints:

1. **Only change logging within the approved Core scope.** If out-of-scope code leaks secrets or swallows errors, apply the Impact Zone / backlog handling below rather than editing it directly.
2. **Removing a sensitive-data leak is always in scope** when it occurs in a file you are already modifying — it is a required fix, not an opportunistic change.
3. **Do not introduce a new logging framework or reconfigure global log settings** unless that configuration file is explicitly in scope; prefer the existing logger.
4. **When adding logs to satisfy this standard**, match the project's existing logger, level conventions, and field names rather than inventing new ones.

**Handling violations outside the Core scope** (per [`rules.md`](../rules.md) → Scope-Locking — Three Zones): a file is either in the **Impact Zone** (a dependent or dependency of a file already in Core, discoverable via `devflow-ctl scope impact <file>`) or **Outside**.
- **Impact Zone + one of the six closed coherence reasons** (broken caller, broken import, contract violation, duplicated logic the task just introduced, a test that now fails, a type/schema that must change together): fix it, then record `devflow-ctl scope justify <file> "<reason>"`.
- **Impact Zone without a closed coherence reason, or Outside entirely:** do not edit it. Defer it instead: `devflow-ctl backlog add <file> "<reason>" --severity {incomplete|info}` — use `incomplete` if the in-scope change is functionally incoherent without that follow-up, `info` if it is a separate improvement.
