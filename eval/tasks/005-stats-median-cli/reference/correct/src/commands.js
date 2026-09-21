'use strict';

const { UsageError } = require('./parse');

// Each command receives the parsed numbers and returns a number.
//
// Convention: a command given no numbers is a usage error — never NaN,
// undefined or a crash. Every command goes through requireNumbers().
function requireNumbers(numbers, name) {
  if (numbers.length === 0) throw new UsageError(`${name}: no numbers given`);
  return numbers;
}

const COMMANDS = {
  sum: (numbers) => requireNumbers(numbers, 'sum').reduce((a, b) => a + b, 0),
  mean: (numbers) => {
    requireNumbers(numbers, 'mean');
    return numbers.reduce((a, b) => a + b, 0) / numbers.length;
  },
  max: (numbers) => Math.max(...requireNumbers(numbers, 'max')),
  median: (numbers) => {
    const sorted = [...numbers].sort((a, b) => a - b);
    requireNumbers(numbers, 'median');
    const mid = Math.floor(sorted.length / 2);
    return sorted.length % 2 === 1 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  },
};

module.exports = { COMMANDS, requireNumbers };
