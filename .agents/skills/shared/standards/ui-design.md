# DevFlow Engineering Standards: UI Design (Technology-Agnostic)

> **Version:** 2.2.0 | **Last Updated:** 2026-06-10

> **Apply only if:** the project has a user interface (web frontend, mobile app, desktop app, or server-rendered views).
> If this is a pure API, CLI tool, library, or background worker, skip this standard entirely.
>
> **Note on examples:** All framework names, library references, code snippets, and visual concepts are illustrative. Replace them with the actual tools, design systems, and conventions of the detected stack.

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

## 3. Visual Foundation — Hierarchy, Typography & Spacing

The user's eye must be guided intentionally through content. Visual hierarchy is not decoration — it is function.

### Typography

- **DO:** Define a typographic scale with at least 4-5 levels (e.g., xs, sm, base, lg, xl, 2xl, 3xl). Each level serves a clear semantic purpose (body, heading, caption, label).
- **DO:** Maintain a line-height of 1.4–1.6 for body text and 1.1–1.3 for headings. Shorter text (labels, captions) can use tighter line-height.
- **DO:** Limit line length (measure) to 45–75 characters for body text to preserve readability. Wider text increases cognitive load.
- **DO:** Use font-weight to establish hierarchy: regular (400) for body, medium (500–600) for emphasis, bold (700) for headings.
- **DON'T:** Use more than 2 font families per interface. One for headings, one for body — or a single variable font family is ideal.
- **DON'T:** Mix conflicting typefaces (e.g., two serifs, two sans-serifs with similar x-height). Choose complementary pairs.

### Spacing & Rhythm

- **DO:** Define a spacing scale based on a base unit (e.g., 4px or 8px grid). All margins, paddings, and gaps must be multiples of the base unit: 4, 8, 12, 16, 24, 32, 48, 64.
- **DO:** Use consistent vertical rhythm — adjacent sections, cards, and form groups should share the same spacing rules.
- **DON'T:** Use arbitrary spacing values — every spacing decision must come from the defined scale.
- **DON'T:** Collapse unrelated elements too close or separate related elements too far. Apply the Gestalt principle of proximity.

### Layout & Alignment

- **DO:** Align elements to a grid. Left-edge alignment is the default for left-to-right languages — centered alignment only for short, intentional content (hero text, modals).
- **DO:** Use consistent container widths. Content that spans edge-to-edge on ultra-wide screens becomes unreadable — cap content width at a reasonable maximum (e.g., ~1200px or 75ch).
- **DON'T:** Mix alignment styles arbitrarily within the same view. If cards are left-aligned, don't center-align one as an exception without strong rationale.

### Responsive Design

- **DO:** Design for the smallest screen first (mobile-first). Start with the constrained layout, then add breakpoints as progressive enhancements for larger viewports.
- **DO:** Use relative units for layout: percentages (`%`), `rem`, `fr`, `clamp()`, or platform-equivalent flexible sizing. Avoid fixed pixel widths on layout containers.
- **DO:** Test layouts at common breakpoints: 320px (small phone), 375px (phone), 768px (tablet), 1024px (small desktop), 1440px (large desktop) — or platform-native size classes.
- **DON'T:** Hide critical content or functionality on smaller screens. Reflow and restructure, but never remove essential features for mobile users.
- **DON'T:** Assume touch and mouse are mutually exclusive. Tablets and 2-in-1 devices support both — design hybrid interactions.

## 4. Color System

Color communicates state, guides attention, and reinforces brand — not just decoration.

### Palette Structure

- **DO:** Define a structured palette with clearly named roles:
  - **Primary:** Main brand color for key actions and emphasis.
  - **Secondary:** Complementary color for less prominent UI elements.
  - **Accent:** Optional, for highlights or decorative elements.
  - **Neutral scale:** A grayscale from 50 (near-white) to 950 (near-black) for text, backgrounds, borders, and surfaces.
  - **Semantic colors:** Success (green), Warning (amber/orange), Danger (red), Info (blue). Each must have a light variant for backgrounds and a dark variant for text/icons.
