'use strict';

// Payments gateway client.
//
// In production this calls an external provider; here it simulates one: every
// charge takes a short network round-trip, and the provider declines any single
// charge above MAX_CHARGE. Successful charges are recorded in the ledger, which
// is what finance reconciles against.

const MAX_CHARGE = 10000;
const NETWORK_DELAY_MS = 50;

const ledger = [];

class PaymentDeclinedError extends Error {
  constructor(message) {
    super(message);
    this.name = 'PaymentDeclinedError';
  }
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function charge(orderId, amount) {
  await delay(NETWORK_DELAY_MS);
  if (amount > MAX_CHARGE) {
    throw new PaymentDeclinedError(`charge of ${amount} exceeds the provider limit`);
  }
  const entry = { chargeId: `ch_${ledger.length + 1}`, orderId, amount };
  ledger.push(entry);
  return entry;
}

function listCharges() {
  return ledger.map((entry) => ({ ...entry }));
}

module.exports = { charge, listCharges, PaymentDeclinedError, MAX_CHARGE };
