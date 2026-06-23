# Plan Document Template

> **For agentic workers:** Use devflow-implement (Red→Green per task) → devflow-review to execute this plan task-by-task.

**Goal:** {One-sentence summary}
**Architecture:** {Brief reference to spec document path}
**Rigor:** {light | standard | deep | maximum} — {one-line reason}
**Mockup:** `docs/devflow/mockups/YYYY-MM-DD-{slug}-mockup.html` *(UI features only — omit for backend/CLI/library)*
**Tech Stack:** {Detected from workspace}

---

## Plan Digest

> **Purpose:** a 10-20 line structured summary that downstream agents (Implementer, Reviewer, Verifier, Task Supervisor) read FIRST. If the digest answers their questions, they skip reading the full plan. If it raises questions, they read the specific task's full work packet. Saves ~60-80% of plan read cost.

```markdown
## Plan Digest
- **Tasks:** {N} tasks in {M} waves
- **Files to create:** {list}
- **Files to modify:** {list}
- **Key dependencies:** {task A → task B (B needs A's output)}
- **Risk areas:** {tasks with HIGH risk — one line each}
- **Test strategy:** {unit per task + integration for {X} + e2e for {Y}}
- **Scope:** {what's explicitly out of scope}
```

---

## File Map

> Adapt section headings to the project's actual architecture. Examples below — use only the layers that exist in the detected stack.

**Modify:**
- `path/to/file` — description of change

**Create:**
- `path/to/new-file` — purpose

*(For web projects, group by Backend / Frontend. For Android, group by layer: Data / Domain / Presentation. For PHP/Laravel, group by: Controllers / Models / Views / Migrations. For CLI, group by: Commands / Services / Config. Adapt as needed.)*

---

### Task N: {Title}

> **Risk:** 🔴 HIGH / 🟡 MEDIUM / 🟢 LOW — {one-line reason from spec's Risk Assessment} *(omit if LOW and no special notes)*
> **Affects existing:** {list of features/files that currently use what this task modifies, or "None"} *(include if Impact flag set in context.md)*
> **Reference implementation:** `{path/to/similar-existing-file}` — {what to replicate from it} *(from codebase exploration)*

**Goal:** {What should exist at the end of this task — one sentence}
**Context:** {Relevant files, prior decisions, spec sections, and knowledge-base patterns that inform this task}
**Constraints:** {What not to touch, assume, or expose — scope boundaries for this task}
**Acceptance criteria:** {How success will be judged — verifiable conditions, not implementation steps}

**Deliverables:**
- Modify: `path/to/file` — {description of change}
- Create: `path/to/new-file` — {purpose}

**Implementation guide:**
{Complete code snippets for each file change. The Implementer follows these as a guide and may adapt the approach if a justified improvement exists — any deviation must be documented and flagged to the user per the Implementer's deviation policy.}

- [ ] **Commit checkpoint**
```bash
git add {specific files}
git commit -m "{conventional commit message}"
```

#### ♿ Accessibility (if UI task)
- [ ] All interactive elements have `aria-label` or visible label
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Color contrast meets WCAG 2.1 AA (4.5:1 for text)
- [ ] No keyboard traps
*(Omit this section for non-UI tasks)*

#### ⏪ Rollback (if HIGH-risk task)
```bash
{Exact command(s) to revert this task's changes if something goes wrong}
```
*(Omit this section for LOW/MEDIUM risk tasks)*

#### 🧪 Tests for this Task

**Test file:** `{path/to/feature.test.ext}` *(create new / add to existing)*

```{language}
{Complete, ready-to-paste test code using the detected test framework and conventions.
Must include:
  - All required imports, use statements, annotations, or setup methods
  - Test class/function/block structure matching the project's existing patterns
  - At least one test per scenario below
  - Assertions that will FAIL because the production code doesn't exist yet

Example structure varies by stack:
  - JS/TS (Jest/Vitest): describe + test/it blocks, expect assertions
  - PHP (PHPUnit): class extending TestCase, public test methods, $this->assert*
  - Python (pytest): functions prefixed test_, assert statements
  - Java/Android (JUnit): @Test annotated methods, assertEquals/assertTrue
  - .NET (xUnit/NUnit): [Fact]/[Test] annotated methods, Assert class}

// ✅ Happy path
{test for normal expected behavior}

// ⚠️ Edge case
{test for boundary or unexpected input}

// ❌ Failure / error scenario
{test that verifies correct error handling}
```

**Run command:**
```bash
{exact command to execute only these tests, adapted to the detected stack}
```

> ⚠️ All tests above MUST fail on first run (red phase). They will pass after the production code is implemented.

---

### Self-Review Checklist
- [ ] All spec requirements are covered
- [ ] Each task has a **Goal**, **Context**, **Constraints**, **Acceptance criteria**, and **Deliverables** section
- [ ] Each task has a commit checkpoint
- [ ] Code snippets in the Implementation guide are complete (not partial)
- [ ] Each task has a `🧪 Tests for this Task` section with complete, runnable test code
- [ ] Each test section has at least one happy path, one edge case, one failure scenario
- [ ] Each test section includes the exact run command
- [ ] Test code uses the detected test framework and follows project conventions
- [ ] Dependencies between tasks are respected
- [ ] No orphan files (everything referenced exists)
- [ ] Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) format: `type(scope): description` (types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`)
- [ ] HTML wireframe mockup generated (UI features only) — saved to `docs/devflow/mockups/`
- [ ] **Rigor** level classified and set via `devflow-ctl config set rigor {level}`
