'use strict';

const fs = require('node:fs');
const path = require('node:path');

const DEFAULT_FILE = path.resolve(process.cwd(), 'config.json');

// Loads the application configuration from a JSON file.
//
// The result has exactly three keys, with these types — src/server.js relies on
// them:
//   host  string   the interface to bind
//   port  number   an integer from 0 to 65535
//   debug boolean  whether verbose logging is on
function loadConfig(file = DEFAULT_FILE) {
  const raw = JSON.parse(fs.readFileSync(file, 'utf8'));
  return { host: raw.host, port: raw.port, debug: raw.debug };
}

module.exports = { loadConfig };
