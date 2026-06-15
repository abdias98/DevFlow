# DevFlow Engineering Standards: Accessibility (a11y) (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-06-15

> **Note on examples:** Element names, ARIA attributes, and APIs are illustrative (web-oriented). Map them to the accessibility API of the detected platform (web/ARIA, iOS/UIKit accessibility, Android/TalkBack, desktop toolkits). The principles are universal; the primitives differ.

Accessibility is **not a feature — it is a requirement**. Apply these principles to any user-facing interface you design, generate, or review. This standard was extracted from `ui-design.md` to give accessibility its own first-class home; UI design and accessibility are reviewed together.

## 1. Perceivable

- **What:** Users must be able to perceive the information presented, regardless of sensory ability.
- **DO:**
  - Provide text alternatives for non-text content (images, icons, charts): meaningful `alt` text, or an explicitly empty alternative for purely decorative imagery.
  - Provide captions/transcripts for audio and video.
  - Never rely on color alone to convey meaning — pair it with text, an icon, or a pattern.
- **DON'T:**
  - Ship informative images/icons with no accessible name.
  - Encode state (error, success) using only color.

## 2. Color Contrast

- **What:** Insufficient contrast makes content unreadable for low-vision users and in bright environments.
- **DO:**
  - Meet at least **WCAG AA**: contrast ratio **4.5:1** for normal text, **3:1** for large text and meaningful UI components/graphics.
  - Verify with a contrast analyzer — do not eyeball it.
- **DON'T:**
  - Use low-contrast "subtle" gray-on-gray text for content that must be read.
  - Place text over images without a scrim/overlay guaranteeing contrast.

## 3. Keyboard Operability

- **What:** Every interaction must be possible without a pointing device.
- **DO:**
  - Make all interactive elements reachable and operable by keyboard in a logical tab order; users must complete every task without a mouse.
  - Support expected keys (Enter/Space to activate, Esc to dismiss, arrow keys within composite widgets).
  - Manage focus deliberately: move focus into opened dialogs/menus, trap it while modal, and return it on close.
- **DON'T:**
  - Create keyboard traps the user cannot exit.
  - Remove the focus outline without providing an equally visible replacement.
  - Bind actions only to mouse/hover/touch events.

## 4. Visible Focus

- **What:** Keyboard users must always be able to see where they are.
- **DO:**
  - Provide a clearly visible focus indicator with a contrast ratio of at least **3:1** against its background.
  - Ensure focus order follows the visual/reading order.
- **DON'T:**
  - Set focus styles to `none`/invisible.
  - Let focus jump unpredictably or land on hidden elements.

## 5. Semantics & ARIA

- **What:** Assistive technology relies on correct roles, names, states, and structure.
- **DO:**
  - Use native semantic elements/controls (`button`, `a`, `input`, `select`, headings, lists, landmarks) before reaching for ARIA — they bring behavior and semantics for free.
  - Use ARIA (`role`, `aria-label`, `aria-describedby`, `aria-expanded`, …) **only** when native semantics are insufficient, and keep ARIA state in sync with actual state.
  - Give every control an accessible name; associate labels with their fields.
- **DON'T:**
  - Use generic containers (`div`/`span`) as interactive controls unless no native control fits — and then add the correct role, keyboard handlers, and focus management.
  - Put `aria-hidden="true"` on a focusable element (it creates an unreachable focus trap).
  - Apply ARIA roles that contradict the element's real behavior.

## 6. Forms & Errors

- **What:** Forms are where inaccessible UIs most directly block task completion.
- **DO:**
  - Associate a programmatic label with every input; group related controls (fieldset/legend or platform equivalent).
  - Identify errors in text (not color alone), tie the message to the field, and move focus to the first error.
  - Expose required/invalid state programmatically, not just visually.
- **DON'T:**
  - Use placeholder text as the only label.
  - Signal validation failure with a red border alone.

## 7. Dynamic Content & Motion

- **What:** Content that changes after load, and motion, can exclude or harm users if unmanaged.
- **DO:**
  - Announce important asynchronous updates to assistive tech (live regions / platform announcements).
  - Respect user preferences: reduced motion, increased contrast, color scheme, and zoom/text scaling up to **200%** without loss of content or function.
  - Keep target sizes comfortable (a common floor is ~44×44 px / 24px minimum per WCAG) for touch.
- **DON'T:**
  - Auto-play motion or carousels that cannot be paused, or animation that ignores `prefers-reduced-motion`.
  - Silently swap content so screen-reader users never learn it changed.

## 8. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `accessibility.md §3`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Interactive element (button, link, form field, control) not keyboard-operable, or missing an accessible name/role, blocking a core user flow (§3, §5); `aria-hidden="true"` (or equivalent) on a focusable element creating an unreachable trap (§5); keyboard trap with no exit (§3); form input with no programmatic label on a critical flow (§6) |
| 🟡 **WARN** | Text/UI below the WCAG AA contrast minimum (§2); missing or invisible focus indicator (§4); meaning conveyed by color alone (§1); validation error shown by color only, or not tied to the field (§6); informative image/icon with no text alternative (§1); motion that ignores reduced-motion preference (§7); touch target below the recommended minimum (§7) |
| 🟢 **INFO** | ARIA used where a native semantic element would suffice (§5); async update not announced via a live region (§7); zoom/reflow not yet verified to 200% (§7); focus order slightly out of step with visual order (§4) |

## 9. Applying This Standard with a Limited Scope

When reviewing or modifying accessibility in a **specific set of files**, follow these constraints:

1. **Only change markup/behavior within the approved scope.** If an out-of-scope component has an a11y violation, flag it as a finding (WARN/BLOCK note) rather than editing it.
2. **Fixing a keyboard trap, a missing accessible name, or a focus-hidden control is always worth surfacing** when it occurs in a file you are already modifying — these block users entirely.
3. **Do not introduce a new accessibility/UI framework or global ARIA strategy** unless it is explicitly in scope; use the platform's native semantics and the project's existing patterns.
4. **When adding accessibility to satisfy this standard**, prefer native semantic controls over ARIA, and verify contrast and keyboard operation rather than assuming them.
