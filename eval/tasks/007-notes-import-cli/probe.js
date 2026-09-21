'use strict';

// Behavioural probe for 007-notes-import-cli. Run from the result workspace:
//
//   node <task-dir>/probe.js <scenario>
//
// Drives the real executable (bin/notes.js) as a child process against a
// throw-away store file, exactly as a user would. Exit 0 when the scenario
// holds, 1 (with a reason on stderr) when it does not.

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');

function sandbox() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'eval-notes-'));
  const store = path.join(dir, 'store.json');
  const notes = (...args) => {
    const r = spawnSync(process.execPath, [path.resolve(process.cwd(), 'bin/notes.js'), ...args], {
      encoding: 'utf8',
      timeout: 5000,
      env: { ...process.env, NOTES_FILE: store },
    });
    return { code: r.status, out: r.stdout, err: r.stderr };
  };
  const write = (name, content) => {
    const p = path.join(dir, name);
    fs.writeFileSync(p, typeof content === 'string' ? content : JSON.stringify(content));
    return p;
  };
  return { notes, write };
}

const ids = (listOutput) => listOutput.split('\n').filter(Boolean).map((line) => line.split(':')[0]);

const scenarios = {
  // The requested feature: every note in the file is added.
  'import-valid'() {
    const { notes, write } = sandbox();
    const file = write('in.json', [{ id: 'a', title: 'One' }, { id: 'b', title: 'Two' }, { id: 'c', title: 'Three' }]);
    const r = notes('import', file);
    assert.equal(r.code, 0, `exit code ${r.code}: ${r.err}`);
    assert.deepEqual(ids(notes('list').out), ['a', 'b', 'c']);
  },

  // A note in the middle of the file is invalid: the import fails AND the notes
  // before it must not be left behind.
  'atomic-import'() {
    const { notes, write } = sandbox();
    const file = write('in.json', [{ id: 'a', title: 'One' }, { id: 'b', title: '' }, { id: 'c', title: 'Three' }]);
    const r = notes('import', file);
    assert.notEqual(r.code, 0, 'the import must fail');
    assert.deepEqual(ids(notes('list').out), [], 'a failed import must leave the store as it was');
  },

  // The error tells the user which note is the problem.
  'names-offender'() {
    const { notes, write } = sandbox();
    const file = write('in.json', [{ id: 'a', title: 'One' }, { id: 'bad-note', title: '' }]);
    const r = notes('import', file);
    assert.notEqual(r.code, 0);
    assert.match(r.err, /bad-note/);
  },

  // A file that is not JSON, or not an array, is a usage error — not a stack trace.
  'malformed-file'() {
    const { notes, write } = sandbox();
    for (const content of ['{not json', '{"id":"a","title":"One"}']) {
      const r = notes('import', write('bad.json', content));
      assert.equal(r.code, 1, `expected exit code 1, got ${r.code}`);
      assert.ok(r.err.trim().length > 0, 'an error message is expected on stderr');
      assert.doesNotMatch(r.err, /\n\s+at /, 'a stack trace is not an error message');
    }
  },

  // A file naming no notes is valid: nothing to add, nothing changes.
  'empty-array'() {
    const { notes, write } = sandbox();
    const r = notes('import', write('in.json', []));
    assert.equal(r.code, 0, `exit code ${r.code}: ${r.err}`);
    assert.deepEqual(ids(notes('list').out), []);
  },

  // add and list keep working.
  'existing-intact'() {
    const { notes } = sandbox();
    assert.equal(notes('add', 'n1', 'Buy', 'milk').code, 0);
    assert.equal(notes('list').out, 'n1: Buy milk\n');
    assert.equal(notes('add', 'n1', 'Again').code, 1);
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
