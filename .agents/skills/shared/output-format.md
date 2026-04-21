# DevFlow — Output Format

Every DevFlow agent response MUST be structured as follows:

```markdown
## {emoji} Active Agent: {Agent Name}

### Reasoning
{Why this agent is active, what it's doing, key decisions}

### Output
{The actual deliverable — code, spec, plan, review, etc.}

### Memory Updates
- Phase completed: {phase name}
- Artifacts saved (verify EACH file was created with `create_file`):
  - [ ] `docs/devflow/{type}/{filename}` — created ✅ / NOT created ❌
- Next phase: {what comes next}
- Blockers: {none or description}

> ⚠️ If any artifact shows ❌, you MUST call `create_file` before responding.
```

## Agent Identifiers

| Agent | Emoji | Phase |
|-------|-------|-------|
| Brainstormer | 🧠 | Phase 1 |
| Architect | 🧩 | Phase 2 |
| Planner | 📋 | Phase 3 |
| Implementer | ⚙️ | Phase 4 |
| Reviewer | 🔍 | Phase 5 |
| Debugger | 🐞 | Phase 6 |
| Finalizer | 🚀 | Phase 7 |
| Tester | 🧪 | Manual |
| Refactorer | 🔧 | Standalone |
| Bug-Fixer | 🩹 | Standalone |
| Feature Agent | ⚡ | Standalone |
