# Final Summary Template

```markdown
## 🚀 DevFlow Finalization — {Feature Name}

### ✅ Definition of Done
| Criterion | Status |
|-----------|--------|
| {criterion from context.md} | ✅ Met / ⚠️ Not verified |

### ✅ Tests
{N} tests passing | 0 failing

### 📦 Files Changed
**Created:**
- `path/to/new-file`

**Modified:**
- `path/to/existing-file`

### 🧪 Tests Added
| Test File | Test Cases |
|-----------|------------|
| `path/to/test` | N tests |

### 🏗️ Architecture Decisions
{Key decisions from spec — 2-4 bullet points}

### ▶️ How to Run / Test
{Exact command(s)}

### 📚 Documentation
{APIs, components, configs changed — or "No updates needed"}

### 💡 Next Steps
> Format by project type:
> - **Web/mobile:** Story format: *As a {user}, I want to {goal}. (Est: S/M/L)*
> - **Library/CLI:** *Add support for {capability}. (Est: S/M/L)*
> - **General:** *[HIGH/MED/LOW] {action}*

### 📄 Artifacts
- Spec:   `docs/devflow/specs/{file}`
- Plan:   `docs/devflow/plans/{file}` ✔️ *(checkboxes updated)*
- Review: `docs/devflow/reviews/{file}`

### 📤 Stack PRs *(Stack Mode = yes only)*
| Stack | Branch | Base | PR Title | Status |
|-------|--------|------|----------|--------|

> The team reviews and merges stacked PRs in order.
```

## Knowledge Persistence

Before cleaning session, append to `/memories/repo/devflow-project-knowledge.md`:

```markdown
## YYYY-MM-DD — {slug}
- **Stack detected:** {tech stack}
- **Key conventions found:** {naming, test structure, organization}
- **Reusable patterns discovered:** {wrappers, base classes, utilities}
- **Pitfalls encountered:** {issues that caused rework}
```

## Finalization Rules

| Rule | Reason |
|------|--------|
| NEVER finalize if tests fail | Ship only green code |
| NEVER finalize if BLOCK findings unresolved | Don't ship broken design |
| NEVER finalize if DoD unverified | Feature isn't done |
| ALWAYS clean session memory | Prevents stale context |
| ALWAYS update plan checkboxes | Clean, auditable record |
| ALWAYS include "How to Run" | User verifies independently |
| ALWAYS include Stack PR summary if stacked | Complete PR list needed |
