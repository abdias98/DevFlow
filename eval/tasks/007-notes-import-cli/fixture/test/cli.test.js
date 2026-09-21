'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { run } = require('../src/cli');

function tmpStore() {
  return path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'notes-')), 'notes.json');
}

test('add then list shows the note', () => {
  const file = tmpStore();
  assert.equal(run(['add', 'n1', 'Buy', 'milk'], { file }).code, 0);
  assert.equal(run(['list'], { file }).stdout, 'n1: Buy milk\n');
});

test('adding a duplicate id is an error', () => {
  const file = tmpStore();
  run(['add', 'n1', 'First'], { file });
  const result = run(['add', 'n1', 'Again'], { file });
  assert.equal(result.code, 1);
  assert.match(result.stderr, /duplicate id: n1/);
});

test('a note without a title is rejected', () => {
  const result = run(['add', 'n1'], { file: tmpStore() });
  assert.equal(result.code, 1);
  assert.match(result.stderr, /invalid note 'n1'/);
});