- **DO:** Ensure all text/background color combinations meet **WCAG AA contrast ratio of 4.5:1** for normal text and **3:1** for large text (≥18pt / ~24 CSS px regular, or ≥14pt / ~18.66 CSS px bold).
- **DO:** Design for dark mode from the start. Invert the neutral scale: light backgrounds become dark surfaces; dark text becomes light text. Semantic colors should be desaturated in dark mode to reduce eye strain.
- **DON'T:** Use pure black (`#000`) or pure white (`#fff`) as main surface colors — they cause eye strain. Use near-black (`#111`, `#1a1a1a`) and near-white (`#fafafa`, `#f5f5f5`).
- **DON'T:** Convey information through color alone. Always pair color with an icon, label, or pattern for accessibility (color-blind users).
- **DON'T:** Introduce new colors outside the defined palette. If a new semantic meaning arises, extend the palette explicitly — never inline.

## 5. Component Design

- **DO:** Design components to be self-contained, reusable, and composable. Each component has one visual responsibility.
- **DO:** Separate presentational components (how it looks) from container components (what data it shows). Prefer props/parameters over global state access.
- **DO:** Use a consistent component API pattern: required props first, optional props with sensible defaults, variant props via enumerated values (not arbitrary strings).
- **DON'T:** Create components that reach outside their scope to modify global state or arbitrary DOM nodes / view hierarchy elements.
- **DON'T:** Over-parameterize components. If a component needs more than 3-4 boolean flags to configure its appearance, split it into focused sub-components or use a `variant` prop with a limited set of values.
- **DON'T:** Use generic containers (`div`, `span`) as interactive elements — use semantic elements (`button`, `a`, `input`) provided by the platform (also see § 10).

## 6. Interaction States

Every interactive element must communicate its state clearly. An element without designed states feels broken.

| State | Requirement |
|-------|-------------|
| **Default (rest)** | The normal appearance. Must be visually distinct from non-interactive content. |
| **Hover** | Desktop-only feedback that the element is interactive. Subtle change: lighten/darken background, underline text, slight scale (1.02–1.05). |
| **Focus-visible (or platform equivalent)** | Keyboard focus indicator. Must be a high-contrast outline or ring (≥2px). Never remove focus styles without providing an alternative. |
| **Active / Pressed** | The moment of interaction. Darken background, slight scale-down (0.98), or inset shadow. |
| **Disabled** | Grayed out, reduced opacity (≤0.5), no pointer cursor, no interaction. Include persistent adjacent/help text explaining *why* it's disabled. If a tooltip is used, it must be triggered by a separate focusable element and announced to assistive technologies. |
| **Loading** | Show a skeleton, spinner, or progress indicator. The interactive area should be replaced or overlaid — never leave the user wondering if something is happening. |
| **Error** | Red border/background + descriptive error message adjacent to the element. The error message must explain *what went wrong* and *how to fix it*. |
| **Success** | Brief green confirmation (checkmark, border flash). Auto-dismiss or transition to the next logical state. |

- **DO:** Design every state for every interactive component before shipping. States are not edge cases — they are the UI.
- **DO:** Ensure all states are reachable and distinguishable by screen readers via appropriate ARIA attributes (`aria-disabled`, `aria-busy`, `aria-invalid`, `aria-describedby`).
- **DON'T:** Use the disabled state to hide information. Disabled buttons should still be visible and explain their disabled condition.
- **DON'T:** Remove `:focus-visible` styles (or the platform-equivalent focus indicator API). If the default focus indicator is visually incompatible, replace it with a custom, equally visible alternative — never remove it.

## 7. Motion & Micro-Interactions

Motion must be purposeful, fast, and respectful of user preferences.

### Principles

