# DevFlow Engineering Standards: Testing (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-06-10

> **Note on examples:** All tool names, directory names, and code fragments are illustrative. Replace them with the actual test runner, utilities, and conventions of the detected stack.

Apply these principles to all tests you design, generate, or review. TDD is non-negotiable in DevFlow — this standard defines what "good tests" means.

## 1. Test Pyramid

- **What:** The ratio of test types determines the speed and reliability of your test suite.
- **DO:**
  - Maintain a pyramid: many unit tests at the base, fewer integration tests in the middle, minimal E2E tests at the top.
  - Aim for unit tests to cover the majority of logic, integration tests to verify boundaries, and E2E tests to validate the critical user journey only.
  - Make unit tests the default. Reach for integration tests when verifying I/O boundaries (DB, HTTP, file system). Use E2E tests sparingly — they are slow and brittle.
- **DON'T:**
  - Invert the pyramid (many E2E, few unit tests) — it produces a slow, brittle, and expensive suite.
  - Skip unit tests in favor of integration tests "because they test more" — integration tests are slower and harder to isolate failures.
  - Write tests that depend on the order in which they run. Each test must be fully independent.

## 2. Test Anatomy — Arrange / Act / Assert

- **What:** Every test must have a clear, three-part structure.
- **DO:**
  - **Arrange:** Set up inputs, dependencies, and state. Use factories or builders for complex objects.
  - **Act:** Call the single unit under test. One action per test.
  - **Assert:** Verify the exact outcome expected. One logical assertion per test (multiple `.assert` calls on the same subject are fine; multiple unrelated assertions are not).
  - Name tests as: `{subject} — {scenario} — {expected outcome}`. Example: `createOrder — when stock is zero — should throw OutOfStockError`.
- **DON'T:**
  - Write tests that do many things ("test the whole flow in one test") — they produce unreadable failure messages.
  - Assert on implementation details (private methods, internal state, specific call counts unless required by the contract).
  - Use production data in tests. Generate realistic fake data with factories or fixtures.

## 3. What to Mock and What Not to

- **What:** Over-mocking produces tests that pass but do not verify real behavior.
- **DO:**
  - Mock external I/O: network calls, database queries, file system, time (`Date.now()`, `clock`), randomness.
  - Mock at the port/interface boundary (the abstraction defined in the application layer) — never mock a concrete implementation directly.
  - Prefer test doubles (fakes, stubs) over full mock libraries for simple cases — a fake repository that stores data in memory is more reliable than a mock with fragile expectations.
- **DON'T:**
  - Mock domain logic — test it directly with unit tests. If domain logic is hard to test without mocking, it is a design problem (missing abstraction, hidden dependency).
  - Mock everything by default. If you can use a real, fast, in-memory alternative (SQLite, in-process HTTP client, in-memory cache), prefer it.
  - Mock the unit under test itself. You are testing the unit — mocking it defeats the purpose.

## 4. Test Coverage

