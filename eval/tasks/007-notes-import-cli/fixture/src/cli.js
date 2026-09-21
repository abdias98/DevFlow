'use strict';

const { createStore, NoteError } = require('./store');

const USAGE = 'usage: notes <add <id> <title> | list>\n';

// Pure entry point: returns what the process should print and exit with, so it
// can be tested without spawning anything.
function run(argv, { file }) {
  const [command, ...rest] = argv;
  const store = createStore(file);
  try {
    if (command === 'add') {
      const [id, ...title] = rest;
      store.add({ id, title: title.join(' ') });
      return { code: 0, stdout: `added ${id}\n`, stderr: '' };
    }
    if (command === 'list') {
      const lines = store.readAll().map((note) => `${note.id}: ${note.title}`);
      return { code: 0, stdout: lines.length ? `${lines.join('\n')}\n` : '', stderr: '' };
    }
    return { code: 1, stdout: '', stderr: USAGE };
  } catch (err) {
    if (err instanceof NoteError) return { code: 1, stdout: '', stderr: `${err.message}\n` };
    throw err;
  }
}

module.exports = { run, USAGE };
