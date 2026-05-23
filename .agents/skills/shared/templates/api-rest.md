# Reference Template: API REST

> **This is a reference guide, not a rigid spec.** The Architect adapts these patterns to the actual project's conventions, ORM, framework, and existing code. Priority order: AGENTS.md → project template → exploration → this reference.

## Typical Layer Structure

```
src/
├── controllers/     # HTTP handlers: parse request, call service, format response
├── services/        # Business logic, orchestration, use cases
├── repositories/    # Data access, queries (always behind interfaces in inner layers)
├── models/          # Domain entities, value objects, enums
├── middleware/       # Cross-cutting: auth, logging, rate limiting, CORS, error handling
├── routes/          # Route registration, path → controller mapping
├── validators/      # Request schema validation (DTOs, schemas)
├── errors/          # Custom error hierarchy, HTTP-to-domain error mapping
└── config/          # Environment, DB connection, external service URLs
```

## Data Flow

```
Request → Middleware Pipeline → Controller → Validator → Service → Repository → DB
                                                    ↓ (error)
                                          Error Handler → Response
```

## Common Patterns

| Pattern | When to use | Key files |
|---------|-------------|-----------|
| **JWT Auth** | Stateless API, mobile/SPA clients | `middleware/auth.js`, `services/auth.service.js` |
| **Session Auth** | Server-rendered apps, existing session infra | `middleware/session.js` |
| **Offset Pagination** | Relational DBs, simple UX | `?page=1&limit=20`, response includes `meta: {total, page, limit}` |
| **Cursor Pagination** | Real-time feeds, large datasets | `?cursor=abc&limit=20`, opaque cursor, stable ordering |
| **Validation Middleware** | Every request boundary | Schema-based (Zod, Joi, class-validator) before service layer |
| **Error Handler** | Global catch-all | Catches all thrown errors, maps to HTTP status + consistent JSON body |
| **Rate Limiting** | Public endpoints, auth endpoints | Per-IP or per-user, configurable per route |

## Common Anti-Patterns

| Anti-Pattern | Why it's a problem | Fix |
|-------------|-------------------|-----|
| Business logic in controllers | Makes logic untestable without HTTP | Extract to services |
| Raw SQL in services | Bypasses ORM, SQL injection risk | Use repositories with parameterized queries |
| Returning 200 for errors | Confuses clients, hides failures | Use correct status codes (400, 401, 403, 404, 409, 422, 500) |
| No input validation | Security risk, data corruption | Validate at every input boundary |
| Catching all exceptions silently | Hides bugs, makes debugging impossible | Log and re-throw or map to domain errors |

## Test Architecture

| Layer | Test Type | What to mock |
|-------|-----------|-------------|
| Controllers | Integration / E2E | Nothing (real HTTP) or external services only |
| Services | Unit | Repositories, external APIs |
| Repositories | Integration | Nothing (test DB) |
| Middleware | Unit | Request/Response objects |
| Validators | Unit | Nothing (pure functions) |
