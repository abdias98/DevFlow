'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { run } = require('../src/cli');

test('median of an odd count is the middle value', () => {
  assert.equal(run(['median', '3', '1', '2']).stdout, '2\n');
});

test('median of an even count averages the two middle values', () => {
  assert.equal(run(['median', '4', '1', '3', '2']).stdout, '2.5\n');
});

test('median with no numbers is a usage error', () => {
  assert.equal(run(['median']).code, 1);
});
