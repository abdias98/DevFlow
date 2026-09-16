'use strict';

// HTTP client for the project backend. The panel receives it by injection, so
// tests pass a fake with the same method names.

function createApi({ baseUrl, fetchImpl = fetch }) {
  async function getJson(path) {
    const res = await fetchImpl(`${baseUrl}${path}`);
    if (!res.ok) throw new Error(`GET ${path} failed with ${res.status}`);
    return res.json();
  }

  return {
    getOverview: (projectId) => getJson(`/api/projects/${encodeURIComponent(projectId)}/overview`),
    getTasks: (projectId) => getJson(`/api/projects/${encodeURIComponent(projectId)}/tasks`),
  };
}

module.exports = { createApi };
