'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createCustomerService } = require('../src/customers');

function fakeStore(initial) {
  const rows = new Map(initial.map((c) => [c.id, { ...c }]));
  return {
    async find(id) {
      const row = rows.get(id);
      return row ? { ...row } : undefined;
    },
    async update(id, changes) {
      const row = { ...rows.get(id), ...changes };
      rows.set(id, row);
      return { ...row };
    },
  };
}

test('getCustomer returns a customer', async () => {
  const service = createCustomerService({ store: fakeStore([{ id: 'c1', name: 'Ada', archived: false }]) });
  assert.equal((await service.getCustomer('c1')).name, 'Ada');
});

test('getCustomer returns null for an unknown customer', async () => {
  const service = createCustomerService({ store: fakeStore([]) });
  assert.equal(await service.getCustomer('nope'), null);
});

test('an archived customer is hidden from a default lookup', async () => {
  const service = createCustomerService({ store: fakeStore([{ id: 'c1', name: 'Ada', archived: true }]) });
  assert.equal(await service.getCustomer('c1'), null);
});

test('an archived customer is found when asked for', async () => {
  const service = createCustomerService({ store: fakeStore([{ id: 'c1', name: 'Ada', archived: true }]) });
  assert.equal((await service.getCustomer('c1', { includeArchived: true })).name, 'Ada');
});

test('updateCustomer changes what getCustomer returns', async () => {
  const service = createCustomerService({ store: fakeStore([{ id: 'c1', name: 'Ada', archived: false }]) });
  await service.updateCustomer('c1', { name: 'Grace' });
  assert.equal((await service.getCustomer('c1')).name, 'Grace');
});
