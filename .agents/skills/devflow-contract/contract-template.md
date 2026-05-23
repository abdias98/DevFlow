# Contract Test Report Template

Save to `docs/devflow/contracts/YYYY-MM-DD-{slug}-contract.md`:

```markdown
# API Contract Report: {Title}

**Date:** YYYY-MM-DD
**Agent:** DevFlow API Contract Agent 🔗
**Stack:** {Language} · {Framework}
**Spec:** `docs/devflow/specs/YYYY-MM-DD-{slug}-design.md`

## Endpoints Validated

| # | Method | Path | Contract Match | Discrepancies |
|---|--------|------|:-------------:|---------------|
| 1 | POST | /api/v1/auth/login | ✅ | — |
| 2 | GET | /api/v1/users/{id} | ⚠️ | Missing `avatar_url` in response |
| 3 | DELETE | /api/v1/sessions | ❌ | Returns 200, spec says 204 |

## Contract Definition (from Spec)

### POST /api/v1/auth/login
```
Method: POST
Path: /api/v1/auth/login
Auth: None
Request:  { email: string, password: string }
Response: { token: string, user: { id, email, name } }
Errors:   400 (validation), 401 (invalid credentials)
```

### GET /api/v1/users/{id}
```
Method: GET
Path: /api/v1/users/{id}
Auth: Bearer token
Response: { id, email, name, avatar_url }
Errors:   401 (unauthorized), 404 (not found)
```

{Repeat for each endpoint}

## Discrepancies

| # | Severity | Endpoint | Check | Expected | Actual |
|---|----------|----------|-------|----------|--------|
| 1 | 🟡 WARN | GET /users/{id} | Response shape | `avatar_url` present | Field missing |
| 2 | 🔴 BLOCK | DELETE /sessions | Status code | 204 No Content | 200 OK |

## Contract Tests Generated

| # | Test File | Endpoints Covered | Scenarios |
|---|-----------|:-----------------:|:----------|
| 1 | `tests/contract/auth.contract.test.ts` | 3 | Happy, validation, auth, edge |
| 2 | `tests/contract/users.contract.test.ts` | 1 | Happy, 401, 404 |

**Run contract tests:**
```bash
{Test Command (single file)} tests/contract/auth.contract.test.ts
{Test Command (single file)} tests/contract/users.contract.test.ts
```

## Coverage Summary

| Metric | Value |
|--------|-------|
| Endpoints defined in spec | {N} |
| Endpoints validated | {N}/{N} ({N}%) |
| Contract matches | {N} |
| Discrepancies (total) | {N} |
| Discrepancies (🔴 BLOCK) | {N} |

## Notes

{Any context, false positives, or follow-up recommendations}
```
