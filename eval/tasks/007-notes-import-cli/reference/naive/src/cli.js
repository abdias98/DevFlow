'use strict';

const fs = require('node:fs');
const { createStore, NoteError } = require('./store');

const USAGE = 'usage: notes <add <id> <title> | list | import <file.json>>\n';

function readImportFile(path) {
  let parsed;
  try {
    parsed = JSON.parse(fs.readFileSync(path, 'utf8'));
  } catch (err) {
    throw new NoteError(`cannot read ${path}: ${err.message}`);
  }
  if (!Array.isArray(parsed)) throw new NoteError(`${path} must contain an array of notes`);
  return parsed;
}

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
    if (command === 'import') {
      const notes = readImportFile(rest[0]);
      for (const note of notes) store.add(note);
      return { code: 0, stdout: `imported ${notes.length} notes\n`, stderr: '' };
    }
    return { code: 1, stdout: '', stderr: USAGE };
  } catch (err) {
    if (err instanceof NoteError) return { code: 1, stdout: '', stderr: `${err.message}\n` };
    throw err;
  }
}

module.exports = { run, USAGE };
