# Checks for 001-cli-json-flag. CWD is the result workspace.
# Each `check <weight> "<desc>" <cmd...>` earns its weight on exit 0.
#
# Set the CLI entrypoint for the target project. Default assumes `npm start`
# forwards args; override by exporting EVAL_CLI before running the engine.
CLI="${EVAL_CLI:-npm start --silent --}"

# Process artifacts (only meaningful for a /devflow run; a bare-prompt baseline
# will fail these — that asymmetry is exactly what we want to measure).
check 1 "Spec artifact produced (process)"   devflow_artifact spec
check 1 "Review artifact produced (process)"  devflow_artifact review

# Outcome — the deliverable itself, framework-agnostic.
check 3 "CLI advertises --json in help"       bash -c "$CLI --help 2>&1 | grep -q -- --json"
check 4 "--json emits a single JSON object"   bash -c "$CLI --json 2>/dev/null | jq -e 'type==\"object\"' >/dev/null"
check 1 "Default output still works"          bash -c "$CLI --help >/dev/null 2>&1"
check 5 "Project test suite passes"           bash -c 'npm test'
