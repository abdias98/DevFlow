# Reference Template: Library / SDK

> **This is a reference guide, not a rigid spec.** Adapt to the language's package convention (npm, PyPI, crates.io, NuGet). Focus: public API surface, versioning, tree-shaking, bundle size. Priority: AGENTS.md → project template → exploration → this reference.

## Typical Structure

```
src/
├── index.js          # Public API surface: only what consumers import
├── core/             # Core functionality, algorithms, data structures
├── adapters/         # Platform-specific implementations, polyfills
├── types/            # TypeScript/JSDoc type definitions
├── utils/            # Internal utilities (NOT exported)
└── __tests__/        # Tests mirror source structure

dist/                 # Built output (not committed for npm packages)
```

## Design Principles

| Principle | Why |
|-----------|-----|
| **Minimal public API** | Export only what's needed. Hide internals. Every export is a commitment. |
| **Semantic Versioning** | MAJOR.MINOR.PATCH. Breaking changes = MAJOR bump. |
| **Tree-shakeable** | Named exports + ES modules. Consumers only bundle what they use. |
| **Zero dependencies** | Minimize external deps. Each dep adds security risk + bundle weight. |
| **Platform-agnostic core** | Core logic works everywhere. Platform specifics in adapters/. |
| **Backward compatible** | Deprecate before removing. Support old API for at least one MAJOR version. |

## Public API Patterns

| Pattern | Example |
|---------|---------|
| **Factory function** | `createClient(config)` returns configured instance |
| **Options object** | Single config object instead of many positional args |
| **Method chaining** | `client.configure().connect().query()` for fluent APIs |
| **Event emitters** | `client.on('error', handler)` for async notifications |
| **Async/Promise** | All I/O operations return Promises (or language equivalent) |
| **Error hierarchy** | Custom error classes: `LibraryError`, `NetworkError`, `ValidationError` |

## Common Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Exporting internals | Only export what's in the public contract |
| Breaking changes in minor | Follow semver strictly |
| Synchronous I/O | All network/disk operations must be async |
| Global state | Everything should be instance-scoped, not module-scoped |
| No TypeScript/types | Provide `.d.ts` files or include types in package |
| Missing JSDoc | Every public function must have JSDoc with example |
| Giant bundle | Check bundle size on every PR. Set a budget. |

## Test Architecture

| What | How |
|------|-----|
| Public API | Test every exported function with documented inputs |
| Edge cases | Boundary values, empty inputs, large inputs, concurrent calls |
| Error handling | Test every error path. Verify error types and messages. |
| Backward compatibility | Test against previous MAJOR version's API |
| Performance | Benchmark critical paths. Set performance budgets. |
