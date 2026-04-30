# DevFlow Engineering Standards: Security (Technology-Agnostic)

> **Note on examples:** All tool names and code fragments are illustrative. Replace them with the actual libraries, services, and conventions of the detected stack.

Apply these principles to all code you design, generate, or review.

## 1. Input Validation
- **What:** All external input must be treated as untrusted until validated.
- **DO:**
  - Validate and sanitize all external input (user input, API parameters, environment variables, file uploads) at the system boundary — the earliest point of entry.
  - Use allowlists (positive validation) wherever possible: define exactly what is permitted and reject everything else.
  - Validate data type, length, format, and range before processing.
  - Normalize input to a canonical form before validation to avoid bypasses using Unicode or encoding tricks.
- **DON'T:**
  - Trust any input from external sources without validation.
  - Use denylists (negative validation) as the primary defense — attackers can often craft payloads that evade them.
  - Rely solely on client-side validation; it is trivially bypassed. Always validate on the server side.

## 2. Authentication & Authorization
- **What:** Verify identity (authentication) and enforce permissions (authorization) on every protected operation.
- **DO:**
  - Use proven, industry-standard authentication protocols (e.g., OAuth2, OpenID Connect). Prefer short-lived access tokens with secure, HTTP‑only, same‑site session cookies for browser clients.
  - Enforce authorization checks at the service/application layer, never only at the UI or API gateway. Every endpoint and use case must verify the caller's permissions.
  - Apply the principle of least privilege: grant only the permissions required for the specific operation.
  - Implement Role-Based Access Control (RBAC) or Attribute-Based Access Control (ABAC) as appropriate, and audit permission changes.
- **DON'T:**
  - Roll your own authentication mechanism — cryptography and session management are extremely hard to get right.
  - Store sensitive tokens in browser storage accessible to JavaScript (e.g., `localStorage`, `sessionStorage`). Prefer secure, HTTP‑only cookies.
  - Skip authorization checks on internal endpoints or background jobs, assuming they are safe because they are not public.

## 3. Secrets Management
- **What:** Credentials and sensitive configuration must never be in source code.
- **DO:**
  - Store secrets in a dedicated secrets manager (e.g., a cloud-based vault service, a self-hosted vault, or encrypted environment variables). Never commit secrets to version control.
  - Use `.gitignore` or equivalent to exclude local secret files. Provide a `.env.example` template with placeholder values for developers.
  - Rotate secrets regularly and on suspicion of compromise. Automate rotation where possible.
  - Inject secrets at runtime via the environment or a secure configuration provider. Prevent secrets from appearing in logs or error messages.
- **DON'T:**
  - Hardcode API keys, passwords, database credentials, or private tokens in source code — not even in test files or examples.
  - Commit `.env` files, key files, or configuration files containing real secrets to version control.
  - Share secrets via email, chat, or documentation.

## 4. Injection Prevention
- **What:** Prevent attackers from injecting malicious code into queries, commands, or outputs.
- **DO:**
  - Use parameterized queries (prepared statements) for all database operations. Never concatenate user input into a query string.
  - Escape or sanitize output appropriately for the target context (HTML entity encoding for web pages, escaping for shell commands, etc.). Use context-aware templating engines with auto-escaping.
  - Validate and sanitize URLs and file paths to prevent path traversal and Server-Side Request Forgery (SSRF).
  - Apply Content Security Policy (CSP) headers in web applications to mitigate cross-site scripting (XSS) risks.
- **DON'T:**
  - Concatenate user input into SQL statements, shell commands, LDAP queries, XML/HTML templates, or any structured language that could be interpreted.
  - Trust that a library or framework will automatically prevent all injection — always understand the safe usage patterns and apply them.

## 5. Dependency Security
- **What:** Third-party code inherits its vulnerabilities into your project.
- **DO:**
  - Prefer well-maintained, actively audited dependencies with a strong security track record.
  - Keep dependencies up to date. Apply security patches promptly — automate vulnerability scanning in the CI/CD pipeline (e.g., dependency audit tools).
  - Review licenses of all dependencies to ensure compliance with your project's distribution model.
  - Pin dependency versions to prevent supply‑chain attacks from compromised updates, and use lockfiles.
- **DON'T:**
  - Add dependencies without verifying their security posture, maintenance status, and license.
  - Ignore vulnerability warnings from dependency scanners — triage and remediate them within a defined time window.
  - Blindly update dependencies without reviewing changelogs and breaking changes, especially for critical or large libraries.

