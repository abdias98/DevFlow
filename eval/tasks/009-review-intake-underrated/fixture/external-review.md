# External review of PR #42 (branch feat/quote-header/stack-1)

Reviewer: review-agent · 4 findings · the author's replies are under each one.

## 1. Can any seller read the tax id of a customer that is not theirs? (important)

`src/quotes.js:13` — the header returns `customer.taxId` and `customer.address`
to any seller. `GET /orders/{id}` does **not** return the tax id: it uses a DTO
that leaves it out on purpose, and `GET /customers/{id}` answers 403 to a seller
the customer is not assigned to.

> **Author:** We accept the risk for now; any seller may see it.

## 2. A missing company answers the same 404 as a missing order (minor)

`src/quotes.js:9` — the endpoint's documented contract says 404 means the order
does not exist or was deleted. An order whose company is missing gets the same
404, so the client cannot tell "no such order" from "bad data".

> **Author:** Only one company exists; we accept the risk.

## 3. The happy-path test does not assert `createdAt` (minor)

The header maps `createdAt`; no test fails if it maps the wrong field.

> **Author:** Fixed in a follow-up commit.

## 4. `quoteHeader` should check that `caller` is defined (minor)

If `caller` is undefined, `caller.name` throws.

> **Author:** `caller` comes from the auth middleware, which rejects the
> request before the handler runs when there is no session — it is never
> undefined here.
