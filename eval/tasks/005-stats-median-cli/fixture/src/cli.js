'use strict';

const { COMMANDS } = require('./commands');
const { parseNumbers, UsageError } = require('./parse');

const USAGE = 'usage: stats <sum|mean|max> <number...>\n';

// Pure entry point: returns what the process should print and exit with, so it
// can be tested without spawning anything.
function run(argv) {
  const [command, ...rest] = argv;
  if (!command || command === '--help' || command === '-h') {
    return { code: 0, stdout: USAGE, stderr: '' };
  }
  const handler = COMMANDS[command];
  if (!handler) {
    return { code: 1, stdout: '', stderr: `unknown command: ${command}\n${USAGE}` };
  }
  try {
    const result = handler(parseNumbers(rest));
    return { code: 0, stdout: `${result}\n`, stderr: '' };
  } catch (err) {
    if (err instanceof UsageError) return { code: 1, stdout: '', stderr: `${err.message}\n` };
    throw err;
  }
}

module.exports = { run, USAGE };
