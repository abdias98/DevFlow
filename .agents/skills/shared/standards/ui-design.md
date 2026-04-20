# DevFlow Engineering Standards: UI Design

> **Apply only if:** the project has a user interface (web frontend, mobile app, desktop app, or server-rendered views).
> If this is a pure API, CLI tool, library, or background worker, skip this standard entirely.

Apply these principles when designing, planning, implementing, or reviewing UI code.

## 1. For Existing Projects — Detect, Evaluate, and Act

Before proposing any UI design, explore the codebase to identify the design system and component conventions in use. Then evaluate:

| Situation | Action |
|-----------|--------|
| UI has a **consistent design system** (component library, design tokens, spacing scale) | **DO:** Follow and extend it. Match naming, structure, and visual conventions. |
| UI uses a **framework with established conventions** (MUI, Tailwind, Bootstrap, Jetpack Compose, SwiftUI) | **DO:** Follow the framework's patterns — don't invent custom alternatives. |
| UI is **inconsistent** (mixed styles, no design tokens, duplicated components) | **DO:** Flag it in the Spec as a finding. Propose a consolidation strategy. **DON'T** refactor existing components unilaterally. |

## 2. For New Projects — Select the Right Approach

Apply the following **reasoning principles** based on the detected UI stack and `Feature Type` in session memory. This list is **non-exhaustive** — use your knowledge of the detected stack to apply the correct approach for any framework or platform.

### Reasoning Principles

| Principle | Apply when... |
|-----------|---------------|
| **Follow the platform's design guidelines** | The project targets a native platform (Android, iOS, Windows, macOS) — use its official design language |
| **Component-Driven + Design Tokens** | The project is a web frontend — every visual unit is a reusable component; spacing, color, and typography come from tokens |
| **Progressive Enhancement** | The project is server-rendered — HTML is the baseline; JS and CSS are enhancements, not requirements |
| **Shared tokens + platform-aware components** | The project is cross-platform — share design decisions (tokens) but adapt component implementation per platform |
| **Reactive UI state separation** | The project has complex or async UI state — separate the state from the view (MVVM, Store, Signals) |

### Reference Examples *(illustrative, not exhaustive)*

| Detected Stack | Common Approach |
|---------------|-----------------|
| React / Vue / Svelte / Angular (SPA) | Component-Driven + Design Tokens + CSS custom properties |
| Next.js / Nuxt / Astro (SSR) | Component-Driven + Progressive Enhancement |
| React Native / Expo / Flutter | Shared design tokens + platform-aware components |
| Android (Jetpack Compose / XML + Java/Kotlin) | Material Design 3 guidelines + ViewModel state |
| iOS (SwiftUI / UIKit) | Human Interface Guidelines + ObservableObject / UIViewController |
| Windows (WinUI / MAUI) | Fluent Design System guidelines |
| Server-rendered (Rails, Django, Blade, Twig) | Semantic HTML + Progressive Enhancement |

> If the detected stack is not listed above, apply the **Reasoning Principles** table above using your knowledge of that platform's conventions and official design guidelines.

- **DO:** Justify the chosen approach in the Architecture Spec.
- **DON'T:** Apply a component library or design system without first checking if one is already present in the project.

## 3. Universal UI Design Rules

### Accessibility
- **DO:** Ensure all interactive elements are keyboard-navigable and have ARIA labels where needed.
- **DON'T:** Use `div` or `span` as buttons — use semantic HTML (`<button>`, `<a>`, `<input>`).
- **DO:** Maintain a minimum contrast ratio of 4.5:1 for text (WCAG AA).

### Component Design
- **DO:** Design components to be self-contained, reusable, and composable. Each component has one visual responsibility.
- **DON'T:** Create components that reach outside their scope to modify global state or DOM nodes.
- **DO:** Separate presentational components (how it looks) from container components (what data it shows).

### Responsive Design
- **DO:** Design mobile-first. Apply breakpoints as progressive enhancements.
- **DON'T:** Use fixed pixel widths for layout containers — prefer `%`, `rem`, `fr`, or `clamp()`.

### Design Tokens & Consistency
- **DO:** Use design tokens (variables) for colors, spacing, typography, and border-radius. Never hardcode visual values.
- **DON'T:** Use magic numbers (`margin: 13px`) — every spacing value should come from the scale.

### Performance
- **DO:** Lazy-load non-critical UI (images, heavy components, routes).
- **DON'T:** Block the initial render with large CSS bundles or synchronous JS that is not needed above the fold.
