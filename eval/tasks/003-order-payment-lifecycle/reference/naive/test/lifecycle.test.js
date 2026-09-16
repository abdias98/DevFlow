'use strict';

// Reference overlay — the tests a straightforward implementation would add.

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

async function post(path, body) {
  const res = await fetch(baseUrl + path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

test('pay marks a pending order as paid', async () => {
  const order = await post('/orders', { amount: 10 });
  const res = await post(`/orders/${order.body.id}/pay`);
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'paid');
});

test('cancel marks a pending order as cancelled', async () => {
  const order = await post('/orders', { amount: 10 });
  const res = await post(`/orders/${order.body.id}/cancel`);
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'cancelled');
});
