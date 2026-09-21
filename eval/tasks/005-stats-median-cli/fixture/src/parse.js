'use strict';

// A usage error is the user's mistake, not a crash: the CLI reports it on
// stderr and exits 1.
class UsageError extends Error {}

// Every argument after the command name must be a finite number. The offending
// argument is named so the user can find it.
function parseNumbers(args) {
  return args.map((arg) => {
    const value = Number(arg);
    if (arg.trim() === '' || !Number.isFinite(value)) {
      throw new UsageError(`not a number: ${arg}`);
    }
    return value;
  });
}

module.exports = { parseNumbers, UsageError };
