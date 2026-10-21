# DevFlow Knowledge Base

## By Topic

### Security
- Endpoints that return customer data check the caller's scope. (project)
- A "same policy as" another endpoint is checked against what that endpoint returns. → E1 → M0001

## Cycle History

### quote-header — 2026-10-01
- The quote header lives in its own endpoint, not in the polled order read. (project)
#### 🔎 Found after review (PR #42)
- Tax id exposure was excused as deliberate on a premise nobody checked. → E1 → M0001
- A missing company shares the order's 404, against the endpoint's contract. → E2
- The happy-path test did not assert createdAt. → E3
