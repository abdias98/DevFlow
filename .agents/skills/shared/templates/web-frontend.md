# Reference Template: Web Frontend

> **This is a reference guide, not a rigid spec.** Adapt to the actual framework (React, Vue, Svelte, Angular), state management, and component library. Priority: AGENTS.md → project template → exploration → this reference.

## Typical Structure

```
src/
├── components/      # Reusable UI components (atoms, molecules, organisms)
├── pages/           # Route-level page components
├── hooks/           # Custom hooks / composables (shared logic)
├── services/        # API client, data fetching, external integrations
├── stores/          # State management (Context, Redux, Pinia, Zustand)
├── utils/           # Pure utility functions, formatters, validators
├── styles/          # Global styles, design tokens, theme
├── types/           # TypeScript types, interfaces (if typed)
└── assets/          # Static files: images, fonts, icons
```

## Architecture Patterns

| Pattern | When to use |
|---------|-------------|
| **Component Composition** | Break UI into small, reusable pieces. Pass data down, events up. |
| **Custom Hooks / Composables** | Extract reusable logic from components (data fetching, form handling) |
| **API Service Layer** | Centralize all HTTP calls. Never call fetch/axios directly in components. |
| **Design Tokens** | Colors, spacing, typography as constants. Avoid hardcoded values. |
| **Lazy Loading** | Route-based code splitting. Load heavy components on demand. |
| **Error Boundaries** | Catch render errors gracefully. Show fallback UI, don't crash the app. |
| **Optimistic Updates** | Update UI immediately, rollback on error. Better UX for mutations. |

## State Categories

| Type | Where | Example |
|------|-------|---------|
| **Server state** | Cache layer (React Query, SWR, Apollo) | User list from API |
| **UI state** | Local component state | Modal open/close, form values |
| **Global state** | Store (Context, Redux, Pinia) | Auth user, theme preference |
| **URL state** | Router params, query string | Search filters, pagination |

## Common Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Fetching in every component | Centralize API calls in services/ |
| Prop drilling > 3 levels | Use context or composition |
| Mixing business logic in JSX | Extract to hooks/services |
| Not handling loading/error states | Always show loading skeleton + error fallback |
| useEffect for data fetching | Use data-fetching library (React Query, SWR) |

## Test Architecture

| What | How |
|------|-----|
| Components | Render test: given props → renders correct output. User interactions. |
| Hooks | Unit test: call hook → verify return values and side effects |
| Services | Unit test: mock fetch → verify correct URL, method, body |
| Pages | Integration: render page with mocked services → verify full flow |
| E2E | Browser test (Playwright, Cypress): real user flows |
