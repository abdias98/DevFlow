'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { loadConfig } = require('../src/config');
const { createServer } = require('../src/server');

const FILE = path.resolve(__dirname, '..', 'config.json');

test('loadConfig reads the values in the file', () => {
  assert.deepEqual(loadConfig(FILE), { host: 'localhost', port: 3000, debug: true });
});

test('createServer describes where it listens and how verbose it is', () => {
  assert.deepEqual(createServer(loadConfig(FILE)), { address: 'localhost:3000', logLevel: 'debug' });
});

test('createServer rejects a configuration of the wrong shape', () => {
  assert.throws(() => createServer({ host: 'localhost', port: '3000', debug: true }), TypeError);
});
