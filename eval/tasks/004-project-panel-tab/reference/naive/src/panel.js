'use strict';

// NAIVE reference — adds the Tasks tab by mirroring the Overview tab exactly,
// which also copies its latent flaw: nothing ties a response to the selection
// that requested it, so a slow response for a previous project wins.
//
// Project panel controller — the state layer behind the project page.
//
// The view renders getState() and forwards user input to selectProject() and
// selectTab(). Nothing in this module touches the DOM.
//
// Conventions:
// - Each tab owns a slice of state shaped { status, data, error }, where status
//   is 'idle' | 'loading' | 'ready' | 'error'.
// - A tab loads its data when it is the active tab and a project is selected.

const TABS = ['overview', 'tasks'];

function emptySlice() {
  return { status: 'idle', data: null, error: null };
}

function createProjectPanel({ api }) {
  const state = {
    projectId: null,
    activeTab: 'overview',
    overview: emptySlice(),
    tasks: emptySlice(),
  };
  const listeners = new Set();

  function getState() {
    return { ...state, overview: { ...state.overview }, tasks: { ...state.tasks } };
  }

  function emit() {
    const snapshot = getState();
    for (const listener of listeners) listener(snapshot);
  }

  async function loadOverview() {
    state.overview = { status: 'loading', data: null, error: null };
    emit();
    try {
      const data = await api.getOverview(state.projectId);
      state.overview = { status: 'ready', data, error: null };
    } catch (error) {
      state.overview = { status: 'error', data: null, error };
    }
    emit();
  }

  async function loadTasks() {
    state.tasks = { status: 'loading', data: null, error: null };
    emit();
    try {
      const data = await api.getTasks(state.projectId);
      state.tasks = { status: 'ready', data, error: null };
    } catch (error) {
      state.tasks = { status: 'error', data: null, error };
    }
    emit();
  }

  function loadActiveTab() {
    if (state.projectId === null) return;
    if (state.activeTab === 'overview') loadOverview();
    if (state.activeTab === 'tasks') loadTasks();
  }

  return {
    getState,

    subscribe(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },

    selectProject(projectId) {
      state.projectId = projectId;
      state.overview = emptySlice();
      state.tasks = emptySlice();
      loadActiveTab();
    },

    selectTab(name) {
      if (!TABS.includes(name)) throw new Error(`unknown tab: ${name}`);
      state.activeTab = name;
      loadActiveTab();
    },
  };
}

module.exports = { createProjectPanel };
