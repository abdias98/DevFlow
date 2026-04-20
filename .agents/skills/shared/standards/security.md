# DevFlow Engineering Standards: Security

Apply these principles to all code you design, generate, or review.

## 1. Input Validation
- **What:** All external input must be treated as untrusted until validated.
- **DO:** Validate and sanitize all external input (user input, API params, env vars) at the system boundary. Use allowlists.
- **DON'T:** Trust any input from external sources or use denylists as the primary defense.

## 2. Authentication & Authorization
- **What:** Verify identity (authn) and enforce permissions (authz) on every protected operation.
- **DO:** Use proven standards (OAuth2, JWT with short expiry, RBAC). Enforce authorization checks at the service layer, not only the UI.
- **DON'T:** Roll your own auth mechanism, store tokens in localStorage without HttpOnly cookies, or skip authorization checks on internal endpoints.

## 3. Secrets Management
- **What:** Credentials and sensitive config must never be in source code.
- **DO:** Store secrets in environment variables or dedicated vaults (e.g., AWS Secrets Manager, HashiCorp Vault, `.env` files excluded from git).
- **DON'T:** Hardcode API keys, passwords, or tokens in source code or commit them to version control.

## 4. Injection Prevention (OWASP Top 10)
- **What:** Prevent attackers from injecting malicious code into queries or commands.
- **DO:** Use parameterized queries / prepared statements for all database operations. Escape output in templates.
- **DON'T:** Concatenate user input into SQL, shell commands, or HTML templates.

## 5. Dependency Security
- **What:** Third-party code inherits its vulnerabilities into your project.
- **DO:** Prefer well-maintained, audited dependencies. Keep them up to date. Run `npm audit` / `pip-audit` / equivalent regularly.
- **DON'T:** Add dependencies without verifying their security posture and license.

## 6. Error Handling & Information Disclosure
- **What:** Internal errors must never leak system details to clients.
- **DO:** Log errors internally with full context. Return generic, user-friendly messages to clients.
- **DON'T:** Expose stack traces, internal paths, database schemas, or system details in API responses or UI error messages.
