'use strict';

// Reference overlay — the tests a straightforward implementation would add.

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createProjectPanel } = require('../src/panel');

const tick = () => new Promise((resolve) => setImmediate(resolve));

test('opening the Tasks tab loads the selected project tasks', async () => {
  const api = { getOverview: async () => ({}), getTasks: async (id) => [{ id: `${id}-t1` }] };
  const panel = createProjectPanel({ api });
  panel.selectProject('p1');
  panel.selectTab('tasks');
  await tick();
  assert.deepEqual(panel.getState().tasks, { status: 'ready', data: [{ id: 'p1-t1' }], error: null });
});
