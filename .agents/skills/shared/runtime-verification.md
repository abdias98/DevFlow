# Runtime Verification — Canonical Pattern

> **Framework-centric principle:** `runtime` is a **primitive that the framework invokes when the environment supports it** (see [environment-probe.md](./environment-probe.md)), not a capability that depends on a specific model. The framework decides when to execute a Feature-Level Scenario against the system it just built; if the editor can start and drive that system (CLI invocation, a server process, an automatable browser), it does; if not, it falls back to a code-only trace of the same scenario.

Every prior verification layer (Reviewer's blind/contrast pass, the Verifier's behavior-paths axis, Visual Diff) reads code and reasons about what it should do. None of them presses the button. This document defines the pattern for actually running a [Feature-Level Scenario](./behavior-scenarios.md) against the running system and observing what happens — the same gap Visual Diff closed for appearance, this closes for behavior.

---

## When to Use Runtime Verification

**Use runtime verification when ALL of these hold:**
- The environment capability probe detected `runtime: yes` (see [environment-probe.md](./environment-probe.md)).
- The change has at least one Feature-Level Scenario ([behavior-scenarios.md](./behavior-scenarios.md)) that involves an externally observable sequence (a CLI invocation, an HTTP request, a UI interaction) — not a pure internal-unit scenario already fully exercised by a fast unit test.
- The system can be started or driven without a cost the cycle isn't already paying (no external paid services, no destructive action against shared infrastructure).

**Do NOT use runtime verification when:**
- `runtime: no` or `unknown` — fall back to the code-only trace below.
- The scenario is adequately covered by a unit/integration test already run in Phase 5/6, and driving the live system would only re-exercise the same path with more overhead and no new signal.
- Running it would require standing up infrastructure or state the project doesn't already have a safe way to provision (a production database, a paid third-party API) — do not fabricate one for the sake of the check.

---

## The Pattern

### 1. Reviewer Runtime Step (Phase 6, optional, after Visual Diff)

For a change with externally observable Feature-Level Scenarios, the Reviewer adds a **runtime verification** sub-step after Visual Diff (or immediately after synthesis, if the feature has no UI). Dispatched when `runtime: yes` is in `context.md` → `## Environment Capabilities`.

**Active by default only at `deep`/`maximum` rigor** (mirrors Visual Diff's rigor gating — see [adaptive-skills.md](./adaptive-skills.md) → Verification Layers by Rigor). At `light`/`standard` rigor it is available on request but not run automatically — driving a live system on every trivial change is overhead the rigor tables already decided against.

**Procedure:**
1. **Select the scenario(s)** — the Feature-Level Scenarios from the plan that describe an externally observable sequence (not already fully pinned down by a fast unit test).
2. **Start or reach the running system** — using whatever the project already provides: the project's own dev-server/run command, its test-CLI entry point, or an automatable browser against a locally-served UI. Never provision new infrastructure for this step alone.
3. **Execute the scenario's sequence** exactly as written in the plan (the same precondition → action sequence → expected outcome the plan already committed to).
4. **Observe**, correlating against the scenario's expected outcome:
   - Process/command output and exit code.
   - Server logs and application logs.
   - Console output (browser or process).
   - Network/traffic observed during the sequence (requests made, responses received, retries, timing).
5. **Compare observed vs. expected.** A divergence is a finding with a reproducible scenario — precondition, sequence, observed (with the concrete output/log/trace line), expected (citing the plan's Feature-Level Scenario) — per [rules.md → Finding Evidence](./rules.md). Severity from **Behavioral Impact Severity**, same as any other scenario-backed finding; a runtime-observed divergence is never weaker evidence than one reasoned from code, since it is the more direct kind of evidence.

**Output format:**
```markdown
### Runtime Verification Findings

**Scenario executed:** {Feature-Level Scenario name/ref from the plan}
**Environment:** {command/server/browser used to drive it}

| # | Severity | Scenario | Observed | Expected |
|---|----------|----------|----------|----------|
| 1 | BLOCK | Re-select client while a fetch is in flight | Stale response overwrote the new client's data (console log shows both responses land, older one applied last) | New client's data only (plan §Feature-Level Scenarios, row 3) |
| 2 | INFO | Duplicate submit within the debounce window | Second request never fired | Matches plan expectation |
```

### 2. Standalone Agents (`standalone-execution.md`)

The same optional step applies to a standalone agent's own Step 6/7 verification when the agent is running at `deep`/`maximum` rigor and `runtime: yes`. A standalone agent without a dedicated Reviewer phase runs the runtime check itself, using the same procedure, before reporting the feature as ready for review.

---

## Fallback: Code-Only Trace (No Runtime)

When `runtime: no` or `unknown` in `context.md` → `## Environment Capabilities`:

- **Reviewer:** no runtime verification sub-step. The Correctness & Behavior dimension's contrast pass already traces each Feature-Level Scenario against the code (not the running system) — that trace is what stands in for execution. Record in `## Coverage`: "Runtime verification skipped — no runtime capability available. Behavior traced against code only (see Correctness & Behavior contrast pass)."
- **Standalone agents:** same fallback — the code-only contrast trace is the verification; no separate note is needed beyond what the review/report already records.

The cycle never breaks — it just loses the executed-behavior confirmation, same as it loses the rendered-appearance confirmation without vision.

---

## Anti-Patterns

- ❌ **Assume runtime is available** — always check `context.md` → `## Environment Capabilities` before attempting to start or drive the system. If `runtime: no`, use the code-only fallback.
- ❌ **Run it at `light`/`standard` rigor by default** — the rigor tables already balance verification depth against overhead; runtime verification follows that balance, not its own schedule.
- ❌ **Provision new infrastructure or use paid/external services just to run this step** — if the scenario can't be driven with what the project already has locally, fall back to the code-only trace instead of reaching outside the cycle's normal footprint.
- ❌ **Re-run a scenario already pinned down by a fast unit test with no new signal to gain** — runtime verification earns its cost on externally observable sequences a unit test can't fully exercise (timing, real network round-trips, real process boundaries), not on everything.
- ❌ **Treat a runtime-observed divergence as optional or advisory** — it is a reproducible scenario like any other; it gets Behavioral Impact Severity and counts toward the verdict, it is not merely descriptive.

---

## Agents That Apply This Pattern

| Agent | Application | Condition |
|-------|--------------|-----------|
| **Reviewer** (Phase 6) | Runtime verification sub-step after Visual Diff | `runtime: yes` AND an externally observable Feature-Level Scenario exists AND rigor is `deep`/`maximum` (available on request otherwise) |
| **Standalone agents** | Same sub-step in their own Step 6/7 verification | `runtime: yes` AND rigor `deep`/`maximum` |

See each agent's SKILL.md for the specific step where runtime verification is integrated.
