# Reference Template: Mobile App

> **This is a reference guide, not a rigid spec.** Adapt to the actual framework (React Native, Flutter, SwiftUI, Jetpack Compose) and platform conventions. Priority: AGENTS.md → project template → exploration → this reference.

## Typical Structure (React Native / Flutter)

```
src/
├── screens/          # Full-screen views, one per route
├── components/       # Reusable UI components (buttons, cards, inputs)
├── navigation/       # Stack, tab, drawer navigator configuration
├── services/         # API client, local storage, push notifications, analytics
├── stores/           # State management (Context, Redux, Provider, BLoC)
├── hooks/            # Custom hooks / composables (platform-specific logic)
├── utils/            # Formatters, validators, helpers
├── theme/            # Design tokens: colors, typography, spacing, dark mode
├── assets/           # Images, fonts, icons, animations
└── types/            # TypeScript/type definitions

__tests__/
├── screens/
├── components/
├── services/
└── integration/
```

## Architecture Patterns

| Pattern | When to use |
|---------|-------------|
| **MVVM / MVI** | Unidirectional data flow. View observes ViewModel/State, actions flow up. |
| **Repository pattern** | Abstract data sources (API, local DB). Single source of truth. |
| **Offline-first** | Local DB as primary. Sync with server when online. |
| **Navigation state** | Centralized router. Deep linking support. |
| **Platform-specific code** | `.ios.js` / `.android.js` extensions or Platform.OS checks |
| **Lazy loading** | Load screens on demand. Reduce initial bundle size. |

## State Management

| Type | Where | Example |
|------|-------|---------|
| **Server state** | React Query / SWR / Riverpod | User profile, feed items |
| **UI state** | Local component state | Form inputs, modal visibility |
| **App state** | Global store | Auth user, theme, onboarding status |
| **Cache** | AsyncStorage / SQLite | Persisted data for offline use |

## Common Patterns

| Pattern | Description |
|---------|-------------|
| **Pull-to-refresh** | Swipe down to reload. Standard mobile UX. |
| **Infinite scroll** | Load more items as user scrolls down. Pagination cursor. |
| **Skeleton loading** | Placeholder UI while data loads. Better than spinner. |
| **Error retry** | Show error message + retry button. Don't leave user stuck. |
| **Keyboard avoidance** | Auto-scroll when keyboard appears. Never hidden behind keyboard. |
| **Safe area** | Respect notch, home indicator, status bar. Use SafeAreaView. |
| **Haptic feedback** | Subtle vibration on important actions (delete, confirm) |
| **Push notifications** | Register device token. Handle foreground/background/terminated states. |

## Common Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Blocking the UI thread | All I/O and heavy computation must be async or in isolate/worker |
| Hardcoded strings | Use i18n library with locale support |
| No loading states | Always show loading/error/empty states |
| Platform-specific in shared code | Abstract behind platform adapter |
| Memory leaks (unmounted state updates) | Cleanup subscriptions, cancel async ops in useEffect/initState cleanup |
| Giant initial bundle | Code splitting, lazy loading, optimize images |

## Test Architecture

| What | How |
|------|-----|
| Components | Render test: given props → renders correct UI. Interaction test. |
| Hooks / BLoC | Unit test: call → verify state changes and side effects |
| Services | Unit test: mock API → verify correct requests |
| Screens | Integration: render with mocked services → verify full user flow |
| E2E | Detox / Maestro: real device/emulator flow |
