## ⚡ Feature Plan: project-panel-tasks-tab

**Date:** 2026-09-17
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript (Node CommonJS) · none · `node --test`

### Plan Digest

- **Tasks:** 2 tasks
- **Files to create:** none
- **Files to modify:** `src/panel.js`, `test/panel.test.js`
- **Key dependencies:** Task 1 (shared stale-response-safe loader, replacing the ad hoc `loadOverview`) → Task 2 (Tasks tab wired onto the same loader)
- **Test strategy:** unit per task + 2 sequence/interaction tests (S1 ordering, S2 project-switch-while-loading)
- **Scope:** `panel.js` state layer only — no DOM, no changes to `api.js`

### Summary

**Goal:** Add a `tasks` tab to the panel, safe against stale/out-of-order responses, following the Overview tab's `{status,data,error}` shape.

**Definition of Done:**
- [ ] `selectTab('tasks')` shows the selected project's tasks in `getState().tasks`
- [ ] `tasks` has loading/error states like `overview`
- [ ] The panel never shows data belonging to a project other than the current selection
- [ ] Overview keeps working
- [ ] Covered by tests

### Scope

- **In:** `src/panel.js` (loader + tasks tab), tests
- **Out:** `src/api.js`, any DOM/view code, other tabs

### Reference Implementation

- **File/Pattern:** `src/panel.js` `loadOverview`/`loadActiveTab` — same `{status,data,error}` slice shape and `TABS` gating, but its load pattern has a latent gap (see Behavior Scenarios below): it does not tie a response to the request that produced it, so a request for a superseded selection can overwrite state for the current one.

### Affected Files

**Modify:**
- `src/panel.js` — replace `loadOverview`'s ad hoc pattern with a shared `load(tab)` helper that tags every request with a token and applies the response only if it is still the latest request for that tab; add `tasks` following the same helper. `selectProject` invalidates in-flight requests for every tab, not only the active one.

### Behavior Scenarios

| # | Given | When | Then | Task | Test file |
|---|-------|------|------|------|-----------|
| S1 | Tasks tab active, project A selected, its `getTasks` request in flight | Project is switched to B before A's response arrives, and A's response arrives *after* B's | The panel shows B's tasks — A's late response is discarded | Task 1 | `test/panel.test.js` |
| S2 | Tasks tab active, project A's tasks loaded | Project is switched to B while still on the Tasks tab | The panel never shows A's tasks mixed with B's tab state — `tasks` resets and reloads for B | Task 2 | `test/panel.test.js` |
| S3 | Overview tab active, project A loaded | Project switched to B, B's `getOverview` request fails | Overview shows the error for B, not A's stale data | Task 1 | `test/panel.test.js` |

### Tasks

#### Task 1: Shared stale-response-safe loader (fixes Overview, used by Tasks)

- **Standards constraints:** `concurrency.md §5` — a response must only be applied if it is still the result of the *latest* request for that slice; superseded responses are discarded, which is a form of idempotency-under-redelivery applied to client-side async state. `design-principles.md §1` — Overview and Tasks share one loading pattern; a second copy of the same logic (DRY) is exactly what let the original gap go unnoticed.

- [ ] **Test file:** `test/panel.test.js` (new tests appended to existing file)
  ```javascript
  // 🔁 Sequence / interaction scenario — S1
  test('a late response for a superseded project selection is discarded (Overview)', async () => {
    let resolveA;
    const api = {
      getOverview: (id) => id === 'a'
        ? new Promise((resolve) => { resolveA = () => resolve({ name: 'A' }); })
        : Promise.resolve({ name: 'B' }),
      getTasks: async () => [],
    };
    const panel = createProjectPanel({ api });
    panel.selectProject('a');
    panel.selectProject('b'); // b resolves immediately (microtask), a is still pending
    await tick();
    resolveA(); // a's late response arrives after b's
    await tick();
    assert.deepEqual(panel.getState().overview.data, { name: 'B' });
  });

  // ❌ Failure / error scenario (S3)
  test('an error for the new selection does not leave the previous selection\\'s data (Overview)', async () => {
    const api = {
      getOverview: (id) => id === 'a' ? Promise.resolve({ name: 'A' }) : Promise.reject(new Error('boom')),
      getTasks: async () => [],
    };
    const panel = createProjectPanel({ api });
    panel.selectProject('a');
    await tick();
    panel.selectProject('b');
    await tick();
    assert.equal(panel.getState().overview.status, 'error');
    assert.notDeepEqual(panel.getState().overview.data, { name: 'A' });
  });
  ```

