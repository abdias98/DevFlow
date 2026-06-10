# DevFlow Engineering Standards: Git Conventions (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-06-10

> **Note on examples:** Branch names, commit scopes, and tag formats are illustrative. Adapt to the team's agreed conventions detected from the existing git history.

Apply these conventions to all commits, branches, and tags produced during a DevFlow cycle.

## 1. Commit Message Format (Conventional Commits)

DevFlow uses **Conventional Commits** (`https://www.conventionalcommits.org`) for all commits produced by agents.

```
<type>(<scope>): <short description>

[optional body]
[optional footer]
```

### Types

| Type | When to use |
|------|-------------|
| `feat` | A new feature or capability visible to the user |
| `fix` | A bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or correcting tests |
| `docs` | Documentation only |
| `perf` | Performance improvement |
| `chore` | Maintenance (deps, build, CI config) |
| `revert` | Reverts a previous commit |

### Rules

- **DO:** Keep the short description under 72 characters. Use the imperative mood: "add user endpoint", not "added" or "adds".
- **DO:** Use the scope to identify the module, feature, or file area affected: `fix(auth): handle expired token gracefully`.
- **DO:** Add a body when the "why" is non-obvious. Separate from the subject with a blank line.
- **DO:** Add `BREAKING CHANGE:` in the footer when a commit introduces a breaking API or behavior change.
- **DON'T:** Use vague scopes (`misc`, `various`, `update`) — name the actual area.
- **DON'T:** Combine unrelated changes in a single commit. One logical change per commit.
- **DON'T:** Reference issue numbers in the short description — use the footer: `Closes #42`.

## 2. Branch Naming

| Pattern | When to use |
|---------|-------------|
| `feat/{slug}` | New feature (default for DevFlow cycles) |
| `fix/{slug}` | Bug fix (standalone Bug-Fixer or debug cycle) |
| `refactor/{slug}` | Refactoring (standalone Refactorer) |
| `perf/{slug}` | Performance improvement |
| `chore/{description}` | Dependency updates, CI changes, tooling |
| `docs/{slug}` | Documentation-only changes |

- **DO:** Use lowercase kebab-case for the slug. Keep it short but descriptive: `feat/user-email-verification`.
- **DO:** Create a branch for every DevFlow cycle — even single-task features. Branches provide an isolated workspace and a clean rollback point.
- **DON'T:** Push directly to `main`/`master`. Always use a branch and PR, even for small fixes.
- **DON'T:** Reuse branch names across unrelated features — stale branches cause confusion.

## 3. Commit Checkpoints (DevFlow-specific)

During a DevFlow lifecycle cycle, commit at each task boundary:

- After each `🟢 Green Phase` (test passes, implementation complete for one task).
- Commit message: `{type}({scope}): {task description}` — derived from the plan's task title.
- Do NOT batch multiple tasks into one commit. Granular commits enable targeted rollback.

## 4. Tagging & Releases

- **DO:** Tag releases following Semantic Versioning: `vMAJOR.MINOR.PATCH`.
- **DO:** Annotate release tags with a message summarizing what changed: `git tag -a v2.1.0 -m "Add email verification feature"`.
- **DON'T:** Tag intermediate development commits — tag only reviewed, merged, and tested states.
- **DON'T:** Force-push tags after they have been shared with collaborators.

## 5. Pull Requests

- **DO:** Target PRs at the base branch configured for the project (typically `main` or `develop`).
- **DO:** Include in the PR description: summary of changes, test instructions, and a link to the DevFlow artifacts (spec, plan).
- **DON'T:** Auto-create PRs — DevFlow agents never run `gh pr create` autonomously. The user creates the PR after reviewing the branch.
- **DON'T:** Force-push to a PR branch that has been reviewed — push new commits instead.

## 6. Code Review Checklist
When reviewing commits and branches, verify:
- [ ] Commit messages follow Conventional Commits format with a meaningful scope.
- [ ] Each commit represents one logical change — no mixed concerns.
- [ ] Branch name matches the type and slug of the feature or fix.
- [ ] No commits directly to `main`/`master`.
- [ ] Breaking changes declared with `BREAKING CHANGE:` footer.
- [ ] Release tags are annotated and follow SemVer.

## 7. Severity Classification

Use when raising findings in code review. Always cite this file and section (e.g., `git-conventions.md §1`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Direct commit to a protected branch (`main`/`master`) without a PR (§2) |
| 🟡 **WARN** | Vague commit message with no scope or actionable description (§1); multiple unrelated changes in one commit (§1); branch name does not match the change type (§2) |
| 🟢 **INFO** | Missing issue reference in footer when one exists (§1); non-annotated release tag (§4) |
