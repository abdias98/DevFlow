# DevFlow Eval Harness

The framework ships many waves of scaffolding. This directory answers the only
question that justifies any of it:

> Does a feature built with `/devflow` come out **measurably better** than one
> built with a bare prompt to the same model — and did the latest wave improve
> outcomes, or just add cost?

Without this, every wave is a bet on intuition. The eval harness turns "I think
it's better" into a number you can regress against.

## What it is (and isn't)

- It **does not run the model.** It scores the *result* of a run.
- A **golden task** declares the prompt plus weighted, executable checks — the
  Definition of Done expressed as assertions a script can verify.
- The **engine** (`bin/devflow-eval`) runs those checks against a result
  workspace and emits a scorecard (markdown) + `scorecard.json`.

## The measurement loop

```
1. Pick a golden task            eval/tasks/001-cli-json-flag/
   (tasks with a fixture/: seed both workspaces first)
     devflow-eval init 003-order-payment-lifecycle /path/to/workspace-A
     devflow-eval init 003-order-payment-lifecycle /path/to/workspace-B
2. Run it through /devflow        → produces workspace A (code + docs/devflow/ artifacts)
3. Run the SAME prompt bare        → produces workspace B (code only)
4. Score both:
     devflow-eval score 001-cli-json-flag /path/to/workspace-A
     devflow-eval score 001-cli-json-flag /path/to/workspace-B
5. Compare the two scorecards.
```

## Outcome vs process — and why pass/fail ignores paperwork

Checks fall into two buckets, scored **separately** so they never blend into a
misleading single number:

- **`check`** / **`check_outcome`** — does the deliverable actually work? (the
  endpoint responds, tests pass). Framework-agnostic; both runs are judged here.
- **`check_process`** — did the run produce DevFlow artifacts (spec, plan,
  review)? Only a `/devflow` run earns these.

**Pass/fail is decided by `outcome` alone.** Process is reported but never
gates. This is deliberate: if two runs ship an identical deliverable, the
framework must not "win" the verdict on paperwork — and a `/devflow` run with a
broken deliverable must not pass just because it wrote a spec. The scorecard
shows `Outcome`, `Process`, and a blended `Score` (reference only), e.g.:

```
Outcome: 13/13 = 100%   ← decides pass/fail
Process:  2/2  = 100%   ← /devflow earned its artifacts
Score:   15/15 = 100%   (blended, for reference)
```

If the same task scores `Outcome 100%` on both the `/devflow` and the bare run,
that is the honest signal that **on this task the framework added documentation,
not a better outcome** — exactly the conflation this split exists to expose.
Look for value where process can change the outcome (security, ambiguity,
multi-run reliability), not on first-shot-correct routine tasks.

Run the same task across DevFlow versions (or models) and watch the **outcome**
percentage. A wave that doesn't move it is cost without benefit.

## Usage

```bash
eval/bin/devflow-eval list
eval/bin/devflow-eval init  <task-id|task-dir> <dest-dir> [--reference <name>]
eval/bin/devflow-eval score <task-id|task-dir> <result-dir>
```

`init` seeds an empty workspace from the task's `fixture/`. `--reference <name>`
overlays `reference/<name>/` on top — used to calibrate a task, never for a run
under evaluation.

Exit code: `0` if the score meets the task's `threshold`, `1` if below, `2` on
usage error — so it drops straight into CI.

## Writing a golden task

A task is a directory under `tasks/` with two files:

- `task.md` — header (`id`, `title`, `complexity`, `category`, `threshold`) plus
  the prompt and human-readable Definition of Done.
- `checks.sh` — the executable rubric. Each line is:

  ```bash
  check <weight> "<description>" <command...>
  ```

  The command runs with the working directory set to the result workspace; exit
  `0` earns the weight. Two helpers are available inside `checks.sh`:

  - `devflow_artifact spec|plan|review|validation|summary` — passes if that
    DevFlow artifact was produced.
  - `file_matches <path> <ere>` — passes if the file exists and matches the regex.

  Project-specific entrypoints (CLI command, serve command, port) are read from
  environment variables at the top of each `checks.sh` — override them for the
  target project before scoring.

### Optional task files

- `fixture/` — the starting project the run modifies. Required for any task whose
  checks depend on a known codebase (every behavioural task).
- `reference/<name>/` — known implementations overlaid on the fixture to prove
  the checks discriminate. A behavioural task ships at least `naive/` (misses a
  defect class) and `correct/`.
- Probe scripts (e.g. `probe.js`) — kept **next to `checks.sh`, outside the
  workspace**, so the run under evaluation can neither read nor edit them.
  `checks.sh` locates them with `"$(dirname "${BASH_SOURCE[0]}")"`.

## Behavioural tasks

Tasks `001` and `002` are first-shot-correct routine work: a capable model
passes them bare, so they measure cost more than benefit. Behavioural tasks
(`category: behavior`) measure what a verification process exists to catch —
defects the prompt **implies** but does not spell out:

| Task | Defect classes probed |
|------|-----------------------|
| `003-order-payment-lifecycle` | repetition, invalid transitions, partial failure, concurrency, data limits |
| `004-project-panel-tab` | side effects, transitions on selection change, out-of-order responses, partial failure; propagating a flaw from the convention it was told to follow |

Rules for writing one:

1. **The prompt states a normal functional requirement.** It never names the
   scenarios the checks probe — the task measures whether the run discovers
   them. Each `task.md` has a *What the checks probe* section for maintainers;
   do not paste it into the run.
2. **Every probed behaviour must follow from the requirement or from existing
   code in the fixture** — a documented convention, an existing module's
   behaviour. A check for something neither implies is a trick, not a measure.
3. **Negative checks are gated on the happy path** ("X is rejected" passes
   vacuously when X does not exist at all).
4. **Calibrate:** fixture and `naive` must FAIL, `correct` must PASS, and `naive`
   must fail on the check it was written to miss. `tests/devflow-eval.bats`
   asserts all three for every behavioural task.
5. **Threshold 90:** missing any behavioural class weighted ≥ 2 fails the task.

## Baselines

`baselines/<version>.md` records calibration and scorecards for a DevFlow
version. Take one before a wave that changes verification and again after its
release — a wave that does not move the behavioural outcome is cost without
benefit (`docs/implementation-plan-waves-18-21.md` §8).

`baselines/runs/<version>/` holds the actual artifacts (plan, feature report,
review, `scorecard.json`) a recorded run produced, so a scorecard number in
the version's `.md` file can be traced back to what the run actually wrote —
not only the workspace's final code, which the scorecard already captures.

## Tests

The engine is itself covered by `tests/devflow-eval.bats` (run `npm test`). It
holds the eval harness to the same dogfooding standard as `devflow-ctl`: a tool
that measures quality must be measured itself.
