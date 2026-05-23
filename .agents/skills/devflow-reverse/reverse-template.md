# Reverse Engineering Report Template

The reverse engineering report saved to `docs/devflow/reverse/YYYY-MM-DD-{slug}-reverse.md` MUST include these sections:

## Required Sections

### Project Overview
- **Project Name:** {detected from package manifest or directory structure}
- **Language(s):** {primary language + secondary if applicable}
- **Framework(s):** {primary framework + secondary if applicable}
- **Architectural Style:** {MVC | Clean Architecture | Hexagonal | Layered | Microservices | Other}
- **Repository Size:** {file count, line count if available}
- **Date Analyzed:** YYYY-MM-DD
- **Mode:** {Quick | Full | Deep}

### Generated Artifacts

| Artifact | Path | Generated? |
|----------|------|------------|
| AGENTS.md | {project root}/AGENTS.md | ✅ / ❌ (reason if not) |
| Stack Profile | docs/devflow/reverse/YYYY-MM-DD-{slug}-stack-profile.md | ✅ / ❌ |
| Architecture Spec | docs/devflow/reverse/YYYY-MM-DD-{slug}-architecture.md | ✅ / N/A (Quick mode) |
| Project Template | docs/devflow/reverse/YYYY-MM-DD-{slug}-template.md | ✅ / N/A (Quick mode) |
| Tech Debt Report | docs/devflow/reverse/YYYY-MM-DD-{slug}-tech-debt.md | ✅ / N/A (non-Deep) |
| Vulnerability Audit | docs/devflow/reverse/YYYY-MM-DD-{slug}-vulnerabilities.md | ✅ / N/A (non-Deep) |

### Architecture Discovered

#### Directory Structure
```
project-root/
├── src/                    # Source code
│   ├── controllers/        # HTTP request handlers
│   ├── services/           # Business logic
│   ├── models/             # Data models / entities
│   ├── routes/             # Route definitions
│   └── middleware/         # Request pipeline
├── tests/                  # Test suite
├── config/                 # Configuration files
├── docs/                   # Documentation
└── package.json            # Project manifest
```
*Note: This structure must reflect the actual project, not a template.*

#### Component Map

| Component | Type | Path | Responsibilities | Dependencies |
|-----------|------|------|------------------|-------------|
| {name} | {Controller | Service | Model | Middleware | Provider | Utility} | {file path} | {summary} | {what it depends on} |

#### Data Flow
Describe the typical request lifecycle from entry point to response/result. Cite source files for each step.

```
HTTP Request → Router ({routes file}) → Middleware Chain ({middleware files}) → Controller → Service → Repository/Model → Database → Response
```

### API Endpoints *(Full + Deep only)*

| Method | Path | Auth | Controller | Request Shape | Response Shape | Source |
|--------|------|------|------------|--------------|----------------|--------|
| GET | /api/v1/resource | JWT | ResourceController@index | Query params | JSON array | routes/api.ts:12 |

Group by resource or domain. Note any inconsistencies between endpoints (e.g., mixed auth, inconsistent error formats).

### Dependency Analysis *(Full + Deep only)*

#### Dependency Map

| Package | Version | Category | Used? | Notes |
|---------|---------|----------|-------|-------|
| {name} | {version} | {framework | database | auth | testing | utility | dev} | ✅ / ❌ / ⚠️ Implicit | {notes} |

#### Unused Dependencies
Dependencies listed in manifest but never imported:
- `{package}:{version}` — not referenced in any source file.

#### Implicit Dependencies
Dependencies used in code but not listed in manifest:
- `{package}` — imported in `{file}:{line}` but absent from `{manifest}`.

### Tech Debt *(Deep only)*

#### Debt Inventory

| ID | Type | Severity | Location | Description | Remediation |
|----|------|----------|----------|-------------|-------------|
| TD-{N} | {TODO | Deprecation | Duplication | Missing Tests | Hardcoded | Large File | N+1 | Missing Error Handling | Outdated Dep} | 🔴 HIGH / 🟡 MEDIUM / 🟢 LOW | {file}:{line} | {description} | {how to fix} |

#### Vulnerability Findings *(Deep only)*

| ID | OWASP Category | Severity | Location | Description | Remediation |
|----|---------------|----------|----------|-------------|-------------|
| VULN-{N} | {Injection | Broken Auth | Sensitive Data | XXE | Broken Access Control | Misconfiguration | XSS | Deserialization | Known CVE | Insufficient Logging} | 🔴 CRITICAL / 🔴 HIGH / 🟡 MEDIUM / 🟢 LOW | {file}:{line} | {description with CVE reference if applicable} | {how to fix} |

### Stack Profile

| Key | Value | Source |
|-----|-------|--------|
| Language | {language} | {file}:{line} |
| Runtime | {runtime} | {file}:{line} |
| Package Manager | {npm | yarn | composer | cargo | go mod | pip | bundler | maven | gradle} | {file}:{line} |
| Framework | {framework} | {file}:{line} |
| Test Runner | {jest | phpunit | pytest | go test | rspec | etc.} | {file}:{line} |
| Test Command | {command} | {file}:{line} |
| Lint Command | {command} | {file}:{line} |
| Source Root | {directory} | {observation} |
| Test Root | {directory} | {observation} |
| Database | {postgresql | mysql | mongodb | sqlite | etc.} | {file}:{line} |
| Cache | {redis | memcached | none} | {file}:{line} |
| Queue | {rabbitmq | sqs | redis | none} | {file}:{line} |

### Known Unknowns

| Category | Question | Evidence Searched | Best Guess |
|----------|----------|-------------------|------------|
| {Deployment | Auth | Database Schema | External Services | etc.} | {what couldn't be determined} | {files checked} | {educated guess with confidence level} |

Every item here is something that could not be confirmed by code inspection alone. Mark confidence as: High / Medium / Low.

### Next Steps

1. **Quick Wins:** {1-3 immediate actions the team can take}
2. **Recommended Investigation:** {areas that need deeper exploration}
3. **Suggested DevFlow Cycles:** {features or improvements that should go through the full DevFlow cycle}
4. **Standalone Agent Candidates:** {bugs, refactors, or small features that can be handled by standalone agents}
