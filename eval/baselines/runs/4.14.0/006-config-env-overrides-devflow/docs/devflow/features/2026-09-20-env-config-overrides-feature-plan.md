## ⚡ Feature Plan: env-config-overrides

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript (CommonJS) · Node.js >=18 · node:test
**Rigor:** standard — routine change: one function extended, one test file, no new components.

### Plan Digest

- **Tasks:** 2 tasks (T1 override + type coercion; T2 fail-fast on invalid / empty values)
- **Files to create:** none (plus flow artifacts under `docs/devflow/`)
- **Files to modify:** `src/config.js`, `test/config.test.js`
- **Key dependencies:** T2 builds on T1 (same function, same test file)
- **Test strategy:** unit tests per task with `node:test`; `loadConfig` takes an injectable `env` (default `process.env`) so tests never depend on the ambient environment; one test proves the default really is `process.env`; one integration-style test feeds `loadConfig` output into `createServer`.
- **Scope:** `src/server.js`, `config.json`, new env vars, `.env` loading, hostname/IP syntax validation and validation of file values are OUT of scope.

### Summary

**Goal:** `HOST`, `PORT` and `DEBUG` environment variables override the matching values from `config.json` in `loadConfig()`, and the result still satisfies the contract `createServer` enforces (string host, integer port 0-65535, boolean debug).

**Definition of Done:**
- [ ] 1. `HOST` set → `loadConfig()` returns that host.
- [ ] 2. `PORT` set to a valid port → `loadConfig()` returns it as an integer, and `createServer(loadConfig())` accepts it and reports the overridden address.
- [ ] 3. `DEBUG` set to a boolean-like value → `loadConfig()` returns a real boolean; `DEBUG=false` turns debug off although the file says `true`.
- [ ] 4. Unset variables leave file values untouched (per-key override).
- [ ] 5. Invalid `PORT` / `DEBUG` values throw at load time naming the variable; no wrong config is returned.
- [ ] 6. New behaviour is covered by tests and `npm test` passes.

### Scope

- **In:** override logic in `loadConfig`; tests in `test/config.test.js` (existing tests isolated from ambient env).
- **Out:** see Plan Digest.

### Reference Implementation

- **File/Pattern:** `src/server.js` `assertValidConfig` — the type contract to satisfy and the `TypeError` convention for invalid config; `test/config.test.js` — node:test + `assert/strict` style.

### Affected Files

**Create:** none.

**Modify:**
- `src/config.js` — add `env` parameter and per-key override with parsing.
- `test/config.test.js` — new tests; existing `loadConfig`/`createServer` tests pass `{}` as env so an ambient `PORT`/`HOST`/`DEBUG` cannot break them (Impact Zone: existing test covering the changed symbol; already in the declared scope).

### Assumptions (CI — inferred, none could be asked)

See `context.md` `## Assumptions (CI)`; the ones that shape behaviour: unset or empty variable = no override; `PORT` digits only, 0-65535; `DEBUG` ∈ {true,false,1,0} case-insensitive; invalid → `TypeError` naming the variable; `HOST` taken verbatim when non-empty.

### Critical Friend

- 🟡 [WARN] `DEBUG` collides with a widespread convention → scenario: a developer has `DEBUG=app:*` exported for the `debug` package → runs anything that calls `loadConfig()` → observed: `TypeError: DEBUG must be ...` at `src/config.js` (parseDebug), expected: per the request `DEBUG` overrides the boolean debug flag; behaviour for non-boolean values is unspecified by the request. Decision: fail loudly (`error-handling.md §1` — no silent coercion of an unknown value) and record it here; a dedicated prefixed variable (e.g. `APP_DEBUG`) would avoid the collision but contradicts the requested variable names. No BLOCK; proceeding.
- 🟢 [INFO] Environment variables are external input → `security.md §1`: validated at the boundary (type, range, allowlist) rather than trusted.

### Behavior Scenarios

| # | Given | When | Then | Task | Test file |
|---|-------|------|------|------|-----------|
| S1 | file {localhost,3000,true} | env {HOST:'0.0.0.0'} | host overridden; port/debug from file | Task 1 | `test/config.test.js` |
| S2 | same file | env {PORT:'8080'} | port is number 8080; `createServer` address `localhost:8080` | Task 1 | `test/config.test.js` |
| S3 | file debug=true | env {DEBUG:'false'} | debug is boolean false; `createServer` logLevel `info` | Task 1 | `test/config.test.js` |
| S4 | any file | env {} | file values unchanged | Task 1 | `test/config.test.js` |
| S5 | any file | `loadConfig` called twice with different env, then with {} | each call reflects its own env (env read at call time) | Task 1 | `test/config.test.js` |
| S6 | any file | env {PORT: 'abc' / '' handled as unset / '80.5' / '65536' / '-1'…} | throws naming PORT; never a partial config; empty string never becomes port 0 | Task 2 | `test/config.test.js` |
| S7 | any file | env {DEBUG:'maybe'} | throws naming DEBUG | Task 2 | `test/config.test.js` |
| S8 | any file | env {HOST:'',PORT:'',DEBUG:''} | treated as unset; file values kept | Task 2 | `test/config.test.js` |
| S9 | any file | process.env has PORT set, `loadConfig(FILE)` called with default env | override is applied (default env is `process.env`) | Task 1 | `test/config.test.js` |

