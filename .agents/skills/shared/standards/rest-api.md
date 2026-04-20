# DevFlow Engineering Standards: REST API Design

> **Apply only if:** the project has HTTP endpoints, REST controllers, or API contracts.
> If this is a CLI, library, background worker, or frontend-only project, skip this standard entirely.

Apply these principles to all API endpoints you design, generate, or review.

## 1. Resource Naming
- **What:** URIs identify resources, not actions.
- **DO:** Use plural nouns for resource URIs: `GET /users`, `POST /orders/{id}/items`.
- **DON'T:** Use verbs in URIs: ~~`GET /getUsers`~~, ~~`POST /createOrder`~~, ~~`DELETE /removeItem`~~.

## 2. HTTP Methods & Semantics
- **What:** Each HTTP verb carries a defined semantic contract.
- **DO:** Use the correct verb: GET (read, idempotent), POST (create), PUT (full replace), PATCH (partial update), DELETE (remove).
- **DON'T:** Use POST for all operations or GET for state-changing actions (side effects on GET break caching and idempotency).

## 3. HTTP Status Codes
- **What:** Status codes are the API's contract with the client — use them precisely.
- **DO:** Return precise codes: 200 (OK), 201 (Created), 204 (No Content), 400 (Bad Request), 401 (Unauthorized), 403 (Forbidden), 404 (Not Found), 409 (Conflict), 422 (Unprocessable Entity), 500 (Server Error).
- **DON'T:** Return 200 with an error body, or use 400/500 as generic catch-alls.

## 4. Response Structure
- **What:** Consistent response shapes reduce client-side complexity.
- **DO:** Use a consistent envelope: `{ "data": ..., "meta": { "total": ... }, "errors": [...] }`. Use ISO 8601 for all dates.
- **DON'T:** Return different shapes for the same resource across endpoints, or mix camelCase and snake_case in the same API.

## 5. Versioning
- **What:** APIs are public contracts — breaking changes require a new version.
- **DO:** Version APIs from the start using URI versioning: `/v1/users`. Maintain backwards compatibility within a version.
- **DON'T:** Make breaking changes to an existing version or release a public API without a version prefix.

## 6. Pagination & Filtering
- **What:** Unbounded collections are a performance and usability risk.
- **DO:** Paginate all collection endpoints. Support filtering and sorting via query params: `?status=active&sort=createdAt&page=2&limit=20`.
- **DON'T:** Return unbounded lists or implement pagination inconsistently across endpoints.

## 7. Error Response Format
- **What:** Structured errors enable clients to handle failures programmatically.
- **DO:** Return structured error bodies: `{ "code": "VALIDATION_ERROR", "message": "Email is required", "fields": [{ "field": "email", "error": "required" }] }`.
- **DON'T:** Return plain strings, HTML error pages, or unstructured error objects.
