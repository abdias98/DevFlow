# DevFlow Engineering Standards: REST API Design (Technology-Agnostic)

> **Apply only if:** the project has HTTP endpoints, REST controllers, or API contracts.
> If this is a CLI, library, background worker, or frontend-only project, skip this standard entirely.
>
> **Note on examples:** All field names, URL patterns, and tool references are illustrative. Adapt conventions (naming, date formats, versioning strategy) to the detected stack and team agreements.

Apply these principles to all API endpoints you design, generate, or review.

## 1. Resource Naming
- **What:** URIs identify resources, not actions.
- **DO:**
  - Use plural nouns for resource URIs: `GET /users`, `POST /orders/{id}/items`.
  - Represent relationships with nested resource paths when the relationship is strong: `GET /users/{id}/orders`.
  - Use query parameters for filtering, sorting, and pagination, not for identifying resources.
- **DON'T:**
  - Use verbs in URIs: `GET /getUsers`, `POST /createOrder`, `DELETE /removeItem`.
  - Create deeply nested paths (more than 2–3 levels). Prefer independent resource endpoints and linking instead.
  - Embed actions into resource names (e.g., `/activateUser`). Use sub‑resources with the correct HTTP method: `PATCH /users/{id}/status`.

## 2. HTTP Methods & Semantics
- **What:** Each HTTP verb carries a defined semantic contract.
- **DO:**
  - Use the correct verb:
    - `GET` — read, idempotent, safe, cacheable.
    - `POST` — create a new resource under the collection.
    - `PUT` — full replacement of a resource at a known URI (idempotent).
    - `PATCH` — partial update (not necessarily idempotent, but can be).
    - `DELETE` — remove a resource (idempotent).
  - Return the created resource or its URI in the `Location` header for `201 Created` responses.
  - Support conditional requests with `If-Match`/`If-None-Match` and `ETag` headers for optimistic concurrency control.
- **DON'T:**
  - Use `POST` for all operations, or `GET` for state‑changing actions (side effects on `GET` break caching, idempotency, and safety guarantees).
  - Expose unsafe operations via `GET` — search with side effects, logout endpoints that mutate server state, etc.

## 3. HTTP Status Codes
- **What:** Status codes are the API's contract with the client — use them precisely.
- **DO:**
  - Use the most specific status code available:
    - `200 OK` — successful GET, PUT, PATCH.
    - `201 Created` — successful POST with a new resource.
    - `204 No Content` — successful DELETE or a PUT/PATCH that returns no body.
    - `301/308` — permanent redirect (resource moved).
    - `400 Bad Request` — malformed syntax, missing required fields.
    - `401 Unauthorized` — missing or invalid authentication.
    - `403 Forbidden` — authenticated but not allowed.
    - `404 Not Found` — resource or collection does not exist.
    - `409 Conflict` — resource state conflict (e.g., version mismatch).
    - `422 Unprocessable Entity` — semantic validation failure.
    - `429 Too Many Requests` — rate limiting.
    - `500 Internal Server Error` — unexpected server failure.
    - `503 Service Unavailable` — temporary maintenance/overload.
- **DON'T:**
  - Return `200 OK` with an error body (clients parse the status, not the body, to determine success).
  - Use `400` or `500` as generic catch-alls when a more specific code applies.
  - Leak internal details in status messages — the code is enough; pair it with a user‑friendly error body (see Principle 7).

## 4. Response Structure
- **What:** Consistent response shapes reduce client-side complexity.
- **DO:**
  - Use a consistent envelope for all responses. A widely adopted pattern: `{ "data": ..., "meta": ..., "errors": [...] }`.
    - `data`: the payload (object for single resource, array for collections).
    - `meta`: pagination info, total count, links.
    - `errors`: structured error objects when not successful (see Principle 7).
  - Use a standard date/time format (e.g., ISO 8601) across the entire API.
  - Return the full resource representation on `POST` and `PUT/PATCH` (unless the client specifies a preference for a minimal response via headers).
- **DON'T:**
  - Return different shapes for the same resource across endpoints (e.g., `GET /users/{id}` returns `{ user: ... }` but `GET /users` returns an array with no wrapper).
  - Mix naming conventions within the same API — agree on camelCase, snake_case, or kebab-case and apply it everywhere.
  - Wrap error responses in a different top-level structure than success responses — the client should know where to look for `errors` regardless of status code.

## 5. Versioning
- **What:** APIs are public contracts — breaking changes require a new version.
- **DO:**
  - Version APIs from the first release. Prefer URI path versioning (`/v1/users`) for simplicity and discoverability, or use a header/query parameter if the team has a strong reason.
  - Maintain backward compatibility within a major version. New fields, optional parameters, and new endpoints are safe; renaming or removing fields, changing types, or altering semantics are breaking.
  - Deprecate old versions gracefully: announce sunset dates, monitor usage, and remove versions only after clients have migrated.
- **DON'T:**
  - Make breaking changes to an existing version without incrementing the version identifier.
  - Release a public API without a versioning strategy — even a single internal consumer will evolve.

## 6. Pagination, Filtering & Sorting
- **What:** Unbounded collections are a performance and usability risk.
- **DO:**
  - Paginate all collection endpoints. Use a consistent pagination mechanism (cursor‑based for real‑time data, offset‑based for simple use cases). Include `meta.total` or a `Link` header for next/previous pages.
  - Support filtering via query parameters: `GET /users?status=active&role=admin`.
  - Support sorting via query parameters with ascending/descending control: `GET /users?sort=+createdAt,-lastName`.
  - Validate filter and sort fields against the allowed set — reject unknown fields with a `400` error.
