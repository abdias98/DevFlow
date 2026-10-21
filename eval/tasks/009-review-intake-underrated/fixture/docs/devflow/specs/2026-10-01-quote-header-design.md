# Quote header — Design

## Design Decisions
- **S4 — Who may read the header:** any seller may read the header of any draft order — the same policy as `GET /orders/{id}`.

## API Contract
#### GET /orders/{id}/quote-header
- 200 — the header
- 404 — the order does not exist or was deleted
