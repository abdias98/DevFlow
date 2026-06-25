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
eval/bin/devflow-eval score <task-id|task-dir> <result-dir>
```

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

## Tests

The engine is itself covered by `tests/devflow-eval.bats` (run `npm test`). It
holds the eval harness to the same dogfooding standard as `devflow-ctl`: a tool
that measures quality must be measured itself.
