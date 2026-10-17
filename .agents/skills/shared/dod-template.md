# Definition of Done — Universal Criteria

These criteria apply to EVERY DevFlow cycle regardless of feature type. The Brainstormer adds feature-specific criteria on top of these defaults.

## Universal Checklist

Every feature MUST satisfy these before the Finalizer can complete the cycle:

### Code Quality
- [ ] **Lint passes:** `{Lint Command}` exits with zero errors — proven by `devflow-ctl evidence check --kind lint,typecheck`, not by a claim
- [ ] **Build succeeds:** `{Build Command}` completes without errors — `devflow-ctl evidence check --kind build`
- [ ] **Dependencies audited:** No critical/high vulnerabilities reported by `devflow-ctl scan sca` *(skips honestly if no supported manifest/tool is present)*
- [ ] **No hardcoded secrets:** No API keys, tokens, or credentials in source files
- [ ] **Scope respected:** No files modified outside the approved plan
- [ ] **Standards compliance:** SOLID, Clean Architecture, Security, Performance standards checked by Reviewer

### Requirements Validation
- [ ] **Validation Gate completed:** All assumptions challenged, standards scanned, risks flagged
- [ ] **BLOCK issues resolved:** Any security, architectural, or contradiction issues from the Validation Gate accepted or fixed
- [ ] **Additional Recommendations documented:** Out-of-scope improvements recorded for future cycles

### Testing
- [ ] **All tests pass:** `{Test Command}` exits with zero failures — `devflow-ctl evidence check --kind test` on the final tree (a kind the project doesn't have is reported as *not verified*, never as passed)
- [ ] **No regression:** Existing tests continue to pass
- [ ] **New tests cover:** Happy path, edge cases, and failure scenarios for all new code
- [ ] **Test files created:** At least one test file per task in the plan

### Artifacts
- [ ] **Plan complete:** All task checkboxes marked `[x]`
- [ ] **Review resolved:** No unresolved BLOCK findings
- [ ] **Traceability ≥ 100%:** All DoD criteria and edge cases mapped to tests

### Operational
- [ ] **How to Run documented:** Final summary includes exact commands
- [ ] **Rollback path clear:** If HIGH-risk, rollback steps are documented
- [ ] **Dependencies verified:** No breaking changes to dependent features

## Usage

The Brainstormer generates the feature-specific DoD in `context.md`. The universal criteria above are automatically included — the Brainstormer only needs to add feature-specific verifiable outcomes.

Example feature-specific criteria added by Brainstormer:
```markdown
## Definition of Done
- [ ] User can register with email and password → verify: test — POST /register returns 201 and the user row exists
- [ ] Invalid email shows validation error → verify: test — 422 with error `email.invalid`, nothing persisted
- [ ] Confirmation email is sent after registration → verify: test — the mail adapter receives exactly one message to that address
```

These are combined with the universal criteria above to form the complete DoD.
