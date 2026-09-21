'use strict';

// Behavioural probe for 005-stats-median-cli. Run from the result workspace:
//
//   node <task-dir>/probe.js <scenario>
//
// Drives the real executable (bin/stats.js) as a child process, exactly as a
// user would, and inspects stdout, stderr and the exit code. Exit 0 when the
// scenario holds, 1 (with a reason on stderr) when it does not.

const path = require('node:path');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');

function stats(...args) {
  const result = spawnSync(process.execPath, [path.resolve(process.cwd(), 'bin/stats.js'), ...args], {
    encoding: 'utf8',
    timeout: 5000,
  });
  return { code: result.status, out: result.stdout.trim(), err: result.stderr };
}

const scenarios = {
  // The requested feature: the median of an odd count.
  'basic'() {
    const r = stats('median', '3', '1', '2');
    assert.equal(r.code, 0, `exit code ${r.code}: ${r.err}`);
    assert.equal(r.out, '2');
  },

  // Numbers compare as numbers, not as text: "10" < "9" is true for strings.
  'numeric-sort'() {
    const r = stats('median', '10', '9', '100');
    assert.equal(r.code, 0, `exit code ${r.code}: ${r.err}`);
    assert.equal(r.out, '10');
  },

  // An even count has no middle value: the median is the mean of the two middle ones.
  'even-count'() {
    const r = stats('median', '4', '1', '3', '2');
    assert.equal(r.code, 0, `exit code ${r.code}: ${r.err}`);
    assert.equal(r.out, '2.5');
  },

  // A single number is its own median.
  'single'() {
    const r = stats('median', '7');
    assert.equal(r.code, 0, `exit code ${r.code}: ${r.err}`);
    assert.equal(r.out, '7');
  },

  // Convention in src/commands.js: no numbers is a usage error, never NaN.
  'empty'() {
    const r = stats('median');
    assert.equal(r.code, 1, `expected exit code 1, got ${r.code}`);
    assert.equal(r.out, '', 'nothing may be printed to stdout');
    assert.ok(r.err.trim().length > 0, 'an error message is expected on stderr');
  },

  // Convention in src/parse.js: the offending argument is named.
  'invalid'() {
    const r = stats('median', '1', 'abc', '3');
    assert.equal(r.code, 1, `expected exit code 1, got ${r.code}`);
    assert.match(r.err, /abc/);
  },

  // The commands that already existed keep working.
  'existing-intact'() {
    assert.equal(stats('sum', '1', '2', '3').out, '6');
    assert.equal(stats('mean', '2', '4').out, '3');
    assert.equal(stats('max', '1', '9', '3').out, '9');
  },

  // The usage text is how a user discovers commands.
  'usage-lists-median'() {
    const r = stats('--help');
    assert.equal(r.code, 0);
    assert.match(r.out, /median/);
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
