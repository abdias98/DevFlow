'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { run } = require('../src/cli');

test('sum adds the numbers', () => {
  assert.deepEqual(run(['sum', '1', '2', '3']), { code: 0, stdout: '6\n', stderr: '' });
});

test('mean averages the numbers', () => {
  assert.equal(run(['mean', '2', '4']).stdout, '3\n');
});

test('max returns the largest number', () => {
  assert.equal(run(['max', '1', '9', '3']).stdout, '9\n');
});

test('a command with no numbers is a usage error', () => {
  const result = run(['sum']);
  assert.equal(result.code, 1);
  assert.match(result.stderr, /no numbers given/);
});

test('a non-numeric argument is named in the error', () => {
  const result = run(['mean', '1', 'abc']);
  assert.equal(result.code, 1);
  assert.match(result.stderr, /not a number: abc/);
});

test('an unknown command prints the usage', () => {
  const result = run(['nope']);
  assert.equal(result.code, 1);
  assert.match(result.stderr, /unknown command: nope/);
});