- [ ] **Production code:** `src/panel.js` (modify)
  ```javascript
  function createProjectPanel({ api }) {
    const loaders = {
      overview: (projectId) => api.getOverview(projectId),
      tasks: (projectId) => api.getTasks(projectId),
    };
    const TABS = Object.keys(loaders);

    const state = { projectId: null, activeTab: 'overview' };
    for (const tab of TABS) state[tab] = emptySlice();

    const latestRequest = {}; // tab -> token of the most recent request
    const listeners = new Set();

    function getState() {
      const snapshot = { ...state };
      for (const tab of TABS) snapshot[tab] = { ...state[tab] };
      return snapshot;
    }

    function emit() {
      const snapshot = getState();
      for (const listener of listeners) listener(snapshot);
    }

    async function load(tab) {
      const token = Symbol(tab);
      latestRequest[tab] = token;
      state[tab] = { status: 'loading', data: null, error: null };
      emit();
      let next;
      try {
        next = { status: 'ready', data: await loaders[tab](state.projectId), error: null };
      } catch (error) {
        next = { status: 'error', data: null, error };
      }
      if (latestRequest[tab] !== token) return; // superseded — discard
      state[tab] = next;
      emit();
    }

    function loadActiveTab() {
      if (state.projectId === null) return;
      load(state.activeTab);
    }

    return {
      getState,
      subscribe(listener) { listeners.add(listener); return () => listeners.delete(listener); },
      selectProject(projectId) {
        state.projectId = projectId;
        for (const tab of TABS) {
          latestRequest[tab] = null; // invalidate any in-flight request for every tab
          state[tab] = emptySlice();
        }
        loadActiveTab();
      },
      selectTab(name) {
        if (!TABS.includes(name)) throw new Error(`unknown tab: ${name}`);
        state.activeTab = name;
        loadActiveTab();
      },
    };
  }
  ```

- [ ] **Commit:**
  ```bash
  git add src/panel.js test/panel.test.js
  git commit -m "refactor(panel): unify tab loading behind a stale-response-safe loader"
  ```

  **Test command:** `node --test test/panel.test.js`

---

#### Task 2: Tasks tab on the shared loader

- **Standards constraints:** `testing.md §4` — cover the happy path, an edge case (tab selected before a project), and the failure/sequence scenarios (S2) for the new tab, not only its happy path.

- [ ] **Test file:** `test/panel.test.js` (appended)
  ```javascript
  // ✅ Happy path
  test('opening the Tasks tab loads the selected project tasks', async () => {
    const api = { getOverview: async () => ({}), getTasks: async (id) => [{ id: `${id}-t1` }] };
    const panel = createProjectPanel({ api });
    panel.selectProject('p1');
    panel.selectTab('tasks');
    await tick();
    assert.deepEqual(panel.getState().tasks, { status: 'ready', data: [{ id: 'p1-t1' }], error: null });
  });

  // ⚠️ Edge case
  test('selecting the Tasks tab before a project is selected does nothing yet', () => {
    const api = { getOverview: async () => ({}), getTasks: async () => [] };
    const panel = createProjectPanel({ api });
    panel.selectTab('tasks');
    assert.equal(panel.getState().tasks.status, 'idle');
  });

  // ❌ Failure / error scenario
  test('a failed tasks request surfaces an error state', async () => {
    const api = { getOverview: async () => ({}), getTasks: async () => { throw new Error('boom'); } };
    const panel = createProjectPanel({ api });
    panel.selectProject('p1');
    panel.selectTab('tasks');
    await tick();
    assert.equal(panel.getState().tasks.status, 'error');
  });

  // 🔁 Sequence / interaction scenario — S2
  test('switching project while on the Tasks tab never mixes tasks across projects', async () => {
    const api = {
      getOverview: async () => ({}),
      getTasks: (id) => id === 'a' ? new Promise(() => {}) /* never resolves */ : Promise.resolve([{ id: 'b-t1' }]),
    };
    const panel = createProjectPanel({ api });
    panel.selectProject('a');
    panel.selectTab('tasks');
    await tick();
    assert.equal(panel.getState().tasks.status, 'loading');
    panel.selectProject('b');
    await tick();
    assert.deepEqual(panel.getState().tasks.data, [{ id: 'b-t1' }]);
  });
  ```

- [ ] **Production code:** none beyond Task 1 — `tasks` is already wired into `loaders`/`TABS` in the shared loader.

- [ ] **Commit:**
  ```bash
  git add test/panel.test.js
  git commit -m "feat(panel): add Tasks tab on the shared stale-response-safe loader"
  ```

  **Test command:** `node --test test/panel.test.js`

---

### Verification

**All new tests:** `node --test test/panel.test.js`
**Full suite:** `npm test`

---

## 🚦 Confirmation

Review the plan at `docs/devflow/features/2026-09-17-project-panel-tasks-tab-feature-plan.md`.
If approved, the Feature Agent will implement each task following TDD (Red → Green).
