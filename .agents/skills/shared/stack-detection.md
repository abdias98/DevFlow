# Quick Stack Detection

Use this procedure when `## Stack Profile` is absent from session memory (`context.md`). This happens when a standalone agent is invoked without a prior DevFlow cycle.

**Goal:** Populate `## Stack Profile` in `context.md` by inspecting the workspace.

---

## Detection Order

### Step 0 — Detect Monorepo (run first)

Check for monorepo workspace configuration. If ANY of these files exist, the project is a monorepo:

| File | Monorepo Tool |
|------|---------------|
| `nx.json` | Nx |
| `turbo.json` | Turborepo |
| `lerna.json` | Lerna |
| `pnpm-workspace.yaml` | pnpm workspaces |
| `rush.json` | Rush |
| `package.json` with `workspaces` field | yarn/npm workspaces |

If monorepo detected:
- Record the monorepo tool and package manager in `## Stack Profiles`.
- Run Steps 1–6 for **each package** in the workspace that is relevant to the feature.
- Use the `## Stack Profiles` format (not single `## Stack Profile`).

If NOT a monorepo: proceed to Step 1 (standard detection).

### Step 1 — Check AGENTS.md first

Search for `AGENTS.md` in the workspace root and `docs/AGENTS.md`. If found:
- Extract: Tech Stack, Test runner, Test run commands, folder structure, and any tooling info.
- Use these values to fill the Stack Profile.
- Skip detection for any field already covered.

### Step 2 — Detect Language and Package Manager

Read the following files (whichever exist) to determine the primary language and package manager:

| File found | Language | Package Manager |
|------------|----------|----------------|
| `package.json` | JavaScript / TypeScript | Detect from lockfiles: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm |
| `pyproject.toml` or `setup.cfg` or `requirements.txt` | Python | Detect: `pyproject.toml` with `[tool.poetry]` → poetry, else pip |
| `go.mod` | Go | go mod |
| `*.csproj` or `*.sln` | C# | nuget / dotnet |
| `pom.xml` | Java | Maven |
| `build.gradle` or `build.gradle.kts` | Java / Kotlin | Gradle |
| `composer.json` | PHP | Composer |
| `Gemfile` | Ruby | Bundler |
| `Cargo.toml` | Rust | Cargo |
| `pubspec.yaml` | Dart / Flutter | pub |

> If multiple files exist, identify the **primary** language from the project root and main source folder.

### Step 3 — Detect Framework

Read the primary config file and inspect dependencies/imports:

- **package.json** → check `dependencies` and `devDependencies` for: `next`, `react`, `vue`, `nuxt`, `angular`, `svelte`, `express`, `fastify`, `nest`, etc.
- **pyproject.toml / requirements.txt** → look for: `django`, `fastapi`, `flask`, `starlette`.
- ***.csproj** → look for: `Microsoft.AspNetCore`, `Blazor`.
- **pom.xml / build.gradle** → look for: `spring-boot`, `quarkus`, `micronaut`.
- **composer.json** → look for: `laravel/framework`, `symfony/symfony`.

### Step 4 — Detect Test Runner and Commands

Read config files for test runner configuration:

| Stack | Where to look | What to extract |
|-------|---------------|----------------|
| JavaScript / TypeScript | `package.json` → `scripts.test` | Full command (e.g., `vitest run`, `jest --runInBand`) |
| JavaScript / TypeScript | `jest.config.*`, `vitest.config.*` | Confirms runner |
| Python | `pyproject.toml` → `[tool.pytest]` or `setup.cfg` | `pytest` or `python -m pytest` |
| Go | `go.mod` | `go test ./...` |
| C# | `*.csproj`, `*.sln` | `dotnet test` |
| Java (Maven) | `pom.xml` | `mvn test` |
| Java / Kotlin (Gradle) | `build.gradle` | `./gradlew test` |
| PHP | `phpunit.xml` or `composer.json` → `scripts.test` | `./vendor/bin/phpunit` |
| Ruby | `Gemfile` | `bundle exec rspec` |

**Single-file test command** — derive from the runner:
- Jest: `npx jest {file}`
- Vitest: `npx vitest run {file}`
- pytest: `pytest {file}`
- go test: `go test {package}`
- dotnet: `dotnet test --filter {TestName}`
- RSpec: `bundle exec rspec {file}`

### Step 5 — Detect Source and Test Roots

- **Source Root:** Look for `src/`, `app/`, `lib/`, `cmd/`, or the folder with the most source files.
- **Test Root:** Look for `tests/`, `test/`, `__tests__/`, `spec/`. Check test runner config for configured paths.
- **Test Utilities:** Look inside the test root for: `factories/`, `fixtures/`, `helpers/`, `mocks/`, `support/`.

### Step 6 — Detect Build, Lint, and Watch Commands

- **Build:** `package.json` → `scripts.build`; `go build ./...`; `dotnet build`; `mvn package`.
- **Lint:** `package.json` → `scripts.lint`; check for `.eslintrc*`, `flake8`, `golangci-lint`, etc.
- **Watch:** `package.json` → `scripts.dev` or `scripts.start`; look for `nodemon`, `air` (Go), `python manage.py runserver`, framework-specific dev servers (Next.js `next dev`, Vite `vite`). If no watch command found, leave empty or derive from the framework (e.g., Django → `python manage.py runserver`).

### Step 7 — Write Stack Profile to context.md

**For single-project workspaces:** Merge the detected values into the `## Stack Profile` table in `context.md`.

**For monorepos:** Use `## Stack Profiles` format. Create one profile entry per affected package. Each entry must have: package path, Language, Framework, Test Command, Test Command (single file), Source Root, Test Root. Common workspace-level config (Package Manager, Monorepo Tool, Lint Command, Build Command) goes under `### Workspace root`.

**NEVER overwrite** fields that were already populated by a prior Architect cycle. Merge incrementally.

---

## Fallback

If any field cannot be auto-detected, set its value to `unknown` and add a note:
```
| **Test Command** | unknown — ask user |
```
Then inform the user: "I could not detect the test command automatically. Please provide it."

---

## Rules

- **NEVER hardcode** a test runner or command. Always derive it from the project files.
- **NEVER assume** a stack without reading at least one config file.
- **ALWAYS prefer** the value from `AGENTS.md` if it exists.
- **Monorepo:** When multiple packages coexist, detect ALL stacks relevant to the feature. Use `## Stack Profiles` format. Never arbitrarily pick a "primary" — record all affected packages.
