# Standards Changelog

Version history for all DevFlow engineering standards. Each standard's current version is declared in its file header.

---

## 2.1.0 — 2026-05-22

### ui-design — 2.1.0
- Comprehensive expansion: 108 → 348 lines
- Added detailed design principles, interaction patterns, and trade-off analysis
- Enhanced checklist with accessibility and responsive design criteria

---

## 2.0.0 — 2026-04-29

### All standards — 2.0.0
Complete technology-agnostic rewrite across all 7 standards:

- **solid:** Generic pseudo-code examples, SOLID interactions & tensions, code review checklist, limited scope section
- **clean-architecture:** Technology-agnostic examples, dependency rule clarified, limited scope section
- **security:** Transport security, data protection at rest, rate limiting added, checklist, limited scope section
- **performance:** Async/resource/caching interactions, checklist, limited scope section
- **rest-api:** Idempotency, documentation, security & safety, checklist, limited scope section
- **project-design:** Architecture Spec documentation, checklist, limited scope section
- **ui-design:** Interactions & trade-offs, checklist, limited scope section

---

## 1.0.0 — 2026-04-20

### Initial release
- 7 standards created: SOLID, Clean Architecture, Security, Performance, REST API, Project Design, UI Design
- Strict DO/DON'T format
- Private Library approach: standards loaded exclusively by DevFlow agents
- Original technology-specific examples (later rewritten in 2.0.0)

---

## Version Policy

- **Major (X.0.0):** Breaking changes to standard rules or structure
- **Minor (X.Y.0):** New sections, expanded coverage, significant additions
- **Patch (X.Y.Z):** Clarifications, typo fixes, non-semantic adjustments
- Each standard may version independently when only one standard changes.
- All standards share a major version bump when a framework-wide rewrite occurs.
