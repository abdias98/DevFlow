# Escape Analysis

Defects found after a DevFlow cycle reported APPROVED (shared/escape-analysis.md).

| ID | Class | Layer | Ref | Note | Cycle | Date |
|----|-------|-------|-----|------|-------|------|
| E1 | standard-design | reviewer:security-safety | PR#42#1 | Underrated: tax id exposure excused as deliberate on a false premise (sibling endpoint does not return it) | quote-header | 2026-10-21T10:00:00Z |
| E2 | caller-contract | reviewer:correctness-behavior | PR#42#2 | Missing company answers the order's 404, against the documented contract | quote-header | 2026-10-21T10:00:00Z |
| E3 | standard-design | reviewer:correctness-behavior | PR#42#3 | Happy-path test does not assert createdAt | quote-header | 2026-10-21T10:00:00Z |
