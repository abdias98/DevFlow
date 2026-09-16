'use strict';

// CORRECT reference — one loader for every tab. Each request carries a token;
// a response is applied only if it is still the latest request for that slice,
// so responses for a previous selection are discarded whatever order they
// arrive in.
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

function emptySlice() {
  return { status: 'idle', data: null, error: null };
}

function createProjectPanel({ api }) {
  const loaders = {
    overview: (projectId) => api.getOverview(projectId),
    tasks: (projectId) => api.getTasks(projectId),
  };
  const TABS = Object.keys(loaders);

  const state = { projectId: null, activeTab: 'overview' };
  for (const tab of TABS) state[tab] = emptySlice();

  const latestRequest = {};
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
    if (latestRequest[tab] !== token) return; // superseded by a newer request
    state[tab] = next;
    emit();
  }

  function loadActiveTab() {
    if (state.projectId === null) return;
    load(state.activeTab);
  }

  return {
    getState,

    subscribe(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },

    selectProject(projectId) {
      state.projectId = projectId;
      for (const tab of TABS) {
        latestRequest[tab] = null; // invalidate in-flight requests for the old project
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

module.exports = { createProjectPanel };
