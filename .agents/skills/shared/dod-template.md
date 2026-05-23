# Definition of Done — Universal Criteria

These criteria apply to EVERY DevFlow cycle regardless of feature type. The Brainstormer adds feature-specific criteria on top of these defaults.

## Universal Checklist

Every feature MUST satisfy these before the Finalizer can complete the cycle:

### Code Quality
- [ ] **Lint passes:** `{Lint Command}` exits with zero errors
- [ ] **Build succeeds:** `{Build Command}` completes without errors
- [ ] **Dependencies audited:** No critical/high vulnerabilities reported by `{Audit Command}` *(if configured)*
- [ ] **No hardcoded secrets:** No API keys, tokens, or credentials in source files
- [ ] **Scope respected:** No files modified outside the approved plan
- [ ] **Standards compliance:** SOLID, Clean Architecture, Security, Performance standards checked by Reviewer

### Testing
- [ ] **All tests pass:** `{Test Command}` exits with zero failures
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
- [ ] User can register with email and password
- [ ] Invalid email shows validation error
- [ ] Confirmation email is sent after registration
```

These are combined with the universal criteria above to form the complete DoD.
