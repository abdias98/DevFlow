# Contributing to DevFlow

**DevFlow v2.7.0** — Multi-agent AI framework with multi-editor support via YAML profiles.

Thanks for your interest in contributing to DevFlow! 🎉

## How to Contribute

### Report Issues
Found a bug or have a suggestion? Open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs. actual behavior
- Your OS and editor/CLI version

### Submit Pull Requests

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Make your changes
4. Test your changes
5. Commit with clear messages: `git commit -m "feat: add X functionality"`
6. Push and create a PR

### Code Style

- **Skills:** Follow existing `SKILL.md` format (YAML frontmatter + markdown workflow). Use `{{SKILLS_DIR}}` for all internal path references. Reference `rules.md` as the canonical source for shared rules.
- **Prompts:** Keep `.prompt.md` files focused on a single phase or standalone agent. Avoid duplicating procedures already defined in the corresponding `SKILL.md`. Reference `rules.md` at the start.
- **Standards:** Engineering standards live in `.agents/skills/shared/standards/` using a strict `DO/DON'T` format with clear reasoning principles. Standards must be technology-agnostic (no framework-specific examples). Each standard should include a "Limited Scope" section for safe use by scope-locked agents.
- **Shared rules:** `rules.md` is the canonical source for Scope-Locking, Test Execution Policy, Flow Artifacts Exception, and Approval & Confirmation. `memory-conventions.md` is the canonical source for all file paths, naming conventions, and session memory formats. Do NOT duplicate these in other files.
- **Tests:** Agents NEVER execute test commands. They create test files and inform the user of the exact command to run. PRs are never created automatically — the user decides if and when to push branches and open PRs.
- **Scripts:** Bash for install scripts (cross-platform compatible).
- **Documentation:** Markdown, clear language, include examples.
- **AGENTS.md:** For complex projects where you develop or test DevFlow skills, create an `AGENTS.md` in the project root documenting your stack, folder structure, and test conventions. This lets DevFlow skip general codebase exploration and produce more accurate plans. See the README for the suggested format.

### Project Layout

```
DevFlow/
├── .agents/skills/              # AI Sub-agents (Copilot skills)
│   ├── devflow-orchestrator/    # Main orchestrator agent
│   ├── devflow-brainstormer/
│   ├── devflow-architect/
│   ├── devflow-plan/
│   ├── devflow-test/            # Manual helper only (not an automatic phase)
│   ├── devflow-implement/
│   ├── devflow-review/
│   ├── devflow-debug/
│   ├── devflow-finalize/
│   ├── devflow-bug-fix/         # Standalone bug fixing agent
│   ├── devflow-feature/         # Standalone feature agent
│   ├── devflow-refactor/        # Standalone refactoring agent
│   └── shared/                  # Common rules, conventions, and standards
│       ├── rules.md
│       ├── memory-conventions.md
│       ├── output-format.md
│       ├── stack-detection.md
│       └── standards/           # Engineering standards (Private Library)
│           ├── solid.md
│           ├── clean-architecture.md
│           ├── security.md
│           ├── performance.md
│           ├── rest-api.md
│           ├── project-design.md
│           └── ui-design.md
├── .github/
│   ├── prompts/                 # Slash command prompts
│   │   ├── devflow.prompt.md   # Full lifecycle
│   │   └── devflow-*.prompt.md # Phase-specific and standalone
│   └── instructions/
│       └── devflow-conventions.instructions.md
├── docs/
│   ├── ARCHITECTURE.md          # Internal design documentation
│   └── devflow/                 # Persistent artifacts (generated at runtime)
├── editor-profiles/             # Editor-specific installation configs
│   └── vscode.yaml
├── install.sh / install.ps1     # Installation scripts
├── uninstall.sh / uninstall.ps1 # Uninstallation scripts
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

### Extension Ideas

We're looking for contributions in these areas:

#### New AI Agents (Skills)
- 📊 **Performance Profiler** — Analyze code performance
- 📚 **Documentation Generator** — Auto-generate doc from code
- 🔐 **Security Auditor** — Deep security review (OWASP++)
- 🐳 **DevOps Helper** — Docker, K8s, CI/CD setup
- 📈 **Data Science** — ML model training and evaluation

> **Note for new agents:** Follow the pattern of existing standalone agents (`devflow-refactor`, `devflow-feature`, `devflow-bug-fix`). Include a `questions-template.md` for clarifying questions, save the plan/report before asking for user approval, and respect the framework-wide policies: never execute tests, never create PRs automatically, and reference shared rules via `{{SKILLS_DIR}}`.

#### Editor Support

Adding support for a new editor requires **zero** changes to skills, agents, or instructions. DevFlow uses a declarative profile system:

1. **Create `editor-profiles/{editor-id}.yaml`** with:
   - `id`: Unique identifier (e.g., `neovim`, `emacs`)
   - `display_name`: Human-readable name for the installer menu
   - `paths.base`: Directory path where the editor config lives (checked to detect installation)
   - `paths.skills`, `paths.prompts`, etc.: Full paths where artifacts are installed
   - `tool_mappings`: Map tool names (e.g., `vscode_askQuestions` → `fzf` for CLI)
   - `path_mappings`: Editor-specific memory paths (e.g., `memory_root: ~/.config/editor/devflow/session`)
   - `install.tool_substitution`: `true` if sed should transform artifact content, `false` to copy as-is
   
   See [editor-profiles/vscode.yaml](editor-profiles/vscode.yaml) and [editor-profiles/generic.yaml](editor-profiles/generic.yaml) as templates.

2. **(Optional) Add detection in `install.sh`** — The installer automatically:
   - Scans `editor-profiles/*.yaml` at install time
   - Checks if `paths.base` directory exists to detect installed editors
   - Shows installation status in the menu (`[installed]` or `[not detected]`)
   
   For custom detection logic (e.g., registry checks, version constraints), add a function in `install.sh` and invoke it during profile scanning.

3. **Test locally:**
   ```bash
   ./install.sh  # Should list your new editor in the menu
   ```

4. **No other changes needed** — Skills automatically receive the correct tool names and paths at install time via sed substitution.

### Process

1. **Discuss first** — Open an issue or discussion before big changes
2. **Small PRs** — Easier to review, test, merge
3. **Tests & docs** — Include both when possible
4. **Be patient** — Maintainers are volunteers!

### Questions?

Ask on GitHub Discussions or open an issue with a `[question]` label.

---

**All contributions make DevFlow better. Thank you!** 💪