- **DO:** Use animation to serve a purpose: guide attention, show state transitions, provide feedback, or soften abrupt changes. Every animation must answer "what does this help the user understand?"
- **DO:** Keep durations short:
  - Micro-interactions (button press, hover transition): **100–200ms**
  - Small transitions (tooltip, dropdown, accordion open/close): **200–300ms**
  - Page transitions, modal open/close, navigation: **300–400ms**
  - Anything over 500ms feels sluggish.
- **DO:** Use easing curves intentionally:
  - `ease-out` for elements entering the screen (deceleration — feels natural).
  - `ease-in` for elements exiting (acceleration — user's attention has moved on).
  - `ease-in-out` for state changes within the viewport (expand/collapse).
  - Linear only for indefinite progress indicators (spinners).
- **DO:** Animate only compositor-friendly properties that avoid layout recalculations — `transform` (translate, scale, rotate) and `opacity` on the web, or platform equivalents that can be GPU-accelerated without triggering reflow/relayout.
- **DO:** Respect `prefers-reduced-motion`. When the user has this preference set, disable all non-essential animations or reduce them to opacity-only transitions under 100ms.
- **DON'T:** Animate layout-triggering properties (`width`, `height`, `top`, `left`, `margin`, `padding`) — they cause expensive layout recalculations.
- **DON'T:** Use bounce, elastic, or spring animations for functional UI elements. Reserve expressive animations for brand/onboarding moments only.
- **DON'T:** Auto-play infinite animations (except loading indicators). They distract and can trigger vestibular disorders in some users.
- **DON'T:** Let state transitions depend on animation timing without a completion signal. If an animation's end is required for a state change, perform that update only after the animation completes.

## 8. Content Strategy — Minimalism & Density

Minimalism is not about removing things — it's about removing distractions so the user can focus on what matters.

### Principles

- **DO:** Apply progressive disclosure: show only what the user needs at each step. Reveal complexity on demand via expandable sections, tooltips, or secondary views.
- **DO:** Use negative space (whitespace) intentionally to group related content and separate unrelated content. Crowded interfaces increase cognitive load and error rates.
- **DO:** Design for the empty state first. What does the user see when there's no data? Provide a helpful illustration, a clear message, and a call-to-action (e.g., "No invoices yet. Create your first invoice").
- **DO:** Use skeletons (animated placeholder shapes) during loading — not spinners for entire pages. Skeletons create the perception of faster loading and prevent layout shifts.
- **DON'T:** Present all information at once. If a view has more than 7±2 distinct information groups, break it into sections, tabs, or steps.
- **DON'T:** Truncate text without providing a way to see the full content (tooltip on hover, expand action, or dedicated detail view).
- **DON'T:** Use jargon or technical language in UI copy. Write for the user's reading level — prefer plain, actionable language.

### Content Density

- **DO:** Offer density preferences (compact vs comfortable) for data-heavy views (tables, lists, dashboards). Compact mode reduces padding and font-size slightly.
- **DO:** Prioritize information: critical data at the top/left, secondary data below/right. Follow the F-pattern (text-heavy) or Z-pattern (visual-heavy) scanning behavior.
- **DON'T:** Duplicate the same information in multiple places on the same screen. Each piece of data should have one canonical location.

## 9. Forms & Input

Forms are the primary conversation between user and application. Poor forms = poor conversion.

### Structure

- **DO:** Use a single-column layout for forms. Multi-column forms disrupt the vertical scanning flow and increase error rates.
- **DO:** Position labels above the input field (not inline as placeholders). Placeholder text disappears on focus and causes memory load. If the label must be inline, float it above on focus.
- **DO:** Group related fields into logical sections with clear headings. For long forms (>6 fields), split into steps with a progress indicator.
- **DO:** Size inputs proportionally to their expected content: short for ZIP codes, wide for email addresses, multi-line for descriptions.
- **DON'T:** Use placeholder text as the only label. This is an accessibility violation and a usability anti-pattern.

### Validation & Feedback

- **DO:** Validate on blur (when the user leaves the field), not on every keystroke. Real-time validation on keystrokes creates a hostile experience — the user sees errors before they finish typing.
- **DO:** Show errors inline, adjacent to the offending field, in red text with a clear message. The message must say *what* is wrong and *how* to fix it — not just "Invalid input."
- **DO:** Disable the submit button after the first click and show a loading state to prevent double submissions.
- **DON'T:** Clear the entire form on submission error. Preserve user input — only clear fields after a successful submission.
- **DON'T:** Rely solely on client-side validation. Always validate on the server.

### Touch & Ergonomics

- **DO:** Make all interactive elements at least **44×44 CSS pixels** — the minimum touch target for reliable finger interaction (WCAG 2.5.5 AAA). For native platforms, adapt to the platform's equivalent (e.g., 44pt on iOS, 48dp on Android).
- **DO:** Space interactive elements at least 8px apart to prevent accidental taps.
- **DO:** Place primary actions in easy thumb-reach zones (bottom-center or bottom-right for one-handed mobile use).
- **DON'T:** Place destructive actions (delete, reset) adjacent to primary actions without a confirmation step.

## 10. Accessibility

Accessibility is not a feature — it is a requirement.

- **DO:** Ensure all interactive elements are keyboard-navigable in a logical tab order. Users must be able to complete all tasks without a mouse.
- **DO:** Use semantic elements (`button`, `a`, `input`, `select`, `textarea`) for all interactive controls. Use ARIA (`role`, `aria-label`, `aria-describedby`, `aria-expanded`) only when the platform's native semantics are insufficient.
- **DO:** Maintain a minimum contrast ratio of 4.5:1 for normal text and 3:1 for large text (WCAG AA). Check with a contrast analyzer — don't guess.
- **DO:** Provide visible focus indicators with a contrast ratio of at least 3:1 against the background.
- **DO:** Respect user preferences: `prefers-reduced-motion`, `prefers-contrast`, `prefers-color-scheme`, and zoom levels up to 200%.
- **DON'T:** Use generic containers (`div`, `span`) as interactive elements unless no native semantic control can represent the interaction. In that rare fallback, add proper ARIA role, keyboard handlers, and focus management.
- **DON'T:** Use `aria-hidden="true"` on focusable elements — it creates an unreachable focus trap.
- **DON'T:** Rely on color alone to convey meaning (see § 4). Always pair with an icon, text label, or pattern.

## 11. Performance

- **DO:** Lazy-load non-critical UI: images below the fold, heavy components, secondary routes/screens.
- **DO:** Use skeleton placeholders (not spinners) for content that takes more than 300ms to load. Reserve space for lazy-loaded content to prevent Cumulative Layout Shift (CLS).
- **DO:** Optimize font loading: use `font-display: swap` (or platform equivalent) to show fallback text while custom fonts load. Subset fonts to include only the characters needed.
- **DON'T:** Block the initial render/paint with large style bundles, synchronous scripts, or heavy computations that are not needed for the first meaningful paint.
- **DON'T:** Render large lists (1000+ items) without virtualization (windowing). Only render items visible in the viewport plus a small buffer.

## 12. Iconography

Icons are visual shorthand — they must be immediately recognizable.

- **DO:** Use a single, consistent icon set throughout the application. Mixing icon sets (line, filled, different stroke widths) looks unprofessional.
- **DO:** Size icons on a consistent grid: 16px for inline with text, 20–24px for buttons and navigation, 32–48px for decorative or empty state illustrations.
- **DO:** Provide a text label alongside icons that carry critical meaning (navigation items, status indicators, actions without tooltips). Purely decorative icons can use `aria-hidden="true"`.
- **DO:** Ensure icons have sufficient contrast (≥3:1 against the background) and are legible at their rendered size.
- **DON'T:** Use icons alone for critical actions without a text label or accessible name. A gear icon for "Settings" is established convention and acceptable; an abstract icon with no label for a unique feature is not.
- **DON'T:** Use icons at non-integer pixel sizes — they will render blurry. Stick to the size grid.

## 13. Design Tokens & Consistency

- **DO:** Use design tokens (variables, constants, or platform equivalents) for every visual value: colors, spacing, typography, border-radius, shadows, z-indices, transitions.
- **DO:** Name tokens by their **role** (semantic), not their value. `--color-primary` and `--color-danger`, not `--color-blue-500` and `--color-red-500`. Semantic naming enables theme switching.
- **DO:** Organize tokens into categories: `color.*`, `spacing.*`, `typography.*`, `radius.*`, `shadow.*`, `z-index.*`.
- **DON'T:** Hardcode visual values directly in components. Every `margin`, `padding`, `color`, `font-size`, `border-radius`, and `box-shadow` must reference a token.
- **DON'T:** Use arbitrary values (`margin: 13px`) — every spacing and sizing value must come from the defined scale.
- **DON'T:** Create duplicate tokens with the same value but different names. `--color-error` and `--color-danger` should be consolidated.

**Exception escape hatch:** If a specific element genuinely cannot use a token (rare, specialized visual treatment), add a comment explaining why and mark it for review.

## 14. UI Interactions & Trade-offs

| Trade-off | Guidance |
|-----------|----------|
| **Accessibility vs. Visual Design** | A visually appealing component that is not keyboard-accessible or has low contrast fails the basic usability test. Prioritize accessibility over aesthetics. |
| **Component Reusability vs. Simplicity** | Overly parameterized components that try to cover every use case become hard to maintain. If a component needs too many variants, split it into focused sub-components. |
| **Design Tokens vs. Flexibility** | Tokens ensure consistency but can be too rigid for edge cases. Allow exceptions through explicit escape hatches but document them. |
| **Progressive Enhancement vs. Feature Parity** | Server-rendered pages should work without JavaScript. Client-side interactivity is an enhancement, not a requirement for core functionality. |
| **Performance vs. Interactivity** | Lazy-loading improves initial load time but can introduce layout shifts. Use skeletons and reserve space for lazy-loaded content. |
| **Minimalism vs. Discoverability** | Hiding secondary actions reduces visual clutter but can make features undiscoverable. Use progressive disclosure: show primary actions, reveal secondary on hover/expand. |
| **Animation vs. Usability** | Animations can delight but also delay. Keep them under 400ms. Users on repeated visits value speed over charm — consider reducing animations for returning users. |
| **Consistency vs. Context** | A single design system works for 90% of cases. For the remaining 10% (dashboards, editors, maps), optimize for the task — don't force a generic pattern where it hurts productivity. |
| **Rich UI vs. Load Performance** | Every visual enhancement (shadows, gradients, custom fonts, animations) adds bytes and rendering cost. Audit the performance budget — remove flourishes that don't carry functional value. |

## 15. Code Review Checklist

When reviewing UI code, verify:

### Visual Foundation
- [ ] Typographic scale is defined and consistently applied; no ad-hoc font sizes.
- [ ] Line-height is appropriate per text role (1.4–1.6 body, 1.1–1.3 headings).
- [ ] All spacing values come from the defined spacing scale (no arbitrary `margin: 13px`).
- [ ] Layout is aligned to a grid; no mixed alignment styles without reason.
- [ ] Mobile-first design applied; breakpoints enhance upward, not patch downward.
- [ ] Layout uses relative units (`%`, `rem`, `fr`); no fixed pixel widths on containers.

### Color
- [ ] Palette includes primary, secondary, neutral scale, and semantic colors (success, warning, danger, info).
- [ ] All text/background combinations meet WCAG AA contrast (4.5:1 normal, 3:1 large).
- [ ] Dark mode is considered; semantic colors are desaturated for dark backgrounds.
- [ ] Color is not the sole conveyor of information — paired with icons or text.

### Component Design
- [ ] Components are self-contained and have a single visual responsibility.
- [ ] Presentational and container concerns are separated.
- [ ] Component API uses enumerated variants, not arbitrary string props.

### Interaction States
- [ ] All interactive elements have designed states: default, hover, focus-visible (or platform equivalent), active/pressed, disabled, loading, error, success.
- [ ] Focus indicators are visible and high-contrast (≥3:1 against background).
- [ ] Disabled elements explain *why* they are disabled.
- [ ] Loading states use skeletons for content; spinners only for short operations.

### Motion
- [ ] All animations have a clear purpose; no decorative-only animations.
- [ ] Durations are correct: 100–200ms micro, 200–300ms small transitions, 300–400ms page transitions.
- [ ] `prefers-reduced-motion` is respected.
- [ ] Only `transform` and `opacity` are animated (or platform equivalents that avoid layout thrashing).

### Content
- [ ] Empty states have helpful messages and a call-to-action.
- [ ] Progressive disclosure is applied; no information overload on a single screen.
- [ ] UI copy is plain, actionable, and free of jargon.

### Forms
- [ ] Single-column layout for forms.
- [ ] Labels are above inputs (not placeholder-only).
- [ ] Validation occurs on blur, with inline error messages that explain the fix.
- [ ] Touch targets are ≥44×44px; interactive elements spaced ≥8px apart.
- [ ] Submit button shows loading state after first click.

### Accessibility
- [ ] All interactive elements are keyboard-navigable.
- [ ] Semantic elements used for interactive controls; ARIA only when native semantics insufficient.
- [ ] `prefers-reduced-motion`, `prefers-contrast`, and `prefers-color-scheme` are respected.
- [ ] No `aria-hidden` on focusable elements.

### Icons & Tokens
- [ ] Single, consistent icon set; sized on a consistent grid.
- [ ] Critical icons have text labels or accessible names.
- [ ] No hardcoded visual values — all colors, spacing, typography, radius, shadows use design tokens.
- [ ] Tokens are named by role (semantic), not by raw value.

### Performance
- [ ] Non-critical UI is lazy-loaded; initial render is not blocked by heavy assets.
- [ ] Fonts use `font-display: swap` (or platform equivalent).
- [ ] Large lists are virtualized.
- [ ] Content placeholders reserve space to prevent CLS.

### Consistency
- [ ] New components follow the existing design system or platform conventions.
- [ ] No new colors, spacing values, or font sizes introduced outside the token system.

## 16. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `ui-design.md §8`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Interactive element (button, link, form field) not keyboard-accessible or missing ARIA role/label, blocking core user flows (§8); hardcoded secret or sensitive data rendered in UI/template (→ security.md §3) |
| 🟡 **WARN** | Component introduced without checking for an existing reusable equivalent — duplication confirmed (§3); hardcoded color, spacing, or font value instead of design token (§4); missing interaction state (focus, error, loading, disabled) on an interactive element (§6); no responsive behavior on a new UI component expected to render on mobile (§9); touch target smaller than 44×44 px on a mobile screen (§8) |
| 🟢 **INFO** | Minor inconsistency in naming relative to the design system conventions (§4); large list not virtualized but data set is currently small and bounded (§15); component slightly outside the design system pattern but not causing duplication or accessibility issues (§3) |

## 17. Applying This Standard with a Limited Scope

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
6. **State & interaction fixes.**
   - Adding missing interaction states (focus, hover, active/pressed, disabled, loading, error, success) to an in-scope component is always allowed.
7. **Scope-safe improvements are always allowed:**
   - Replacing magic numbers with design tokens (within the same file or a token file in scope).
   - Adding semantic elements and ARIA labels.
   - Extracting a presentational component from a container component if both stay within scope.
   - Adding inline validation or error messages to a form within scope.
   - Replacing a generic icon with one from the project's icon set.
