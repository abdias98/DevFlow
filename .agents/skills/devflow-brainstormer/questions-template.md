# Brainstormer Questions Template

## Mandatory Questions

These questions MUST always be asked — never skip even if the request seems clear:

| Category | What to clarify |
|----------|----------------|
| **Goal** | What is the primary outcome? What does "done" look like? |
| **Scope** | What is in scope? What is explicitly out of scope? |
| **Constraints** | Performance, compatibility, deadlines, tech restrictions? |
| **Users** | Who will use this? Expectations? |
| **Edge Cases** | Invalid, empty, or unexpected input behavior? |
| **Assumptions** | What is assumed but not stated? |
| **Definition of Done** | How to verify it works? What would you see? |
| **Feature Type** | web frontend / backend / fullstack / mobile / CLI / library / desktop / other |
| **Impact** | Does this change existing behavior? Which features could be affected? |

## Minimum Questions (if request is vague)

- What is the expected output when this works correctly?
- Are there cases where it should NOT work (failure path)?
- Does this involve any UI/visual changes?

## Feature Type Follow-ups

| Type | Follow-up |
|------|-----------|
| Web frontend | Target device? Responsive? WCAG? |
| Mobile | Platform? Min OS? Consumer/enterprise? Framework? |
| CLI tool | Runtime? Distribution? Interactive or scripted? |
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

### Assumptions
- {assumption 1}

### Feature Type
- **Type:** {detected type}
- **Platform/Environment:** {details}
- **Accessibility:** {requirements or "Standard"}

### Impact
- **Modifies existing behavior:** {Yes/No}
- **Affected features:** {list or "None"}

### Definition of Done
- {criterion 1}
- {criterion 2}

### Problem Restatement
{2-3 sentences restating the problem}
```

## Context.md Template

```markdown
# DevFlow Context

**Request:** {original request}
**Slug:** {feature-slug}
**Tech Stack:** {to be detected by Architect}
**Feature Type:** {type}
**Stack Mode:** {yes | no}
**Selected Mockup:** {filename, if applicable}

## Goal
{One-sentence summary}

## Definition of Done
- {verifiable criterion 1}

## Constraints
- {constraint 1}

## Edge Cases
- {edge case 1}

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
| Suggest implementations | Leave to Phase 2 |
| Skip when vague | Ask — even if obvious |
| Proceed if goal unclear | Keep asking |
