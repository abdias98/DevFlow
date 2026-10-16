# DevFlow Engineering Standards: Git Conventions (Technology-Agnostic)

> **Version:** 1.2.1 | **Last Updated:** 2026-10-12

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
| `perf` | Performance improvement with no behavior change and a measurable gain (otherwise `feat`/`fix`, noting the gain in the body) |
| `chore` | Maintenance (deps, build, CI config) |
| `build` | Build system or packaging change (build scripts, bundler config, artifacts) |
| `ci` | Continuous-integration change (pipelines, runners, workflow definitions) |
| `style` | Formatting-only change with no logic impact (whitespace, lint fixes) |
| `revert` | Reverts a previous commit |

### Rules

- **DO:** Keep the short description under 72 characters. Use the imperative mood: "add user endpoint", not "added" or "adds".
- **DO:** Use the scope to identify the module, feature, or file area affected: `fix(auth): handle expired token gracefully`.
- **DO:** Add a body when the "why" is non-obvious. Separate from the subject with a blank line.
- **DO:** Add `BREAKING CHANGE:` in the footer when a commit introduces a breaking API or behavior change.
- **DO:** Mark a breaking commit in the subject too with the `!` indicator (`feat!: drop Node 18 support`, `fix!: change default retry policy`) together with the `BREAKING CHANGE:` footer describing the break and the migration path.
- **DO:** Use `perf` only for a change whose observable behavior is identical and whose gain is measurable; a faster feature or a faster fix is `feat`/`fix` (with the gain noted in the body), not `perf`.
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
- [ ] Commits are signed and carry a `Signed-off-by` trailer where the project requires them (§11); the merge strategy and hook enforcement match the project policy (§12).

## 7. Severity Classification

Use when raising findings in code review. Always cite this file and section (e.g., `git-conventions.md §1`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Direct commit to a protected branch (`main`/`master`) without a PR (§2) |
| 🟡 **WARN** | Vague commit message with no scope or actionable description (§1); multiple unrelated changes in one commit (§1); branch name does not match the change type (§2); unsigned commit landing where signatures are required, or missing DCO sign-off where mandated (§11); merge applied with the wrong strategy, or hooks bypassed with `--no-verify` (§12) |
| 🟢 **INFO** | Missing issue reference in footer when one exists (§1); non-annotated release tag (§4) |

## 8. Applying This Standard with a Limited Scope

When applying git conventions to a **specific set of files or a single change** (the declared Core scope), follow these constraints:

1. **Only rewrite commits/branches you created in this cycle.** Do not amend, rebase, or rename commits or branches that predate the current task.
2. **A commit message or branch name violation in your own change is always in scope to fix** — rename the branch or amend the still-unpushed commit before opening the PR.
3. **Do not rewrite shared history** (`git commit --amend` on a pushed commit, `git rebase` on a shared branch, `git push --force` to a shared branch) as a side effect of applying this standard; that is always an explicit, separately-confirmed action per `rules.md` → Approval & Confirmation.

**Handling violations outside the Core scope** (per [`rules.md`](../rules.md) → Scope-Locking — Three Zones): a file is either in the **Impact Zone** (a dependent or dependency of a file already in Core, discoverable via `devflow-ctl scope impact <file>`) or **Outside**.
- **Impact Zone + one of the six closed coherence reasons** (broken caller, broken import, contract violation, duplicated logic the task just introduced, a test that now fails, a type/schema that must change together): fix it, then record `devflow-ctl scope justify <file> "<reason>"`.
- **Impact Zone without a closed coherence reason, or Outside entirely:** do not edit it. Defer it instead: `devflow-ctl backlog add <file> "<reason>" --severity {incomplete|info}` — use `incomplete` if the in-scope change is functionally incoherent without that follow-up, `info` if it is a separate improvement.

## 9. Design-Time Decisions

The plan settles these — its branch and its commit checkpoints are written before the first line of code.

- **Branch** — the branch type and slug for the cycle (§2).
- **Identity** — whether commits must be signed and DCO sign-off applied (§11).
- **Commit boundaries** — one commit per task checkpoint, with its message written in the plan (§1, §3).
- **Breaking changes** — whether any commit breaks an API or behavior, and its footer (§1).
- **Release impact** — the version bump the change implies when a release follows (§4).
- **Pull request** — target branch and the artifacts its description links (§5).

## 10. Implementation Self-Check

Before marking a task done:

- [ ] Work happens on the cycle's branch, never directly on `main` (§2).
- [ ] Each commit is one logical change with a `type(scope): description` message in the imperative, under 72 characters (§1).
- [ ] A task is committed only after test output confirmed it passes (§3).
- [ ] A commit that breaks an API or behavior carries a `BREAKING CHANGE:` footer (§1).
- [ ] No force-push rewrote a pull request branch that has already been reviewed (§5).
- [ ] Commits are signed (and carry DCO sign-off) where required, and no hook was bypassed to land them (§11, §12).

## 11. Signed Commits & Identity Attestation

- **What:** A commit history is trustworthy only if authorship is verifiable — signatures prove who wrote what, and DCO records that the author had the right to contribute it.
- **DO:**
  - Sign commits and tags (GPG or SSH keys) on projects that require it, and verify signatures in CI before merge.
  - Add a `Signed-off-by` trailer (Developer Certificate of Origin) where the project mandates DCO, affirming authorship and license compliance of the contribution.
  - Prefer SLSA-2026-style provenance for release artifacts (signed attestation of the source commit and build) on distributed releases.
- **DON'T:**
  - Push unsigned commits where signatures are required, or disable signature verification to land faster.
  - Strip `Signed-off-by` trailers when rebasing someone else's commits, or commit under another author's name/email without their knowledge.

## 12. Merge Strategy & Hook Enforcement

- **What:** How branches land and how conventions are enforced must be explicit — otherwise every PR invents its own history shape.
- **DO:**
  - Follow the project's merge policy explicitly: merge commit (history preserved), squash (one commit per PR), or rebase/linear history — never mix strategies within one branch's lifetime without agreement.
  - Enforce conventions with hooks and CI (commit-msg lint, signature check, branch-name check) rather than relying on memory; a hook failure blocks the push, not the review.
- **DON'T:**
  - Rewrite shared history (amend/rebase/force-push on a shared branch) without explicit, separately-confirmed approval.
  - Bypass hooks (`--no-verify`) to land a commit that violates this standard — fix the commit instead.
