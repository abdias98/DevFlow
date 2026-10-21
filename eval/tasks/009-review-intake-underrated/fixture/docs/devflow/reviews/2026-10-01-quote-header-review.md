# Review — quote-header

## Summary
Quote header endpoint for draft orders.

## Findings

### 🔴 BLOCK (must fix)
(none)

### 🟡 WARN (should fix)
(none)

### 🟢 INFO (optional)
| # | File | Line | Finding | Evidence | Note |
|---|------|------|---------|----------|------|
| I1 | `src/quotes.js` | 13 | Any seller can read the customer's tax id and address of any draft order | security.md §2. **Deliberate decision** (spec S4: same policy as `GET /orders/{id}`) | — |

## Coverage
| Dimension | Ran | Notes |
|---|---|---|
| 1 — Security & Safety | ✅ | |
| 4 — Correctness & Behavior | ✅ | |

## Verdict
APPROVED
