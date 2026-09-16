'use strict';

// CORRECT reference — claims the order (pending → paying) synchronously before
// the charge is awaited, so a concurrent or repeated payment sees a non-pending
// order; a declined charge releases the claim back to pending.

const payments = require('./payments');

const orders = new Map();
let nextId = 1;

class ValidationError extends Error {
  constructor(message) { super(message); this.name = 'ValidationError'; }
}
class NotFoundError extends Error {
  constructor(message) { super(message); this.name = 'NotFoundError'; }
}
class InvalidTransitionError extends Error {
  constructor(message) { super(message); this.name = 'InvalidTransitionError'; }
}

function createOrder({ amount }) {
  if (!Number.isInteger(amount) || amount <= 0) {
    throw new ValidationError('amount must be a positive integer');
  }
  const order = { id: String(nextId++), amount, status: 'pending' };
  orders.set(order.id, order);
  return { ...order };
}

function getOrder(id) {
  const order = orders.get(id);
  if (!order) return null;
  // 'paying' is an internal claim, not a state the API exposes.
  return { ...order, status: order.status === 'paying' ? 'pending' : order.status };
}

function requirePending(id) {
  const order = orders.get(id);
  if (!order) throw new NotFoundError('order not found');
  if (order.status !== 'pending') throw new InvalidTransitionError(`order is ${order.status}`);
  return order;
}

async function payOrder(id) {
  const order = requirePending(id);
  order.status = 'paying';
  try {
    await payments.charge(order.id, order.amount);
  } catch (err) {
    order.status = 'pending';
    throw err;
  }
  order.status = 'paid';
  return { ...order };
}

function cancelOrder(id) {
  const order = requirePending(id);
  order.status = 'cancelled';
  return { ...order };
}

module.exports = {
  createOrder, getOrder, payOrder, cancelOrder,
  ValidationError, NotFoundError, InvalidTransitionError,
};