## 6. Error Handling & Information Disclosure
- **What:** Internal errors must never leak system details to clients.
- **DO:**
  - Log errors internally with full context (stack trace, request details, user context) for debugging. Use structured logging and ensure logs do not contain secrets.
  - Return generic, user-friendly error messages to clients. Distinguish between user‑actionable errors (validation failures, not found) and system errors (internal server error) without revealing internals.
  - Configure the application to return minimal error details in production. Use a custom error handler that strips sensitive information.
- **DON'T:**
  - Expose stack traces, internal file paths, database schemas, framework versions, or system details in API responses or UI error messages.
  - Return different error codes or response times that could allow attackers to enumerate users or resources (side‑channel leaks). Use constant‑time comparisons where relevant.

## 7. Additional Security Principles
- **Transport Security:** Encrypt all external communication with TLS (HTTPS). Redirect HTTP to HTTPS. Use HTTP Strict Transport Security (HSTS) for web applications.
- **Data Protection at Rest:** Encrypt sensitive data stored in databases, file systems, or backups using strong, standard algorithms. Manage encryption keys separately from the encrypted data.
- **Rate Limiting & Abuse Prevention:** Apply rate limiting on login, password reset, and other sensitive endpoints to prevent brute‑force attacks. Use CAPTCHAs or proof‑of‑work challenges where appropriate.
- **Logging & Monitoring:** Log security-relevant events (logins, permission changes, access denials, input validation failures). Set up alerts for suspicious patterns.
- **Secure Defaults:** Every component should default to a secure configuration. Developers must explicitly opt in to less secure settings when absolutely necessary.

## 8. Security Interactions & Trade‑offs
- **Validation + Error Handling:** Good input validation reduces the risk of injection and data corruption. Proper error handling ensures that even when validation fails, no internal details are leaked.
- **Authentication + Secrets:** Even strong authentication is useless if the secret keys used to sign tokens are compromised. Secrets management is foundational to authentication.
- **Dependency Security + Patching:** A vulnerable library can bypass all your input validation and authentication. Regular patching is a non‑negotiable part of defense in depth.
- **Performance + Security:** Rate limiting and encryption add overhead, but they are essential. Never disable them for performance without a documented, approved exception and compensating controls.

## 9. Code Review Checklist
When reviewing, verify:
- [ ] All external inputs are validated using allowlists at the system boundary.
- [ ] Authentication uses a proven standard; authorization is enforced at the service layer, not just the UI.
- [ ] No secrets are hardcoded in source code; secrets are managed via a vault or environment variables excluded from version control.
- [ ] Database operations use parameterized queries; output is context‑escaped.
- [ ] Dependencies are pinned, up to date, and free of known critical vulnerabilities.
- [ ] Error responses do not expose stack traces, internal paths, or system details.
- [ ] Sensitive endpoints have rate limiting and abuse prevention.
- [ ] Communication uses TLS; sensitive data at rest is encrypted.

## 10. Applying This Standard with a Limited Scope

When applying security rules to a **specific set of files or modules** (the declared scope), follow these constraints:

1. **Only modify files inside the scope.**
   - If a security vulnerability originates outside the scope (e.g., a missing authorization check in a parent controller), flag it as an INFO note in the in‑scope file and describe the required fix for the external code.
2. **Secrets management fixes.**
   - If you find a hardcoded secret within scope, replace it with a reference to an environment variable or configuration key. Do not modify configuration files or deployment scripts outside the scope to set the actual value — leave a TODO comment for that.
3. **Input validation additions.**
   - Adding validation within a controller or use case is always allowed if both the validation logic and the target file are in scope. Do not introduce new validation libraries or middleware configurations that would touch files outside the scope.
4. **Dependency updates.**
   - Do not run dependency update commands or modify lockfiles unless explicitly within the approved scope and requested by the user. Recommend vulnerability findings as INFO notes.
5. **Error handling improvements.**
   - Replacing a verbose error response with a generic message is safe within scope. Do not modify global error handler configurations unless they are explicitly in scope.
6. **Scope‑safe security improvements are always allowed:**
   - Adding parameterized queries to replace string concatenation within the same file.
   - Escaping output in the same template or function that produces it.
   - Adding a short‑lived token validation check within the in‑scope service method.