# Brainstormer Questions Template

## Evaluation Matrix

Use this matrix to analyze the user's request. **Do NOT ask all of these questions as a rigid list.** Infer what you can from the prompt, and only ask about what is missing, ambiguous, or contradictory.

| Category | What to clarify |
|----------|----------------|
| **Goal** | What is the primary outcome? What does "done" look like? |
| **Scope** | What is explicitly in scope and out of scope? |
| **Constraints** | Performance, compatibility, deadlines, tech restrictions? |
| **Users** | Who will use this? What are their expectations? |
| **Edge Cases** | Invalid, empty, or unexpected input behavior? |
| **Assumptions** | What is assumed but not explicitly stated? |
| **Definition of Done** | How to verify it works? What specific output or behavior proves completion? |
| **Feature Type** | web frontend / backend / fullstack / mobile / CLI / library / desktop / other |
| **Impact** | Does this change existing behavior? Which features could be affected? |

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
**Feature Type:** {type}
**Stack Mode:** {yes | no}
**Selected Mockup:** {filename, if applicable}

## Stack Profile
[To be detected by Architect]

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
| Proceed if goal unclear | Keep asking until unambiguous |
| Proceed without explicit approval | Ask user to approve the Understanding Summary |
