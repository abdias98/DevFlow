# Bug-Fixer Questions Template

## Mandatory Questions

| Category | What to clarify |
|----------|----------------|
| **Error Details** | What is the exact error message, stack trace, or unexpected behavior? |
| **Reproduction Steps** | What steps trigger the bug? Can you provide a minimal reproduction case? |
| **Expected Behavior** | What should have happened instead? |
| **Affected Area** | Which files, functions, or components are involved? Any no-go zones? |
| **Existing Tests** | Does the project have tests? Where are they? What command runs them? |
| **Definition of Done** | What does success look like? How will we verify the bug is fixed? |

## Understanding Summary Template

```markdown
## 🐛 Bug Understanding

### Error Summary
{One sentence describing the bug}

### Error Details
- **Error type:** {TypeError | NullReferenceException | 404 | timeout | wrong output | ...}
- **Error message:** {exact message or stack trace excerpt}
- **Affected file(s):** `{file1}`, `{file2}`
- **Affected function/method:** {name}

### Steps to Reproduce
1. {step 1}
2. {step 2}
3. {step 3}

### Expected Behavior
{What should have happened}

### Constraints & Risks
- {constraint 1}

### Definition of Done
- {criterion 1}

### Problem Restatement
{2-3 sentences restating the bug and the fix goal}