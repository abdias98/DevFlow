# Standards Profile Template

Saved to `docs/devflow/knowledge-base/standards-profile.md`.

> **Purpose:** DevFlow's standards are deliberately technology-agnostic — "translate errors at layer boundaries", "release resources on every path", "keep business logic out of the entry point". An agent that applies them without knowing how *this* project does those things applies them generically, and the result looks like code from somewhere else. The profile is the bridge: for each applicable standard, the concrete idiom this project uses, and a real file that shows it.

## Rules for Filling It

- **Every row names at least one real file** in the repository as its canonical example. A row with no example is a guess, not a profile entry — leave it out.
- **Describe what the project does, not what it should do.** A convention the code does not follow goes under *Known Deviations*, not under the idioms.
- **Only standards whose domain the project has.** A CLI with no UI has no `ui-design.md` row.
- **Idioms, not rules.** The rule lives in the standard; the row says *how it is expressed here* ("errors cross the service boundary as `AppError` subclasses via `toAppError()`"), and cites the standard section it expresses.
- **Keep it current.** The Finalizer updates a row when a cycle introduces or changes a convention; a stale profile is worse than none.

---

```markdown
# Standards Profile — {project name}

**Generated:** YYYY-MM-DD · **Last updated:** YYYY-MM-DD ({slug of the cycle that last changed it})
**Stack:** {language · framework · test runner · build tool}
**Sources:** `AGENTS.md` · `shared/templates/{type}.md` · exploration of {N} files · {N} DevFlow cycles

> Agents read this with `learnings.md`. A standard says *what* must hold; this profile says *how this project expresses it*. When this profile and a generic reference template disagree, this profile wins.

## Where Responsibilities Live

| Responsibility | Location / convention | Canonical example |
|----------------|-----------------------|-------------------|
| Entry point and dependency wiring | {e.g. `src/main.ts` builds the container} | `{path}` |
| Business rules | {…} | `{path}` |
| Data access | {…} | `{path}` |
| External service clients | {…} | `{path}` |
| Input validation at the boundary | {…} | `{path}` |
| Error translation and error responses | {…} | `{path}` |
| State (UI stores, caches, sessions) | {…} | `{path}` |
| UI components *(if UI)* | {…} | `{path}` |
| Tests, fixtures and factories | {…} | `{path}` |

## Standard → Project Idioms

| Standard | How this project expresses it | Canonical example |
|----------|-------------------------------|-------------------|
| `clean-architecture.md §1` | {e.g. domain modules import only from `src/domain` and `src/ports`} | `{path}` |
| `error-handling.md §4` | {…} | `{path}` |
| `security.md §2` | {…} | `{path}` |
| `concurrency.md §2` | {…} | `{path}` |
| `logging.md §4` | {…} | `{path}` |
| `testing.md §3` | {…} | `{path}` |
| `ui-design.md §13` *(if UI)* | {…} | `{path}` |

## Primitives

The project's chosen mechanism for recurring needs — so a task uses the existing one instead of introducing a second.

| Need | Use | Avoid | Example |
|------|-----|-------|---------|
| Cancel or supersede in-flight work | {…} | {…} | `{path}` |
| Release resources / dispose subscriptions | {…} | {…} | `{path}` |
| Transactions / atomic multi-step writes | {…} | {…} | `{path}` |
| Validation | {…} | {…} | `{path}` |
| Timeouts and retries | {…} | {…} | `{path}` |
| Idempotency / dedup | {…} | {…} | `{path}` |
| Caching and invalidation | {…} | {…} | `{path}` |
| Time and scheduling in tests | {…} | {…} | `{path}` |

## Known Deviations

Places where the codebase does not follow a standard today — so agents neither copy the deviation into new code nor "fix" it outside scope.

| Standard | Deviation | Where | Tracked in |
|----------|-----------|-------|------------|
| `{standard}.md §{N}` | {what the code does instead} | `{path}` | {backlog ID / "not tracked"} |
```
