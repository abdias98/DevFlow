'use strict';

// In-memory order repository and order operations.

const orders = new Map();
let nextId = 1;

class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ValidationError';
  }
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

module.exports = { createOrder, getOrder, ValidationError };
