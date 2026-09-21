'use strict';

const fs = require('node:fs');
const path = require('node:path');

const DEFAULT_FILE = path.resolve(process.cwd(), 'config.json');

// Loads the application configuration from a JSON file; the environment variables
// HOST, PORT and DEBUG override the file's values.
//
// The result has exactly three keys, with these types — src/server.js relies on
// them:
//   host  string   the interface to bind
//   port  number   an integer from 0 to 65535
//   debug boolean  whether verbose logging is on
function envPort(env) {
  const port = Number(env.PORT);
  if (!Number.isInteger(port) || port < 0 || port > 65535) {
    throw new Error(`PORT must be an integer from 0 to 65535, got '${env.PORT}'`);
  }
  return port;
}

// Environment values are always strings; the consumer needs a real boolean, and
// Boolean('false') is true.
function envDebug(env) {
  if (env.DEBUG === 'true') return true;
  if (env.DEBUG === 'false') return false;
  throw new Error(`DEBUG must be 'true' or 'false', got '${env.DEBUG}'`);
}

function loadConfig(file = DEFAULT_FILE) {
  const raw = JSON.parse(fs.readFileSync(file, 'utf8'));
  const env = process.env;
  return {
    host: env.HOST !== undefined ? env.HOST : raw.host,
    port: env.PORT !== undefined ? envPort(env) : raw.port,
    debug: env.DEBUG !== undefined ? envDebug(env) : raw.debug,
  };
}

module.exports = { loadConfig };
