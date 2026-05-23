# Documentation Report Template

Save to `docs/devflow/documentation/YYYY-MM-DD-{slug}-docs.md`:

```markdown
# Documentation Report: {Title}

**Date:** YYYY-MM-DD
**Agent:** DevFlow Documentation Agent 📚
**Stack:** {Language} · {Framework}

## Documentation Generated

| Document | Action | Sections | Artifact Sources |
|----------|:------:|----------|------------------|
| README.md | Created / Updated | {N} sections | {specs}, {summaries} |
| API.md | Created / Updated | {N} endpoints | {specs} |
| CHANGELOG.md | Updated | {N} entries | {summaries}, {plans} |
| ARCHITECTURE.md | Updated | {N} sections | {specs}, {knowledge-base} |

## Artifact Sources Used

| Artifact | Type | Used for |
|----------|------|----------|
| `docs/devflow/specs/2026-05-22-user-auth-design.md` | Spec | API endpoints, Architecture, Design Decisions |
| `docs/devflow/specs/2026-05-23-payment-design.md` | Spec | Data Structures, Risk Assessment |
| `docs/devflow/plans/2026-05-22-user-auth.md` | Plan | File Map, Tech Stack |
| `docs/devflow/summaries/2026-05-22-user-auth-summary.md` | Summary | How to Run, Files Changed |
| `docs/devflow/reviews/2026-05-22-user-auth-review.md` | Review | Quality notes |
| `docs/devflow/knowledge-base/learnings.md` | KB | Patterns, Decisions |

## README.md — Sections Updated

| Section | Source | Status |
|---------|--------|:------:|
| Project name + description | Spec Context | ✅ |
| Tech stack | Stack Profile | ✅ |
| How to run / test | Summary | ✅ |
| Project structure | Plan File Map + Spec Architecture | ✅ |
| Contributing | Existing README (preserved) | ⚠️ Unchanged |

## API.md — Endpoints Documented

| # | Method | Path | Source |
|---|--------|------|--------|
| 1 | POST | /api/v1/auth/register | `user-auth-design.md` |
| 2 | POST | /api/v1/auth/login | `user-auth-design.md` |
| 3 | GET | /api/v1/users/{id} | `user-auth-design.md` |

## CHANGELOG.md — Entries Added

| Version | Date | Type | Description |
|---------|------|------|-------------|
| 1.1.0 | 2026-05-22 | Added | User authentication (register, login, profile) |
| 1.2.0 | 2026-05-23 | Added | Payment gateway integration |

## Notes

{Any documentation gaps, sections that need manual review, or follow-up recommendations}
```