### Tasks

#### Task 1: Override HOST, PORT, DEBUG from the environment

- **Standards constraints:**
  - `security.md §1` — env values are external input: parse into the exact types the contract requires (integer port, boolean debug), never pass raw strings through.
  - `testing.md §3, §6` — tests inject `env`; nothing depends on ambient process env or test order; the one test touching `process.env` restores it in `finally`.
  - `design-principles.md §2, §5` — no config framework or options object; one small helper, three call sites.

- [ ] **Test file:** `test/config.test.js` (modify)
  ```js
  'use strict';

  const test = require('node:test');
  const assert = require('node:assert/strict');
  const fs = require('node:fs');
  const os = require('node:os');
  const path = require('node:path');
  const { loadConfig } = require('../src/config');
  const { createServer } = require('../src/server');

  const FILE = path.resolve(__dirname, '..', 'config.json');

  function writeConfigFile(t, values) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'app-config-'));
    t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
    const file = path.join(dir, 'config.json');
    fs.writeFileSync(file, JSON.stringify(values));
    return file;
  }

  // -- existing tests, isolated from the ambient environment (env = {}) --
  test('loadConfig reads the values in the file', () => {
    assert.deepEqual(loadConfig(FILE, {}), { host: 'localhost', port: 3000, debug: true });
  });

  test('createServer describes where it listens and how verbose it is', () => {
    assert.deepEqual(createServer(loadConfig(FILE, {})), { address: 'localhost:3000', logLevel: 'debug' });
  });

  test('createServer rejects a configuration of the wrong shape', () => {
    assert.throws(() => createServer({ host: 'localhost', port: '3000', debug: true }), TypeError);
  });

  // -- new: overrides --
  // ✅ Happy path
  test('loadConfig — HOST set — overrides only the host (S1)', () => {
    assert.deepEqual(loadConfig(FILE, { HOST: '0.0.0.0' }), { host: '0.0.0.0', port: 3000, debug: true });
  });

  test('loadConfig — PORT set — returns the port as a number (S2)', () => {
    const config = loadConfig(FILE, { PORT: '8080' });
    assert.deepEqual(config, { host: 'localhost', port: 8080, debug: true });
    assert.equal(typeof config.port, 'number');
  });

  test('createServer — config with PORT override — listens on the overridden port (S2)', () => {
    assert.deepEqual(createServer(loadConfig(FILE, { PORT: '8080' })), {
      address: 'localhost:8080',
      logLevel: 'debug',
    });
  });

  test('loadConfig — DEBUG=false — turns debug off although the file says true (S3)', () => {
    const config = loadConfig(FILE, { DEBUG: 'false' });
    assert.equal(config.debug, false);
    assert.equal(createServer(config).logLevel, 'info');
  });

  test('loadConfig — DEBUG=true — turns debug on although the file says false (S3)', (t) => {
    const file = writeConfigFile(t, { host: 'localhost', port: 3000, debug: false });
    assert.equal(loadConfig(file, { DEBUG: 'true' }).debug, true);
  });

  test('loadConfig — all three set — every value comes from the environment', () => {
    assert.deepEqual(loadConfig(FILE, { HOST: 'example.test', PORT: '443', DEBUG: '0' }), {
      host: 'example.test',
      port: 443,
      debug: false,
    });
  });

  test('loadConfig — no variables set — returns the file values (S4)', () => {
    assert.deepEqual(loadConfig(FILE, {}), { host: 'localhost', port: 3000, debug: true });
  });

  // ⚠️ Edge cases
  for (const [raw, expected] of [['true', true], ['TRUE', true], ['1', true], ['false', false], ['False', false], ['0', false]]) {
    test(`loadConfig — DEBUG='${raw}' — is the boolean ${expected}`, (t) => {
      const file = writeConfigFile(t, { host: 'localhost', port: 3000, debug: !expected });
      assert.equal(loadConfig(file, { DEBUG: raw }).debug, expected);
    });
  }

  for (const [raw, expected] of [['0', 0], ['65535', 65535], ['0080', 80]]) {
    test(`loadConfig — PORT='${raw}' — is the integer ${expected}`, () => {
      assert.equal(loadConfig(FILE, { PORT: raw }).port, expected);
    });
  }

  // 🔁 Sequence / interaction scenarios
  test('loadConfig — called with different env each time — every call reflects its own env (S5)', () => {
    assert.equal(loadConfig(FILE, { PORT: '8080' }).port, 8080);
    assert.equal(loadConfig(FILE, { PORT: '9090' }).port, 9090);
    assert.equal(loadConfig(FILE, {}).port, 3000);
  });

  test('loadConfig — default env — is process.env (S9)', () => {
    const previous = process.env.PORT;
    process.env.PORT = '4242';
    try {
      assert.equal(loadConfig(FILE).port, 4242);
    } finally {
      if (previous === undefined) delete process.env.PORT;
      else process.env.PORT = previous;
    }
  });
  ```

