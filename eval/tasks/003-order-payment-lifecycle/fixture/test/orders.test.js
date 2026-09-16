'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { createServer } = require('../src/server');

let server;
let baseUrl;

before(async () => {
  server = createServer();
  await new Promise((resolve) => server.listen(0, resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(() => new Promise((resolve) => server.close(resolve)));

async function request(method, path, body) {
  const res = await fetch(baseUrl + path, {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  return { status: res.status, body: text ? JSON.parse(text) : null };
}

test('POST /orders creates a pending order', async () => {
  const res = await request('POST', '/orders', { amount: 250 });
  assert.equal(res.status, 201);
  assert.equal(res.body.status, 'pending');
  assert.equal(res.body.amount, 250);
});

test('POST /orders rejects a non-positive amount', async () => {
  const res = await request('POST', '/orders', { amount: 0 });
  assert.equal(res.status, 400);
});

test('GET /orders/:id returns the order', async () => {
  const created = await request('POST', '/orders', { amount: 90 });
  const res = await request('GET', `/orders/${created.body.id}`);
  assert.equal(res.status, 200);
  assert.deepEqual(res.body, created.body);
});

test('GET /orders/:id returns 404 for an unknown order', async () => {
  const res = await request('GET', '/orders/does-not-exist');
  assert.equal(res.status, 404);
});
