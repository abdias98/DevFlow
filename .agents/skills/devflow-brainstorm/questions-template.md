# Brainstormer Questions Template

## Evaluation Matrix

Use this matrix to analyze the user's request. **Do NOT ask all of these questions as a rigid list.** Infer what you can from the prompt, and only ask about what is missing, ambiguous, or contradictory.

| Category | What to clarify |
|----------|----------------|
| **Goal** | What is the primary outcome? What does "done" look like? |
| **Scope** | What is explicitly in scope and out of scope? |
| **Constraints** | Performance, compatibility, deadlines, tech restrictions? |
| **Users & Context of Use** | Who will use this, for which goal and main task, in what environment, through which interface (GUI, command line, both, or a script)? What do they expect? — the *context of use* of ISO 9241-11; for a user-facing feature it becomes the spec's User Experience section (`user-experience.md §16`) |
| **Mistakes & Lost Work** *(user-facing)* | What can the user break or lose by mistake — a destructive action, a long form, an unsaved edit, an expired session — and how do they get it back (undo, confirmation, draft)? (`user-experience.md §3`, §5) |
| **Edge Cases** | Invalid, empty, or unexpected input behavior? |
| **Transitions & Lifecycle** | What happens when something changes over time: the input or context changes while work is in flight, an action is repeated, results arrive out of order, the user leaves halfway, a step fails after another succeeded? What must reset and what must persist? Use the [Transition Prompts](<{{SKILLS_DIR}}/shared/behavior-scenarios.md>) — ask only what this feature can actually exhibit, in the user's terms, never as design. |
| **Assumptions** | What is assumed but not explicitly stated? |
| **Definition of Done** | How to verify it works? What specific output or behavior proves completion? Write each criterion as `{criterion} → verify: test|command|manual — {observable result}` — *"POST /orders → verify: test — responds 201 with `{id, status}`"*, never *"works well"*; a `manual` check names its reason. `devflow-ctl artifacts check context` fails a criterion without it. **Universal criteria** (lint, build, tests, no BLOCKs, etc.) are defined in [dod-template.md](<{{SKILLS_DIR}}/shared/dod-template.md>) and apply automatically to every cycle. Only add feature-specific criteria here. |
| **Feature Type** | web frontend / backend / fullstack / mobile / CLI / library / desktop / other |
| **Impact** | Does this change existing behavior? Which features could be affected? |

## Feature Type Follow-ups

| Type | Follow-up |
|------|-----------|
| Web frontend | Target device? Responsive? WCAG? Languages/locales? |
| Mobile | Platform? Min OS? Consumer/enterprise? Framework? |
| CLI tool | Runtime? Distribution? Run by a person, by scripts, or both (`user-experience.md §10`)? |
| Library/SDK | Public API contract? Language targets? Versioning? |
| Desktop | OS targets? Native or Electron? Distribution? |

## Understanding Summary Template

```markdown
## 🎯 Understanding Summary

### Goal
{One sentence}

### Constraints
- {constraint 1}

### Edge Cases
- {edge case 1}

### Behavior Scenarios
- When {something changes / repeats / fails / arrives out of order}, the user sees {expected outcome} — or "None — {why the feature has no transitions}"

### Assumptions
- {assumption 1}

### Feature Type
- **Type:** {detected type}
- **Platform/Environment:** {details}
- **Accessibility:** {requirements or "Standard"}

### Context of Use *(user-facing features only — otherwise "N/A — no user-facing interface")*
- **Users:** {who}
- **Goal & main task:** {what they are trying to get done}
- **Environment & interface:** {GUI / command line / both; device, locale(s)}
- **Mistakes & lost work:** {what they could break or lose, and how they recover it}

### Impact
- **Modifies existing behavior:** {Yes/No}
- **Affected features:** {list or "None"}

### Definition of Done
- {criterion} → verify: {test | command | manual} — {observable result: the status, value or output that proves it}

### Problem Restatement
{2-3 sentences restating the problem}
```

## Context.md Template

```markdown
# DevFlow Context

**Request:** {original request}
**Slug:** {feature-slug}
**Feature Type:** {type}
**Stack Mode:** {yes | no}
**Selected Mockup:** {filename, if applicable}

## Stack Profile
[To be detected by Architect]

## Goal
{One-sentence summary}

## Definition of Done
- {criterion} → verify: {test | command | manual} — {observable result: the status, value or output that proves it}

## Constraints
- {constraint 1}

## Edge Cases
- {edge case 1}

## Behavior Scenarios
- When {…}, the user sees {…} — or "None — {reason}" ([behavior-scenarios.md](<{{SKILLS_DIR}}/shared/behavior-scenarios.md>))

## Context of Use
- **Users:** {who} · **Goal & main task:** {…} · **Environment & interface:** {GUI / command line / both; locales} · **Mistakes & lost work:** {…}
- or "N/A — no user-facing interface"

## Assumptions
- {assumption 1}

## Impact
- **Modifies existing behavior:** {yes | no}
- **Affected features:** {list}
```

## Strict Prohibitions

| ❌ NEVER | ✅ Instead |
|----------|-----------|
| Write code/pseudocode | Ask questions or restate problem |
| Define schemas/classes | Describe WHAT, not HOW |
| Suggest implementations | Leave to Phase 3 |
| Proceed if goal unclear | Keep asking until unambiguous |
| Proceed without explicit approval | Ask user to approve the Understanding Summary |
