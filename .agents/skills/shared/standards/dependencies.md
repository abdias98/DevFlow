# DevFlow Engineering Standards: Dependency Management & Supply Chain (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-06-15

> **Note on examples:** All manifest files, lockfiles, audit tools, and registries are illustrative. Replace them with the actual package manager and ecosystem of the detected stack (npm, pip, Maven, Cargo, Go modules, Composer, NuGet, etc.).

Apply these principles whenever you add, update, remove, or review third-party dependencies, manifests, lockfiles, or build configuration.

## 1. Minimize the Dependency Surface

- **What:** Every dependency is code you did not write but must trust, ship, patch, and audit.
- **DO:**
  - Prefer the standard library or existing project dependencies before adding a new package.
  - Justify each new dependency: what it provides, why it beats writing it, and its maintenance health (activity, maintainers, downloads, open critical issues).
  - Favor small, focused, well-maintained packages over large frameworks pulled in for one function.
- **DON'T:**
  - Add a heavy dependency for a trivial, easily-inlined utility (a one-liner is not worth a supply-chain risk).
  - Add a package that is unmaintained, archived, or has a single anonymous maintainer for security-sensitive functionality.
  - Duplicate functionality already provided by an existing dependency.

## 2. Pin Versions & Commit Lockfiles

- **What:** Reproducible builds require that the exact same dependency tree resolves every time, everywhere.
- **DO:**
  - Commit the lockfile (or equivalent) so CI, teammates, and production resolve identical versions.
  - Use the ecosystem's reproducible-install command in CI (the one that fails if the lockfile is out of date), not a loose install.
  - Use explicit, bounded version ranges in the manifest; let the lockfile pin the exact resolved versions.
- **DON'T:**
  - Use unbounded/floating specifiers (`*`, `latest`) for production dependencies.
  - Add a `.gitignore` entry for the lockfile, or regenerate it casually without reviewing the resulting diff.
  - Hand-edit the lockfile.

## 3. Vulnerability Auditing

- **What:** Known-vulnerable dependencies are one of the most common breach vectors.
- **DO:**
  - Run the ecosystem's audit/advisory tool (the project's `Audit Command`) and treat **critical/high** vulnerabilities as release blockers.
  - Keep auditing in CI so new advisories on existing dependencies are caught over time, not only at install.
  - Remediate by upgrading to a patched version; if none exists, isolate, apply a vetted override, or remove the dependency.
- **DON'T:**
  - Ship a release with known critical/high vulnerabilities and no documented, time-boxed mitigation.
  - Suppress an audit finding without recording the rationale and a follow-up.

## 4. Integrity & Source Trust

- **What:** Dependencies must come from trusted sources and arrive unmodified.
- **DO:**
  - Install only from the official/approved registry (or an internal mirror); verify integrity hashes/checksums where the ecosystem supports it.
  - Be alert to typosquatting and dependency confusion: confirm the exact package name and that internal package names cannot be shadowed by a public registry.
  - Prefer dependencies that publish provenance/signatures when available.
- **DON'T:**
  - Install packages from arbitrary URLs, gists, or unverified forks in production builds.
  - Disable integrity/checksum verification to make an install "just work".

## 5. License Compliance

- **What:** A dependency's license governs how the product may be distributed; the wrong license is a legal and business risk.
- **DO:**
  - Check each new dependency's license against the project's allowed-license policy.
  - Flag copyleft or restrictive licenses (e.g., strong-copyleft) when they conflict with how the product is shipped.
  - Record attributions/notices the licenses require.
- **DON'T:**
  - Introduce a dependency with a license incompatible with the project's distribution model.
  - Add a dependency with no license, or an unclear/unknown license, to a distributed product.

## 6. Updating Dependencies

- **What:** Dependencies must be kept current for security and compatibility — but updates carry risk.
- **DO:**
  - Update deliberately: read the changelog, watch for breaking changes, and run the full test suite after upgrading.
  - Apply security patches promptly; batch routine upgrades and keep them reviewable (separate from feature changes).
  - Update one logical group at a time so a regression is easy to bisect.
- **DON'T:**
  - Bulk-bump everything blindly in a single commit mixed with feature work.
  - Defer security-critical updates indefinitely, or stay on an end-of-life/unsupported major version without a plan.

## 7. Transitive Dependencies & Footprint

- **What:** Most of the dependency tree is indirect — and is shipped and audited just the same.
- **DO:**
  - Be aware of what transitive dependencies a new package pulls in; prefer packages with a lean tree.
  - Use overrides/resolutions to force a patched transitive version when a direct upgrade is not yet available.
  - Separate development/build-only dependencies from runtime/production dependencies so production ships less.
- **DON'T:**
  - Ship development/test tooling as a production runtime dependency.
  - Ignore a transitive vulnerability because it is "not a direct dependency" — it still ships.

## 8. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `dependencies.md §3`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Release with a known **critical/high** dependency vulnerability and no documented mitigation (§3); dependency installed from an untrusted/arbitrary source or with integrity verification disabled (§4); dependency whose license is incompatible with the product's distribution model added to shipped code (§5); lockfile removed/ignored so builds are non-reproducible (§2) |
| 🟡 **WARN** | Unbounded/floating version specifier (`*`/`latest`) for a production dependency (§2); new dependency added with no justification when an existing one or the standard library suffices (§1); unmaintained/archived package added for security-sensitive functionality (§1); development/build tool declared as a production runtime dependency (§7); audit not run in CI (§3) |
| 🟢 **INFO** | Heavy dependency added for a trivial utility (§1); routine upgrades long overdue (§6); dependency tree could be leaner / transitive footprint noted (§7); license attribution/notice missing (§5) |

## 9. Applying This Standard with a Limited Scope

When reviewing or modifying dependencies in a **specific set of files**, follow these constraints:

1. **Only change manifests/lockfiles within the approved scope.** A dependency change is rarely "trivial" — it affects the whole build, so treat manifest/lockfile edits as in-scope only when the task explicitly calls for them.
2. **Removing a known critical/high vulnerability or an untrusted source is always worth surfacing** — if it is outside scope, raise it as a BLOCK/WARN finding rather than silently bumping versions.
3. **Do not perform a broad dependency upgrade** as a side effect of an unrelated change; propose it separately so the resulting lockfile diff is reviewable on its own.
4. **When adding a dependency to satisfy a task**, prefer one already present or in the same ecosystem the project uses, and update the lockfile with the standard tooling (never by hand).
