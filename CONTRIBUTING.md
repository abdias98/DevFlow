# Contributing to DevFlow

**DevFlow v2.6.2** — Multi-agent AI framework with multi-editor support via YAML profiles.

Thanks for your interest in contributing to DevFlow! 🎉

## How to Contribute

### Report Issues
Found a bug or have a suggestion? Open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs. actual behavior
- Your OS and VS Code version

### Submit Pull Requests

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Make your changes
4. Test your changes
5. Commit with clear messages: `git commit -m "feat: add X functionality"`
6. Push and create a PR

### Code Style

- **Skills:** Follow existing SKILL.md format (YAML frontmatter + markdown workflow)
- **Prompts:** Keep `.prompt.md` files focused on a single phase
- **Standards:** Engineering standards live in `.agents/skills/shared/standards/` using a strict `DO/DON'T` format with clear reasoning principles. Do not use global editor instructions.
- **Scripts:** Bash for install scripts (cross-platform compatible)
- **Documentation:** Markdown, clear language, include examples
- **AGENTS.md:** For complex projects where you develop or test DevFlow skills, create an `AGENTS.md` in the project root documenting your stack, folder structure, and test conventions. This lets DevFlow skip general codebase exploration and produce more accurate plans. See the README for the suggested format.

### Project Layout

- **`.agents/skills/`**: Agent logic and phase workflows.
- **`.agents/skills/shared/`**: Common logic, memory management, and standards.
- **`.github/prompts/`**: Model behavior definitions for each phase/agent.
- **`editor-profiles/`**: YAML profiles defining editor-specific paths and tool mappings.
- **`docs/`**: Core framework documentation and design specs.

### Extension Ideas

We're looking for contributions in these areas:

#### New AI Agents (Skills)
- 📊 **Performance Profiler** — Analyze code performance
- 📚 **Documentation Generator** — Auto-generate doc from code
- 🔐 **Security Auditor** — Deep security review (OWASP++)
- 🐳 **DevOps Helper** — Docker, K8s, CI/CD setup
- 📈 **Data Science** — ML model training and evaluation

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

---
- GitHub Issues / Discussions
- Jira / Linear / Azure DevOps
- Slack notifications
- GitLab CI

#### Tools
- Batch processing (run on multiple features)
- Performance metrics dashboard
- Historical reports (how we've improved over time)

### Process

1. **Discuss first** — Open an issue or discussion before big changes
2. **Small PRs** — Easier to review, test, merge
3. **Tests & docs** — Include both when possible
4. **Be patient** — Maintainers are volunteers!

### Questions?

Ask on GitHub Discussions or open an issue with a `[question]` label.

---

**All contributions make DevFlow better. Thank you!** 💪
