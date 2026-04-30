# DevFlow Engineering Standards: UI Design (Technology-Agnostic)

> **Apply only if:** the project has a user interface (web frontend, mobile app, desktop app, or server-rendered views).
> If this is a pure API, CLI tool, library, or background worker, skip this standard entirely.
>
> **Note on examples:** All framework names, library references, and code snippets are illustrative. Replace them with the actual tools, design systems, and conventions of the detected stack.

Apply these principles when designing, planning, implementing, or reviewing UI code.

## 1. For Existing Projects — Detect, Evaluate, and Act

Before proposing any UI design, explore the codebase to identify the design system and component conventions in use. Then evaluate:

| Situation | Action |
|-----------|--------|
| UI has a **consistent design system** (component library, design tokens, spacing scale) | **DO:** Follow and extend it. Match naming, structure, and visual conventions. |
| UI uses a **framework with established conventions** (any platform or library) | **DO:** Follow the framework's patterns — don't invent custom alternatives unless the framework explicitly recommends them. |
| UI is **inconsistent** (mixed styles, no design tokens, duplicated components) | **DO:** Flag it in the Spec as a finding. Propose a consolidation strategy. **DON'T** refactor existing components unilaterally. |

## 2. For New Projects — Select the Right Approach

Apply the following **reasoning principles** based on the detected UI stack and `Feature Type` in session memory. This list is **non-exhaustive** — use your knowledge of the detected stack to apply the correct approach for any framework or platform.

### Reasoning Principles

| Principle | Apply when... |
|-----------|---------------|
| **Follow the platform's design guidelines** | The project targets a native platform (mobile, desktop) — use its official design language and components |
| **Component-Driven + Design Tokens** | The project is a UI with reusable visual units — each component is self-contained; spacing, color, and typography come from tokens |
| **Progressive Enhancement** | The project is server-rendered or targets multiple device capabilities — the baseline is semantic structure; enhancements are layered on top |
| **Shared tokens + platform-aware components** | The project is cross-platform — share design decisions (tokens) but adapt component implementation per platform |
| **Reactive UI state separation** | The project has complex or async UI state — separate state management from the view layer |

### Reference Examples *(illustrative, not exhaustive)*

| Feature Type | Common Approach |
|--------------|-----------------|
| Web SPA | Component-Driven + Design Tokens |
| Server-Rendered Web App | Component-Driven + Progressive Enhancement |
| Cross-Platform Mobile/Desktop | Shared design tokens + platform-aware components |
| Native Mobile App | Official platform guidelines + reactive state separation |
| Native Desktop App | Official platform guidelines + component-driven architecture |

> If the detected project type is not listed above, apply the **Reasoning Principles** table to determine the best fit using your knowledge of the platform's conventions.

- **DO:** Justify the chosen approach in the Architecture Spec.
- **DON'T:** Apply a component library or design system without first checking if one is already present in the project.

## 3. Universal UI Design Rules

### Accessibility
- **DO:** Ensure all interactive elements are keyboard-navigable and have appropriate accessibility labels (ARIA where applicable). Respect user preferences for reduced motion and high contrast.
- **DON'T:** Use generic containers (`div`, `span`) as interactive elements — use semantic elements (`button`, `a`, `input`) provided by the platform.
- **DO:** Maintain a minimum contrast ratio of 4.5:1 for text (WCAG AA). Provide focus indicators that are clearly visible.

### Component Design
- **DO:** Design components to be self-contained, reusable, and composable. Each component has one visual responsibility.
- **DON'T:** Create components that reach outside their scope to modify global state or arbitrary DOM nodes / view hierarchy elements.
- **DO:** Separate presentational components (how it looks) from container components (what data it shows). Prefer props/parameters over global state access.

### Responsive Design
- **DO:** Design for the smallest screen first. Apply larger breakpoints as progressive enhancements.
- **DON'T:** Use fixed pixel widths for layout containers — prefer relative units (`%`, `rem`, `fr`, `clamp()`, or platform-equivalent flexible sizing).

### Design Tokens & Consistency
- **DO:** Use design tokens (variables, constants, or platform equivalents) for colors, spacing, typography, and border-radius. Never hardcode visual values directly in components.
- **DON'T:** Use arbitrary values (`margin: 13px`, `padding: 7`) — every spacing and sizing value must come from the defined scale.

### Performance
- **DO:** Lazy-load non-critical UI (images below the fold, heavy components, secondary routes/screens).
- **DON'T:** Block the initial render/paint with large style bundles, synchronous scripts, or heavy computations that are not needed for the first meaningful paint.

## 4. UI Interactions & Trade-offs

- **Accessibility vs. Visual Design:** A visually appealing component that is not keyboard-accessible or has low contrast fails the basic usability test. Prioritize accessibility over aesthetics.
- **Component Reusability vs. Simplicity:** Overly parameterized components that try to cover every use case become hard to maintain. If a component needs too many variants, split it into focused sub-components.
- **Design Tokens vs. Flexibility:** Tokens ensure consistency but can be too rigid for edge cases. Allow exceptions through explicit escape hatches (e.g., utility classes or platform-specific overrides) but document them.
- **Progressive Enhancement vs. Feature Parity:** Server-rendered pages should work without JavaScript. Client-side interactivity is an enhancement, not a requirement for core functionality.
- **Performance vs. Interactivity:** Lazy-loading improves initial load time but can introduce layout shifts or delays. Use placeholders/skeletons and reserve space for lazy-loaded content.

## 5. Code Review Checklist
When reviewing UI code, verify:
- [ ] Interactive elements are semantic and keyboard-accessible.
- [ ] Color contrast meets WCAG AA (4.5:1 for text).
- [ ] Components are self-contained and have a single visual responsibility.
- [ ] No hardcoded visual values — all spacing, colors, and typography use design tokens.
- [ ] Layout uses relative units; no fixed pixel widths that break responsiveness.
- [ ] Non-critical UI is lazy-loaded; initial render is not blocked by heavy assets.
- [ ] New components follow the existing design system or platform conventions.

## 6. Applying This Standard with a Limited Scope

When applying UI design rules to a **specific set of files or modules** (the declared scope), follow these constraints:

1. **Only modify files inside the scope.**
   - If a UI violation is found in a component outside the scope, mention it as an INFO note in the in-scope file and describe the recommended fix.
2. **Component refactors.**
   - If a component needs to be split for SRP but the new component would live outside the scope, leave a comment in the original file recommending the split and the target location.
3. **Design token introduction.**
   - If you replace hardcoded values with design tokens, define the tokens within the scope (e.g., in a local constants file) if a global token file exists outside the scope. Leave a TODO to migrate to the global token file.
4. **Accessibility fixes.**
   - Replacing `div` with `button` or adding keyboard handlers within the same file is always allowed. Do not modify global accessibility configurations or base templates outside the scope.
5. **Performance improvements.**
   - Adding lazy-loading to an in-scope component is allowed. Do not modify build configurations, bundler settings, or global loading strategies unless they are explicitly in scope.
6. **Scope-safe improvements are always allowed:**
   - Replacing magic numbers with design tokens (within the same file or a token file in scope).
   - Adding semantic elements and ARIA labels.
   - Extracting a presentational component from a container component if both stay within scope.