- [ ] **Production code:** `src/config.js` *(modify)*
  ```js
  // Reads an override from env. A variable that is not set means "no override"
  // and the file value is kept.
  function fromEnv(env, name, parse, fileValue) {
    const value = env[name];
    return value === undefined ? fileValue : parse(value);
  }

  const parseHost = (value) => value;
  const parsePort = (value) => Number(value);
  const parseDebug = (value) => value.toLowerCase() === 'true' || value === '1';

  // ...
  // The environment variables HOST, PORT and DEBUG override the matching values
  // from the file. `env` exists so tests do not depend on the process environment.
  function loadConfig(file = DEFAULT_FILE, env = process.env) {
    const raw = JSON.parse(fs.readFileSync(file, 'utf8'));
    return {
      host: fromEnv(env, 'HOST', parseHost, raw.host),
      port: fromEnv(env, 'PORT', parsePort, raw.port),
      debug: fromEnv(env, 'DEBUG', parseDebug, raw.debug),
    };
  }
  ```

- [ ] **Commit:**
  ```bash
  git add src/config.js test/config.test.js
  git commit -m "feat(config): let HOST, PORT and DEBUG override config.json values"
  ```

  **Test command:** `node --test test/config.test.js`

---

#### Task 2: Fail fast on invalid values; empty variable means "not set"

- **Standards constraints:**
  - `error-handling.md §1, §2` — an invalid `PORT`/`DEBUG` is rejected at the boundary with an error naming the variable; no `NaN`, no silent coercion, no partially applied override.
  - `security.md §1` — allowlist validation: `PORT` = `/^\d+$/` and ≤ 65535; `DEBUG` = `true|false|1|0`.
  - `testing.md §4` — failure scenarios plus the empty-string edge case (`Number('') === 0` would silently bind port 0).

- [ ] **Test file:** `test/config.test.js` (append)
  ```js
  // ❌ Failure scenarios (S6, S7)
  for (const raw of ['abc', '80.5', '1e3', ' 80', '80 ', '-1', '+80', '0x50', '65536', '99999999999999999999']) {
    test(`loadConfig — PORT='${raw}' — throws a TypeError naming PORT (S6)`, () => {
      assert.throws(() => loadConfig(FILE, { PORT: raw }), { name: 'TypeError', message: /PORT/ });
    });
  }

  for (const raw of ['maybe', 'yes', 'on', 'app:*', 'truee']) {
    test(`loadConfig — DEBUG='${raw}' — throws a TypeError naming DEBUG (S7)`, () => {
      assert.throws(() => loadConfig(FILE, { DEBUG: raw }), { name: 'TypeError', message: /DEBUG/ });
    });
  }

  test('loadConfig — valid HOST with invalid PORT — throws instead of returning a partial override (S6)', () => {
    assert.throws(() => loadConfig(FILE, { HOST: '0.0.0.0', PORT: 'abc' }), TypeError);
  });

  // ⚠️ Edge case: empty variable
  test('loadConfig — HOST, PORT and DEBUG set to empty strings — are treated as unset (S8)', () => {
    assert.deepEqual(loadConfig(FILE, { HOST: '', PORT: '', DEBUG: '' }), {
      host: 'localhost',
      port: 3000,
      debug: true,
    });
  });
  ```

- [ ] **Production code:** `src/config.js` *(modify)*
  ```js
  // "Not set" includes the empty string: `PORT=` in a shell is conventionally
  // "unset", and Number('') would otherwise silently become port 0.
  function fromEnv(env, name, parse, fileValue) {
    const value = env[name];
    return value === undefined || value === '' ? fileValue : parse(value);
  }

  const parseHost = (value) => value;

  function parsePort(value) {
    if (!/^\d+$/.test(value) || Number(value) > 65535) {
      throw new TypeError(`PORT must be an integer from 0 to 65535, got '${value}'`);
    }
    return Number(value);
  }

  function parseDebug(value) {
    const normalized = value.toLowerCase();
    if (normalized === 'true' || normalized === '1') return true;
    if (normalized === 'false' || normalized === '0') return false;
    throw new TypeError(`DEBUG must be one of true, false, 1, 0, got '${value}'`);
  }
  ```

- [ ] **Commit:**
  ```bash
  git add src/config.js test/config.test.js
  git commit -m "feat(config): reject invalid PORT/DEBUG and treat empty variables as unset"
  ```

  **Test command:** `node --test test/config.test.js`

---

### Verification

**All new tests:** `node --test test/config.test.js`
**Full suite:** `npm test`

---

## 🚦 Confirmation

CI mode: plan auto-approved.
