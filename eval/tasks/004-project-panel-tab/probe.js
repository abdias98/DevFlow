'use strict';

// Behavioural probe for 004-project-panel-tab. Run from the result workspace:
//
//   node <task-dir>/probe.js <scenario>
//
// Loads the workspace's src/panel.js against a fake API whose responses the
// probe resolves by hand, so ordering and timing are deterministic. Exit 0 when
// the scenario holds, 1 (with a reason on stderr) when it does not.

const path = require('node:path');
const assert = require('node:assert/strict');

const DATA = {
  tasks: {
    p1: [{ id: 't1', title: 'Draft launch plan' }],
    p2: [{ id: 't7', title: 'Review budget' }, { id: 't8', title: 'Hire designer' }],
  },
  overview: {
    p1: { name: 'Apollo' },
    p2: { name: 'Gemini' },
  },
};

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((res, rej) => { resolve = res; reject = rej; });
  return { promise, resolve, reject };
}

function fakeApi() {
  const calls = { overview: [], tasks: [] };
  const make = (kind) => (projectId) => {
    const d = deferred();
    calls[kind].push({ projectId, d, settled: false });
    return d.promise;
  };
  return {
    calls,
    api: { getOverview: make('overview'), getTasks: make('tasks') },
  };
}

// Let promise continuations and any setImmediate/queueMicrotask work run.
async function flush() {
  for (let i = 0; i < 10; i++) await new Promise((resolve) => setImmediate(resolve));
}

function pending(calls, kind, projectId) {
  return calls[kind].filter((c) => c.projectId === projectId && !c.settled);
}

async function respond(calls, kind, projectId, { error } = {}) {
  const open = pending(calls, kind, projectId);
  if (open.length === 0) throw new Error(`no pending ${kind} request for ${projectId}`);
  for (const call of open) {
    call.settled = true;
    if (error) call.d.reject(error);
    else call.d.resolve(DATA[kind][projectId]);
  }
  await flush();
}

function setup() {
  const modulePath = path.resolve(process.cwd(), 'src/panel.js');
  const { createProjectPanel } = require(modulePath);
  const { api, calls } = fakeApi();
  const panel = createProjectPanel({ api });
  return { panel, calls };
}

const tasksOf = (panel) => panel.getState().tasks;

const scenarios = {
  // The Tasks tab shows the selected project's tasks.
  async 'loads-tasks'() {
    const { panel, calls } = setup();
    panel.selectProject('p1');
    panel.selectTab('tasks');
    await flush();
    await respond(calls, 'tasks', 'p1');
    assert.equal(tasksOf(panel).status, 'ready');
    assert.deepEqual(tasksOf(panel).data, DATA.tasks.p1);
  },

  // Failures surface in the tasks slice.
  async 'error-state'() {
    const { panel, calls } = setup();
    panel.selectProject('p1');
    panel.selectTab('tasks');
    await flush();
    await respond(calls, 'tasks', 'p1', { error: new Error('offline') });
    assert.equal(tasksOf(panel).status, 'error');
  },

  // Convention: a tab loads when it is active — not while another tab is.
  async 'loads-only-when-active'() {
    const { panel, calls } = setup();
    panel.selectProject('p1');
    await flush();
    assert.equal(calls.tasks.length, 0, 'tasks were requested while the Overview tab was active');
    panel.selectTab('tasks');
    await flush();
    assert.ok(calls.tasks.length >= 1, 'tasks were never requested after opening the Tasks tab');
    const before = calls.overview.length;
    panel.selectProject('p2');
    await flush();
    assert.equal(calls.overview.length, before, 'overview was requested while the Tasks tab was active');
  },

  // Switching project must never show the previous project's tasks.
  async 'no-stale-data-on-switch'() {
    const { panel, calls } = setup();
    panel.selectProject('p1');
    panel.selectTab('tasks');
    await flush();
    await respond(calls, 'tasks', 'p1');
    panel.selectProject('p2');
    await flush();
    assert.notDeepEqual(tasksOf(panel).data, DATA.tasks.p1, "p1's tasks still shown after switching to p2");
    await respond(calls, 'tasks', 'p2');
    assert.equal(tasksOf(panel).status, 'ready');
    assert.deepEqual(tasksOf(panel).data, DATA.tasks.p2);
  },

  // A slow response for a previous selection must not overwrite a newer one.
  async 'out-of-order-responses'() {
    const { panel, calls } = setup();
    panel.selectProject('p1');
    panel.selectTab('tasks');
    await flush();
    panel.selectProject('p2');
    await flush();
    await respond(calls, 'tasks', 'p2');
    await respond(calls, 'tasks', 'p1');
    assert.equal(tasksOf(panel).status, 'ready');
    assert.deepEqual(tasksOf(panel).data, DATA.tasks.p2, "a late p1 response overwrote p2's tasks");
  },

  // An error for the new selection must not leave the previous project's data.
  async 'error-after-switch'() {
    const { panel, calls } = setup();
    panel.selectProject('p1');
    panel.selectTab('tasks');
    await flush();
    await respond(calls, 'tasks', 'p1');
    panel.selectProject('p2');
    await flush();
    await respond(calls, 'tasks', 'p2', { error: new Error('offline') });
    assert.equal(tasksOf(panel).status, 'error');
    assert.notDeepEqual(tasksOf(panel).data, DATA.tasks.p1, "p1's tasks shown alongside p2's error");
  },

  // Adding a tab must not break the existing one.
  async 'overview-intact'() {
    const { panel, calls } = setup();
    panel.selectProject('p1');
    await flush();
    await respond(calls, 'overview', 'p1');
    assert.deepEqual(panel.getState().overview.data, DATA.overview.p1);
    panel.selectTab('tasks');
    await flush();
    panel.selectTab('overview');
    await flush();
    await respond(calls, 'overview', 'p1').catch(() => {});
    assert.deepEqual(panel.getState().overview.data, DATA.overview.p1);
  },
};

async function main() {
  const name = process.argv[2];
  const scenario = scenarios[name];
  if (!scenario) {
    console.error(`unknown scenario '${name}'. Available: ${Object.keys(scenarios).join(', ')}`);
    process.exit(2);
  }
  try {
    await scenario();
  } catch (err) {
    console.error(`${name}: ${err.message}`);
    process.exit(1);
  }
}

main();
