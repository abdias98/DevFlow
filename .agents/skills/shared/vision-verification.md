# Vision Verification — Canonical Pattern

> **Framework-centric principle:** vision is a **primitive that the framework invokes when the environment supports it** (see [environment-probe.md](./environment-probe.md)), not a capability that depends on a specific model. The framework decides when to compare a mockup against the implemented UI; if the editor has vision tools (image reading), it uses them; if not, it falls back to code-only review.

This document defines the canonical pattern for vision-based verification in DevFlow. The Reviewer and Debugger reference this file when the environment supports vision and the feature has a UI.

---

## When to Use Vision Verification

**Use vision verification when ALL of these hold:**
- The environment capability probe detected `vision: yes` (see [environment-probe.md](./environment-probe.md)).
- The feature has a UI component (mockups were created in Phase 4).
- The implementation produced visible UI (HTML/CSS, component rendering, layout).

**Do NOT use vision verification when:**
- `vision: no` or `unknown` — fall back to code-only review (check design tokens, accessibility attributes, layout code structure — but do not compare rendered output).
- The feature is backend-only (no UI).
- The change is non-visual (data layer, API, configuration, refactoring that doesn't affect rendering).

---

## The Pattern

### 1. Reviewer Visual Diff (Phase 6)

For UI features, the Reviewer adds a **visual diff** sub-step after the code review (Step 3 multi-dimension review). This sub-step is dispatched only when `vision: yes` is in `context.md` → `## Environment Capabilities`.

**Procedure:**
1. **Locate the approved mockup** — read `context.md` → `## Selected Mockup` (or the mockups directory if not yet selected).
2. **Take or request a screenshot** of the implemented UI:
   - If the editor supports screenshot tools, use them to capture the rendered UI.
   - If the project has a dev server, ask the user (Pair mode) or auto-execute (Standard/Autonomous mode) the command to render the page and capture a screenshot.
   - If neither is available, ask the user to provide a screenshot.
3. **Compare the mockup against the screenshot** — read both images using vision tools and report discrepancies:
   - Layout differences (spacing, alignment, positioning).
   - Color differences (design token mismatches, contrast issues).
   - Typography differences (font family, size, weight).
   - Component structure differences (missing elements, extra elements, wrong hierarchy).
   - Responsive behavior (if multiple breakpoints are in the mockup).
4. **Report findings** using the standard severity scale:
   - 🔴 **BLOCK** — the implemented UI significantly deviates from the approved mockup (wrong layout, missing major component, broken visual hierarchy).
   - 🟡 **WARN** — minor deviations (spacing off by a few pixels, slight color mismatch, minor typography difference).
   - 🟢 **INFO** — observation (the implementation looks better than the mockup in some detail, or matches exactly).

**Output format:**
```markdown
### Visual Diff Findings

**Mockup:** {path to mockup file}
**Screenshot:** {path to screenshot or "user-provided"}

| # | Severity | Area | Finding |
|---|----------|------|---------|
| 1 | BLOCK | Layout | Header height is 80px in mockup, 60px in implementation. |
| 2 | WARN | Color | Button background is #007bff (mockup) vs #0066cc (implementation). |
| 3 | INFO | Typography | Body text matches mockup exactly. |
```

### 2. Debugger Screenshot Analysis (Phase 7)

The Debugger can accept screenshots of errors when vision is available:

- **UI crash/breakage:** the user provides a screenshot of the broken UI. The Debugger reads it with vision tools and identifies the visual symptom (overlapping elements, missing styles, JS error overlay, blank page).
- **Console errors with visual context:** a screenshot showing both the error state and the UI context helps the Debugger understand what was happening when the error occurred.
- **Cross-browser issues:** screenshots from different browsers help identify rendering inconsistencies.

**Procedure:**
1. The user (or Standard/Autonomous mode) provides a screenshot of the error state.
2. The Debugger reads the screenshot with vision tools.
3. The Debugger describes what it sees (visual symptom, error messages visible, UI state).
4. The Debugger correlates the visual symptom with code (reads the relevant components, styles, layout files).
5. The Debugger identifies the root cause and proposes a fix.

### 3. Architect Diagram Reading (Phase 3)

When the codebase has existing architecture diagrams (photos, exports from diagramming tools), the Architect can read them with vision tools to extract structure:

- **Component diagrams** → identify components, their relationships, and layer boundaries.
- **Data flow diagrams** → identify how data moves through the system.
- **Deployment diagrams** → identify infrastructure and deployment topology.

This is **supplementary** to code exploration — the Architect reads the diagram for context, then explores the code to verify and detail what the diagram shows.

---

## Fallback: Code-Only Review (No Vision)

When `vision: no` or `unknown` in `context.md` → `## Environment Capabilities`:

- **Reviewer:** no visual diff sub-step. The review is code-only — checks design tokens (colors, spacing, typography are defined as tokens, not hardcoded), accessibility attributes (keyboard navigation, ARIA labels, contrast ratios), layout code (relative units, responsive breakpoints), and component structure (self-contained, reusable). The Reviewer notes: "Visual diff skipped — no vision tools available. Code-only review performed. Recommend manual visual review."
- **Debugger:** no screenshot analysis. Debugging relies on logs, stack traces, error messages, and code inspection only.
- **Architect:** no diagram reading. Architecture is extracted from code exploration only.

The cycle never breaks — it just loses the visual verification dimension.

---

## Anti-Patterns

- ❌ **Assume vision is available** — always check `context.md` → `## Environment Capabilities` before attempting to read images. If `vision: no`, use the code-only fallback.
- ❌ **Skip the visual diff for UI features when vision IS available** — the visual diff catches layout, color, and typography issues that code-only review misses. It's the whole point of having vision tools.
- ❌ **Use vision for non-visual changes** — don't dispatch a visual diff for a backend API change or a data layer refactoring. Only use vision when the change affects rendered UI.
- ❌ **Block on minor visual deviations** — a few pixels of spacing difference is a WARN, not a BLOCK. Reserve BLOCK for significant deviations that make the UI functionally different from the approved mockup.
- ❌ **Rely on vision alone** — the visual diff supplements code review; it doesn't replace it. Code-only checks (design tokens, accessibility, component structure) still run even when vision is available.

---

## Agents That Apply This Pattern

| Agent | Application | Condition |
|-------|-------------|-----------|
| **Reviewer** (Phase 6) | Visual diff sub-step after multi-dimension review | `vision: yes` AND feature has UI |
| **Debugger** (Phase 7) | Screenshot analysis of error states | `vision: yes` AND user provides screenshot |
| **Architect** (Phase 3) | Diagram reading for architecture context | `vision: yes` AND diagrams exist in codebase |

See each agent's SKILL.md for the specific step where vision verification is integrated.
