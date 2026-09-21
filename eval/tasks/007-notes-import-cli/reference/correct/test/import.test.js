'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { run } = require('../src/cli');

function tmp() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'notes-'));
}

test('import adds every note in the file', () => {
  const dir = tmp();
  const source = path.join(dir, 'in.json');
  fs.writeFileSync(source, JSON.stringify([{ id: 'a', title: 'One' }, { id: 'b', title: 'Two' }]));
  const file = path.join(dir, 'notes.json');
  assert.equal(run(['import', source], { file }).code, 0);
  assert.equal(run(['list'], { file }).stdout, 'a: One\nb: Two\n');
});

test('a file that is not an array is rejected', () => {
  const dir = tmp();
  const source = path.join(dir, 'in.json');
  fs.writeFileSync(source, '{"id":"a"}');
  assert.equal(run(['import', source], { file: path.join(dir, 'notes.json') }).code, 1);
});

test('an invalid note leaves the store unchanged', () => {
  const dir = tmp();
  const source = path.join(dir, 'in.json');
  fs.writeFileSync(source, JSON.stringify([{ id: 'a', title: 'One' }, { id: 'b', title: '' }]));
  const file = path.join(dir, 'notes.json');
  assert.equal(run(['import', source], { file }).code, 1);
  assert.equal(run(['list'], { file }).stdout, '');
});
