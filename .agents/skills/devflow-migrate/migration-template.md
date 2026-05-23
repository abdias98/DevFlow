# Migration Report Template

Save to `docs/devflow/migrations/YYYY-MM-DD-{slug}-migration.md`:

```markdown
# Migration Report: {Title}

**Date:** YYYY-MM-DD
**Agent:** DevFlow Migration Agent 🗄️
**Stack:** {Language} · {Framework} · {Database} · {ORM}
**Source:** `docs/devflow/specs/YYYY-MM-DD-{slug}-design.md`

## Schema Changes

| # | Operation | Table | Detail | Up | Down |
|---|-----------|-------|--------|----|------|
| 1 | Add column | users | `last_login_at` (timestamp, nullable) | Add column | Drop column |
| 2 | Add table | audit_logs | id, user_id, action, created_at | Create table | Drop table |
| 3 | Add index | audit_logs | idx_audit_user_id on user_id | Create index | Drop index |

## Migration Files Generated

| # | File | Operations | Rollback |
|---|------|:----------:|----------|
| 1 | `migrations/20260522_143000_add_last_login.sql` | 1 up | 1 down |
| 2 | `migrations/20260522_143001_create_audit_logs.sql` | 1 up | 1 down |

## Compatibility Analysis

### Forward (Up)

- [ ] All operations are additive (no destructive changes)
- [ ] New columns have defaults or are nullable
- [ ] New tables have no circular foreign keys
- [ ] Indexes created for new foreign keys

### Backward (Down)

- [ ] Every `up` has a corresponding `down`
- [ ] Rollback restores the exact previous state
- [ ] No data loss on rollback (or explicitly noted)

### Zero-Downtime Assessment

| Operation | Risk | Strategy |
|-----------|:----:|----------|
| Add `last_login_at` (nullable) | 🟢 None | Direct — nullable column, no table lock |
| Create `audit_logs` table | 🟢 None | Direct — new table, no impact on existing |
| Add index on `audit_logs.user_id` | 🟡 Low | Use `CONCURRENTLY` (PostgreSQL) or create during low-traffic window |

## Apply Commands

**Apply migrations:**
```bash
{exact migration command detected from project}
```

**Rollback last migration:**
```bash
{exact rollback command detected from project}
```

**Verify schema after migration:**
```bash
{verify command — e.g., check table structure, run schema tests}
```

## Rollback Plan

If migration causes issues in production:

1. Run rollback: `{rollback command}`
2. Verify schema restored: `{verify command}`
3. Monitor for errors: check logs, error rates, application health

## Notes

{Any context, multi-step strategies, or follow-up recommendations}
```
