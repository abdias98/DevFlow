'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createProjectPanel } = require('../src/panel');

const tick = () => new Promise((resolve) => setImmediate(resolve));

function fakeApi(overviews) {
  return {
    getOverview: async (projectId) => overviews[projectId],
  };
}

test('starts idle with no project selected', () => {
  const panel = createProjectPanel({ api: fakeApi({}) });
  const state = panel.getState();
  assert.equal(state.projectId, null);
  assert.equal(state.activeTab, 'overview');
  assert.equal(state.overview.status, 'idle');
});

test('selecting a project loads its overview', async () => {
  const panel = createProjectPanel({ api: fakeApi({ p1: { name: 'Apollo' } }) });
  panel.selectProject('p1');
  assert.equal(panel.getState().overview.status, 'loading');
  await tick();
  assert.deepEqual(panel.getState().overview, { status: 'ready', data: { name: 'Apollo' }, error: null });
});

test('a failed overview request surfaces an error state', async () => {
  const api = { getOverview: async () => { throw new Error('boom'); } };
  const panel = createProjectPanel({ api });
  panel.selectProject('p1');
  await tick();
  assert.equal(panel.getState().overview.status, 'error');
});

test('rejects an unknown tab', () => {
  const panel = createProjectPanel({ api: fakeApi({}) });
  assert.throws(() => panel.selectTab('nope'), /unknown tab/);
});
