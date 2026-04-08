# Stack Planning Rules

## When to Apply

Only when the user chose **Stack Mode: yes** in Step 1.

## Grouping Rules (apply in this order)

1. **Logical cohesion first** — natural layers make ideal Stacks: `Data layer + Migrations`, `API / Controllers`, `Frontend / Views`, `Auth integration`, etc.
2. **Soft size limit** — aim for ~400 lines of diff and ~8 files per Stack; split larger layers if needed
3. **Hard dependency rule** — if Task A is a prerequisite for Task B, they must be in the same Stack *or* A must be in an earlier Stack
4. **Migration rule** — schema migrations and model changes always travel together in the same Stack; migrations must be the first tasks of their Stack

## Stack Metadata

For each Stack, assign:
- **Number** — sequential integer starting at 1
- **Title** — short descriptive label (e.g., "Data layer + Migrations")
- **Branch** — `feat/{slug}/stack-{N}`
- **Base branch** — `main`/`develop` for Stack 1; `feat/{slug}/stack-{N-1}` for all others
- **PR title** — `[N/M] feat({scope}): {stack title}`

## Plan Document Additions

Add to the plan document:
- A `## Stack Plan` section (before File Map) with a summary table of all Stacks
- Divider headings between task groups: `--- Stack N/M: {title} | branch: feat/{slug}/stack-N ---`
- Two extra items to the Self-Review Checklist:
  - `[ ] Stacks defined with branch and PR title assigned`
  - `[ ] Stack dependencies respected (no forward references)`