- **What:** Coverage is a lagging indicator — high coverage does not guarantee correctness.
- **DO:**
  - Require tests for every happy path, at least one edge case, and at least one failure/error scenario (as defined in DevFlow's plan template).
  - Use coverage as a floor, not a target. A test that merely executes a line without asserting anything is worse than no test.
  - Prioritize coverage of: domain logic, use cases, error paths, and boundary conditions.
  - Track coverage trends over time. A drop in coverage on a new feature signals missing tests.
- **DON'T:**
  - Chase 100% coverage mechanically — trivial getters, generated code, and framework boilerplate do not need tests.
  - Write assertions that always pass (e.g., `assert true === true`) to inflate coverage.
  - Remove tests to fix a failing suite — fix the code or the test, never delete the signal.

## 5. Regression Tests

- **What:** A regression test proves a bug is fixed and cannot silently return.
- **DO:**
  - Write a failing reproduction test BEFORE applying any fix (Red → Green).
  - The reproduction test must fail with the original bug present and pass only after the fix.
  - Name it explicitly: `{subject} — regression — {bug description or ticket ID}`.
  - Keep regression tests in the suite permanently — they document history and prevent re-introduction.
- **DON'T:**
  - Fix a bug without a regression test. Without it, the bug will return.
  - Write a regression test after the fact from memory — the test may not actually catch the original defect.

## 6. Test Independence & Isolation

- **What:** Tests that depend on each other or on shared state are unreliable.
- **DO:**
  - Reset state between tests: use `beforeEach`/`setUp`/`teardown` to restore a clean baseline.
  - Use transactions that roll back, or in-memory stores that reset, for database-backed tests.
  - Run tests in parallel safely — no shared mutable state, no reliance on execution order.
  - Use unique identifiers (UUIDs, random names) in integration tests to avoid collisions.
- **DON'T:**
  - Rely on test execution order. Randomize order periodically to surface hidden dependencies.
  - Share test fixtures across unrelated test files without explicit reset.
  - Allow a test to leave side effects (created files, DB records, running processes) that affect other tests.

## 7. Test Naming & Organization

- **What:** A failing test should communicate the problem without reading the code.
- **DO:**
  - Group tests by the unit they test (one test file per production file is a sensible default).
  - Use descriptive names: `should throw OutOfStockError when quantity exceeds available stock` over `test_1`.
  - Use nested `describe`/`context` blocks to group scenarios for the same subject.
  - Place tests in a mirror structure of the source: `src/orders/create-order.ts` → `tests/orders/create-order.test.ts`.
- **DON'T:**
  - Name tests after implementation details (`test_callsRepositorySave`) — name them after behavior.
  - Put multiple unrelated subjects in the same test file.
  - Use numbered test names (`test_1`, `test_2`) that require reading the code to understand.

## 8. Test Performance

- **What:** A slow test suite gets skipped.
- **DO:**
  - Keep the unit test suite under 30 seconds for a typical project.
  - Use in-memory alternatives to slow resources (in-memory DB, local file stubs) for unit and integration tests.
  - Tag slow tests (E2E, load tests) and run them separately in CI, not on every commit.
  - Parallelize independent test suites.
- **DON'T:**
  - Add real `sleep`/`delay` calls in tests. Control time with a mock clock.
  - Run E2E tests on every push — gate them on a pre-release or nightly pipeline.

## 9. Code Review Checklist
When reviewing tests, verify:
- [ ] Each test has a clear Arrange / Act / Assert structure.
- [ ] Test names describe the scenario and expected outcome without reading the code.
- [ ] Happy path, at least one edge case, and at least one error scenario are covered per feature.
- [ ] Mocks are at port/interface boundaries, not on concrete classes or the unit under test.
- [ ] Tests are independent — no shared mutable state, no execution-order dependency.
- [ ] Regression tests exist for any bug fix (fail before fix, pass after).
- [ ] No `sleep`/`delay` in tests; time is controlled via mock clock.
- [ ] Coverage is meaningful — assertions actually verify behavior, not just execute lines.

## 10. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `testing.md §5`).

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | Bug fix applied with no regression test (§5); test asserts on nothing — always passes regardless of code behavior (§4); test file missing for a new feature that modifies domain logic (§4) |
| 🟡 **WARN** | Test verifies implementation details instead of behavior (§2); multiple unrelated assertions in one test producing unreadable failures (§2); test relies on execution order — fails when run in isolation (§6); real `sleep`/`delay` in test body (§8); no edge case or error scenario covered for a feature (§4) |
| 🟢 **INFO** | Test name does not describe the scenario clearly (§7); test file not mirroring source structure (§7); in-memory alternative available but not used (test is slow but not blocking) (§8) |

## 11. Applying This Standard with a Limited Scope

When reviewing or adding tests to a **specific set of files**, follow these constraints:

1. **Only create test files within the approved scope.** If existing tests for out-of-scope code are broken, flag them as INFO notes rather than modifying them.
2. **Regression tests are always within scope** for any bug fix — they are a required deliverable, not an optional extra.
3. **If a test requires a factory or fixture that lives outside scope**, use the existing one (read-only) or create an inline minimal version within the test file. Do not modify shared test utilities unless they are in scope.
4. **Coverage tooling:** Do not modify coverage configuration files unless they are explicitly in scope.
