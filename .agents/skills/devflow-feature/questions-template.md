# Feature Agent Questions Template

## Questions to Clarify

Ask these ONLY when the answer is missing or ambiguous — infer what you can from the user's request and the codebase (see SKILL.md Step 1). If the request already includes scope, Definition of Done, and a reference implementation, skip the questions entirely and confirm your understanding in the Understanding Summary instead.

| Category | What to clarify |
|----------|----------------|
| **Goal** | What is the primary outcome? What does "done" look like? |
| **Scope** | What exactly are we building? Which files/areas are we touching? Any no-go zones? |
| **Definition of Done** | What are the 1-3 verifiable criteria that prove the feature works? |
| **Reusable Code** | Is there similar existing code or patterns to follow? Where? |
| **Dependencies** | Does this depend on other features, libraries, or services? |

## Feature Type Follow-ups (optional)

| Type | Follow-up |
|------|-----------|
| API endpoint | REST or GraphQL? Request/response format? Authentication? |
| UI component | Which screen/page? Responsive? Accessibility requirements? |
| Utility/function | Pure function or side-effect? Performance constraints? |
| CLI command | Subcommand structure? Flags/args? Interactive or scripted? |

## Understanding Summary Template

```markdown
## ⚡ Feature Understanding

### Goal
{One sentence}

### Scope
- **In:** {what's included}
- **Out:** {what's excluded}

### Definition of Done
- {criterion 1}
- {criterion 2}

### Reference Implementation
- {file or pattern to follow, if any}

### Constraints & Risks
- {constraint 1}