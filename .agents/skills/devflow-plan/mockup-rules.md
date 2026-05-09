# HTML Mockup Rules

## When to Generate

**Determine if this is a UI feature using BOTH sources:**
1. Check `Feature Type` in session memory — if `web frontend`, `fullstack`, or `mobile` → generate mockup
2. **Also scan the spec itself** for keywords like: `page`, `view`, `screen`, `form`, `modal`, `component`, `UI`, `interface`, `dashboard`, `button`, `input`, `layout` → if any are present, generate mockup
3. **When in doubt, generate the mockup.** Only skip if the spec explicitly describes a backend-only feature (API, CLI, library, migration, etc.) with zero UI components.

## Single vs. Multiple Proposals

- If the spec **specifies a concrete UI design** (exact layout, component placement, visual references) → generate **1 mockup**.
- If the design is **open-ended or underspecified** (e.g., "a dashboard", "a form", "a list page" without layout details) → generate **2–3 alternative mockup proposals** with different layouts/approaches. Label them clearly (e.g., Proposal A: Sidebar layout, Proposal B: Tab-based layout, Proposal C: Card grid).

## HTML Rules

- Pure HTML + inline CSS — **no external CDN links, no JS frameworks, no images** (fully self-contained)
- Wireframe aesthetic: system font, `#f5f5f5` background, `#333` text, `#ccc` borders, `#ddd` fill for placeholders
- One `<section>` per screen or view identified in the spec
- Each section must include:
  - A visible heading with the screen name
  - Structural placeholders: header bar, navigation, content areas, sidebars
  - Interactive elements: buttons (labeled), input fields, dropdowns, checkboxes, tables, lists — all styled but static
  - Annotation labels in `<small style="color:#999">` describing what each area does
- Add a simple tab/link nav at the top of the page so the user can jump between sections
- No actual application logic — placeholders only

## Saving

1. **ALWAYS use `create_file`** to save the HTML file(s):
   - **Single mockup:** `docs/devflow/mockups/YYYY-MM-DD-{slug}-mockup.html`
   - **Multiple proposals:** `docs/devflow/mockups/YYYY-MM-DD-{slug}-mockup-A.html`, `-mockup-B.html`, `-mockup-C.html`
2. **Display the complete HTML inline** in the chat response inside a `html` code block
3. Announce the saved path(s) and instruct the user they can also open in a browser
4. **Continue automatically** to the next step — do NOT wait for confirmation (mockup selection happens at the Confirmation Gate)
