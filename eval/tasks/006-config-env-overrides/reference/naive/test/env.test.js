'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { loadConfig } = require('../src/config');
const { createServer } = require('../src/server');

const FILE = path.resolve(__dirname, '..', 'config.json');

function withEnv(vars, fn) {
  const saved = {};
  for (const key of Object.keys(vars)) saved[key] = process.env[key];
  Object.assign(process.env, vars);
  try {
    return fn();
  } finally {
    for (const key of Object.keys(vars)) {
      if (saved[key] === undefined) delete process.env[key];
      else process.env[key] = saved[key];
    }
  }
}

test('HOST overrides the host in the file', () => {
  withEnv({ HOST: '0.0.0.0' }, () => assert.equal(loadConfig(FILE).host, '0.0.0.0'));
});

test('PORT overrides the port and is a number', () => {
  withEnv({ PORT: '8080' }, () => {
    assert.equal(loadConfig(FILE).port, 8080);
    assert.equal(createServer(loadConfig(FILE)).address, 'localhost:8080');
  });
});

test('DEBUG=true turns debug on', () => {
  withEnv({ DEBUG: 'true' }, () => assert.equal(loadConfig(FILE).debug, true));
});

test('an invalid PORT is rejected', () => {
  withEnv({ PORT: 'abc' }, () => assert.throws(() => loadConfig(FILE), /PORT/));
});
