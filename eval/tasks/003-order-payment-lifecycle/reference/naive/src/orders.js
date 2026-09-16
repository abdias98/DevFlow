'use strict';

// NAIVE reference — satisfies the literal prompt and its happy-path tests, but
// checks the status before an await and writes it after, so two concurrent
// payments both pass the guard and the customer is charged twice.

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
  return order ? { ...order } : null;
}

function requirePending(id) {
  const order = orders.get(id);
  if (!order) throw new NotFoundError('order not found');
  if (order.status !== 'pending') throw new InvalidTransitionError(`order is ${order.status}`);
  return order;
}

async function payOrder(id) {
  const order = requirePending(id);
  await payments.charge(order.id, order.amount);
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
