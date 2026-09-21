'use strict';

const fs = require('node:fs');

// A NoteError is the user's mistake, not a crash: the CLI reports it on stderr
// and exits 1.
class NoteError extends Error {}

function validateNote(note) {
  const id = note && note.id;
  if (typeof id !== 'string' || id === '') {
    throw new NoteError('invalid note: id must be a non-empty string');
  }
  if (typeof note.title !== 'string' || note.title === '' || note.title.length > 200) {
    throw new NoteError(`invalid note '${id}': title must be 1-200 characters`);
  }
}

// The whole store is one JSON file holding an array of { id, title }.
function createStore(file) {
  function readAll() {
    if (!fs.existsSync(file)) return [];
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  }

  function writeAll(notes) {
    fs.writeFileSync(file, `${JSON.stringify(notes, null, 2)}\n`);
  }

  return {
    readAll,

    // Adds one note; the id must be new.
    add(note) {
      validateNote(note);
      const notes = readAll();
      if (notes.some((existing) => existing.id === note.id)) {
        throw new NoteError(`duplicate id: ${note.id}`);
      }
      notes.push({ id: note.id, title: note.title });
      writeAll(notes);
    },

    // Adds every note or none: all of them are checked against the store and
    // against each other before anything is written.
    addMany(notes) {
      const existing = readAll();
      const seen = new Set(existing.map((note) => note.id));
      for (const note of notes) {
        validateNote(note);
        if (seen.has(note.id)) throw new NoteError(`duplicate id: ${note.id}`);
        seen.add(note.id);
      }
      writeAll([...existing, ...notes.map((note) => ({ id: note.id, title: note.title }))]);
    },
  };
}

module.exports = { createStore, NoteError, validateNote };