- **DON'T:**
  - Return unbounded lists or implement pagination differently across endpoints.
  - Expose database column names directly in query parameters — use API-facing field names.

## 7. Error Response Format
- **What:** Structured errors enable clients to handle failures programmatically.
- **DO:**
  - Return a consistent, structured error object: `{ "code": "VALIDATION_ERROR", "message": "A human‑readable summary.", "details": [{ "field": "email", "issue": "required" }] }`.
  - Use specific error codes that clients can switch on (e.g., `INVALID_INPUT`, `RESOURCE_NOT_FOUND`, `UNAUTHORIZED`, `RATE_LIMITED`).
  - Include a `documentation_url` or `help` link when the error requires further explanation.
- **DON'T:**
  - Return plain strings, HTML error pages, or unstructured objects.
  - Expose internal exception types or stack traces in error fields.

## 8. Security & Safety
- **What:** APIs are the front door to your system — they must be secured by default.
- **DO:**
  - Require TLS (HTTPS) for all endpoints. Redirect HTTP to HTTPS.
  - Authenticate every endpoint unless it is explicitly public. Use standard authorization headers (e.g., Bearer token).
  - Apply rate limiting, especially on auth, password reset, and token‑generation endpoints.
  - Set appropriate CORS policies — never use wildcard origins for credentialed requests.
  - Validate `Content-Type` headers and reject requests with unsupported media types (`415 Unsupported Media Type`).
- **DON'T:**
  - Expose sensitive data in URL paths (they appear in logs and browser history). Use headers or the request body instead.
  - Trust any input from the client — validate everything at the boundary (see `security.md` § 1).

## 9. Idempotency & Safe Operations
- **What:** Clients must be able to retry requests without causing duplicate side effects.
- **DO:**
  - Design `PUT`, `DELETE`, and `GET` to be idempotent by default.
  - For `POST` and `PATCH` endpoints that are not naturally idempotent, support an `Idempotency-Key` header. Store the key and the response for a configured time window; return the stored response on duplicate keys.
- **DON'T:**
  - Create a new resource on every retry of the same `POST` if the client did not receive the first response — idempotency keys prevent unintended duplicates.

## 10. Documentation
- **What:** An undocumented API does not exist.
- **DO:**
  - Provide an API specification using a standard format (e.g., OpenAPI). Keep it in sync with the implementation.
  - Include request/response examples for all endpoints.
  - Document authentication requirements, rate limits, and error codes.
- **DON'T:**
  - Let the specification drift from the actual implementation. Use tooling to generate the spec from code or validate the implementation against the spec.

## 11. REST API Interactions & Trade‑offs
- **Status Codes + Error Response:** A specific status code combined with a structured error body gives clients both the protocol-level signal (status) and the actionable detail (error code/field).
- **Pagination + Performance:** Pagination prevents accidental unbounded queries. Coupled with `meta.total`, clients can display progress without fetching the entire dataset.
- **Versioning + Backward Compatibility:** Versioning allows safe evolution, but maintaining multiple versions has a cost. Only version when breaking changes are unavoidable; prefer extending the API compatibly.
- **Idempotency + Reliability:** Idempotency keys and idempotent verbs make the API safer in distributed systems where network failures are common.

## 12. Code Review Checklist
When reviewing an API, verify:
- [ ] Resource URIs use nouns; no verbs or actions in paths.
- [ ] HTTP methods match the operation semantics (GET/read, POST/create, PUT/replace, PATCH/partial, DELETE/remove).
- [ ] Status codes are specific and accurate; no `200 OK` with error bodies.
- [ ] Response structure is consistent across endpoints (envelope, data shape, date format).
- [ ] Versioning is present and backward compatible within a version.
- [ ] All collection endpoints are paginated and support filtering/sorting.
- [ ] Errors are structured with a code, message, and optionally per‑field details.
- [ ] Authentication is enforced on non‑public endpoints; rate limiting is applied on sensitive operations.
- [ ] `Idempotency-Key` is supported on non‑idempotent `POST`/`PATCH` endpoints.
- [ ] API specification (e.g., OpenAPI) is present and up to date.

## 13. Applying This Standard with a Limited Scope

When applying REST API design rules to a **specific set of files or modules** (the declared scope), follow these constraints:

1. **Only modify files inside the scope.**
   - If an API endpoint outside the scope violates a rule, flag it as an INFO note in the in‑scope file and recommend the fix. Do not touch external controllers or routes.
2. **Response structure changes.**
   - Normalizing a response envelope is allowed if both the controller and the serialization logic are in scope. If the envelope is defined by a global middleware or serializer outside the scope, leave a TODO comment and suggest the central change.
3. **Versioning additions.**
   - If a new endpoint is being added within scope, apply the existing versioning strategy. Do not introduce a new version prefix or modify the routing configuration if those live outside the scope.
4. **Pagination and filtering.**
   - Paginating an unbounded collection within an in‑scope endpoint is always allowed. Do not introduce new shared pagination libraries or modify base controller classes outside the scope.
5. **Security headers and rate limiting.**
   - Applying rate limiting or CORS headers usually requires middleware configuration outside the scope. Recommend those changes as INFO notes rather than modifying global configuration files.
6. **Scope‑safe improvements are always allowed:**
   - Correcting HTTP methods and status codes in a controller.
   - Adjusting resource URIs (if the routing table is in the same file).
   - Returning structured error objects instead of plain strings.
   - Adding an `Idempotency-Key` check within the in‑scope service method.