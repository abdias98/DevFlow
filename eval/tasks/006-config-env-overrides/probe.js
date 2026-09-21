'use strict';

// Behavioural probe for 006-config-env-overrides. Run from the result workspace:
//
//   node <task-dir>/probe.js <scenario>
//
// Sets process.env, loads the workspace's config module and hands its result to
// the workspace's own server setup — the consumer the loader exists for. Exit 0
// when the scenario holds, 1 (with a reason on stderr) when it does not.

const path = require('node:path');
const assert = require('node:assert/strict');

const VARS = ['HOST', 'PORT', 'DEBUG'];
const FILE = path.resolve(process.cwd(), 'config.json');

function load(env = {}) {
  for (const key of VARS) delete process.env[key];
  Object.assign(process.env, env);
  const { loadConfig } = require(path.resolve(process.cwd(), 'src/config.js'));
  return loadConfig(FILE);
}

function serve(env = {}) {
  const config = load(env);
  const { createServer } = require(path.resolve(process.cwd(), 'src/server.js'));
  return createServer(config);
}

const scenarios = {
  // No environment: the file still decides (host localhost, port 3000, debug on).
  'file-values'() {
    assert.deepEqual(serve(), { address: 'localhost:3000', logLevel: 'debug' });
  },

  // The requested feature: HOST overrides the file.
  'host-override'() {
    assert.equal(serve({ HOST: '0.0.0.0' }).address, '0.0.0.0:3000');
  },

  // Environment values are strings; the server rejects a port that is not a number.
  'port-override'() {
    assert.equal(serve({ PORT: '8080' }).address, 'localhost:8080');
  },

  // DEBUG=true keeps/turns verbose logging on.
  'debug-true'() {
    assert.equal(serve({ DEBUG: 'true' }).logLevel, 'debug');
  },

  // The file says debug: true, so DEBUG=false must turn it OFF. The string
  // 'false' is truthy; the consumer needs a real boolean false.
  'debug-false'() {
    assert.equal(serve({ DEBUG: 'false' }).logLevel, 'info');
  },

  // A port that is not a number must not be silently accepted.
  'invalid-port'() {
    assert.throws(() => load({ PORT: 'abc' }), /PORT|port/);
  },
};

const name = process.argv[2];
if (!scenarios[name]) {
  console.error(`unknown scenario: ${name}`);
  process.exit(2);
}
try {
  scenarios[name]();
} catch (err) {
  console.error(`scenario '${name}' failed: ${err.message}`);
  process.exit(1);
}
