# Reference Template: Fullstack

> **This is a reference guide, not a rigid spec.** Combines API REST + Web Frontend patterns. The Architect applies the relevant backend and frontend templates to their respective packages. In monorepos, each package gets its own profile under `## Stack Profiles`.

## Monorepo Structure (recommended)

```
project/
├── packages/
│   ├── frontend/       # Web Frontend (see web-frontend.md template)
│   │   └── src/        # Components, pages, hooks, services, stores, utils
│   ├── api/            # API REST backend (see api-rest.md template)
│   │   └── src/        # Controllers, services, repositories, models, middleware
│   └── shared/         # Shared types, DTOs, validation schemas, constants
├── package.json        # Workspace root (pnpm workspaces, turborepo, nx)
└── turbo.json          # Build pipeline
```

## Cross-Cutting Concerns

| Concern | Handling |
|---------|----------|
| **Type sharing** | `packages/shared/` for DTOs, validation schemas, enums used by both |
| **API contract** | Define in spec. Both frontend and backend implement against it. Generated types. |
| **Environment vars** | `packages/api/.env` and `packages/frontend/.env`. Never commit secrets. |
| **Testing** | Backend: unit + integration + contract. Frontend: component + integration + E2E. |
| **CI/CD** | Monorepo-aware: only build/test affected packages. Use turborepo/nx affected. |

## Fullstack Data Flow

```
Browser → Frontend (React/Vue/Svelte)
              │ HTTP (fetch/axios)
              ▼
          API Gateway / Backend
              │ Controller → Service → Repository → DB
              ▼
          Response (JSON)
              │
              ▼
          Frontend Store → Component → UI
```

## Common Fullstack Patterns

| Pattern | Description |
|---------|-------------|
| **BFF (Backend For Frontend)** | Dedicated API layer that aggregates data for specific UI needs |
| **SSR / Server Components** | Render initial HTML on server. Hydrate on client. |
| **API Type Generation** | Generate TypeScript types from OpenAPI/Swagger. Single source of truth. |
| **Optimistic UI** | Frontend updates immediately, backend validates, rollback on conflict |
| **WebSocket / SSE** | Real-time features: chat, notifications, live updates |
