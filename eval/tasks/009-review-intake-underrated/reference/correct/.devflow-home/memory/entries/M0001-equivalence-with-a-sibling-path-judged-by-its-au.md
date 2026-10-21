---
id: M0001
type: escape
status: candidate
title: Equivalence with a sibling path judged by its auth rule, not by the data it returns
agents: [devflow-review]
stack: [any]
class: standard-design
layer: reviewer:security-safety
target: devflow-review/correctness-guide.md
key: escape:standard-design:reviewer-security-safety:sibling-path-data-not-auth
seen:
  - p-00000000 2026-10-21
promoted_ref: —
created: 2026-10-21
updated: 2026-10-21
---

**Rule:** When a finding about exposing sensitive data is excused because another path has the same policy, compare the fields that path returns; if the user did not accept the risk, ask instead of classifying INFO.
