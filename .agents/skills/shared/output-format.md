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

> **Important:** Every agent response MUST include an `### Additional Recommendations` section at the end (even if empty). Use it to surface out-of-scope improvements, standard violations, and future considerations.

## Agent Identifiers

| Agent | Emoji | Phase |
|-------|-------|-------|
| Brainstormer | 🧠 | Phase 1 |
| Architect | 🧩 | Phase 2 |
| Planner | 📋 | Phase 3 |
| Implementer | ⚙️ | Phase 5 |
| Reviewer | 🔍 | Phase 6 |
| Debugger | 🐞 | Phase 7 |
| Finalizer | 🚀 | Phase 8 |
| Tester | 🧪 | Manual |
| Refactorer | 🔧 | Standalone |
| Bug-Fixer | 🩹 | Standalone |
| Feature Agent | ⚡ | Standalone |
| Performance Agent | 📊 | Standalone |
| Migration Agent | 🗄️ | Standalone |
| Contract Agent | 🔗 | Standalone |
| Documentation Agent | 📚 | Standalone |
| Template Agent | 📐 | Standalone |
| Tutorial Agent | 🎓 | Standalone |
| Reverse Agent | 🔬 | Standalone |
| Orchestrator | 🎯 | Standalone |
