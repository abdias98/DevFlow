---
id: 002-rest-health-endpoint
title: Add a GET /health endpoint to a web service
complexity: routine
category: api
threshold: 80
---

## Prompt

> Add a `GET /health` endpoint to the service. It must return HTTP 200 with a
> JSON body containing at least a `status` field set to `"ok"`. Add a test that
> hits the endpoint and asserts the status code and body.

Run once through `/devflow` (or `/devflow-feature`) and once as a bare-prompt
baseline, then score both.

## Definition of Done

- `GET /health` is routed and returns 200.
- The response body is JSON with `status: "ok"`.
- A test covers the endpoint and the suite passes.
- No existing route or behaviour regressed.

## Scoring

Checks live in `checks.sh`. They start the service via `EVAL_SERVE` (default
`npm start`) on `EVAL_PORT` (default 3000) and probe it. Override those for the
target project before running.
