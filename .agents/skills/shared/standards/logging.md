# DevFlow Engineering Standards: Logging & Observability (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-06-15

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

## 5. Error Logging

- **What:** Errors must be observable with enough detail to diagnose, and must never be silently lost.
- **DO:**
  - Log caught errors that are not rethrown, including the exception type, message, and stack trace (or cause chain).
  - Log at the boundary where the error is handled — once — not at every layer it passes through.
  - Include the context needed to reproduce: operation, inputs (sanitized), and correlation ID.
- **DON'T:**
  - **Swallow exceptions** — catching an error and neither logging nor rethrowing hides failures. (This is a blocker; see also `error-handling` guidance where present.)
  - Log the same error repeatedly as it bubbles up (log-and-rethrow at every layer) — it creates duplicate noise.
  - Log an error and then continue as if it succeeded, producing misleading downstream logs.

## 6. Performance & Volume

- **What:** Logging is not free. Excessive or synchronous logging degrades the system it observes.
- **DO:**
  - Guard expensive log-message construction behind a level check (or use the logger's lazy/parameterized API).
  - Prefer asynchronous / buffered log appenders for high-throughput paths, accepting bounded loss on crash where appropriate.
  - Sample or rate-limit high-frequency events instead of logging every occurrence.
- **DON'T:**
  - Log inside tight or unbounded loops without sampling — it can dominate latency and flood storage.
  - Perform blocking I/O (network/disk) on the request thread to write logs in a hot path.
  - Serialize large objects/collections into a single log line.

## 7. Log Management

- **What:** Logs are an operational asset with a lifecycle.
- **DO:**
  - Send logs to a centralized aggregator (or at minimum a stable, rotated file) — not only to a developer's console.
  - Define retention and rotation so logs neither fill disks nor disappear before they are useful.
  - Emit timestamps in a consistent timezone (prefer UTC / ISO-8601) so cross-service correlation works.
- **DON'T:**
  - Rely on ephemeral container stdout with no aggregation in production.
  - Keep sensitive logs indefinitely "just in case".

## 8. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `logging.md §3`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Secret, credential, token, password, or PII written to a log at any level (§3); exception caught and silently swallowed — neither logged nor rethrown (§5); full auth headers / request bodies logged on a path handling sensitive data (§3) |
| 🟡 **WARN** | Routine/expected flow logged at `ERROR`/`WARN`, or failures logged below `ERROR` (§2); unstructured string-concatenated logs where the project uses structured logging (§1); same error logged at every layer as it propagates (§5); logging inside an unbounded loop with no sampling (§6); logs with no correlation/request ID in a multi-request service (§4) |
| 🟢 **INFO** | `print`/`console.log` used instead of the project logger (§1); expensive log construction not guarded by a level check (§6); inconsistent or non-UTC timestamps (§7); missing centralized aggregation (§7) |

## 9. Applying This Standard with a Limited Scope

When reviewing or modifying logging in a **specific set of files**, follow these constraints:

1. **Only change logging within the approved scope.** If out-of-scope code leaks secrets or swallows errors, flag it as a finding (WARN/BLOCK note) rather than editing it.
2. **Removing a sensitive-data leak is always in scope** when it occurs in a file you are already modifying — it is a required fix, not an opportunistic change.
3. **Do not introduce a new logging framework or reconfigure global log settings** unless that configuration file is explicitly in scope; prefer the existing logger.
4. **When adding logs to satisfy this standard**, match the project's existing logger, level conventions, and field names rather than inventing new ones.
