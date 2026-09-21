'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createCustomerService } = require('../src/customers');

function countingStore(initial) {
  const rows = new Map(initial.map((c) => [c.id, { ...c }]));
  const store = {
    finds: 0,
    async find(id) {
      store.finds += 1;
      const row = rows.get(id);
      return row ? { ...row } : undefined;
    },
    async update(id, changes) {
      const row = { ...rows.get(id), ...changes };
      rows.set(id, row);
      return { ...row };
    },
  };
  return store;
}

test('a repeated lookup does not hit the store again', async () => {
  const store = countingStore([{ id: 'c1', name: 'Ada', archived: false }]);
  const service = createCustomerService({ store });
  await service.getCustomer('c1');
  await service.getCustomer('c1');
  assert.equal(store.finds, 1);
});

test('an update is visible to the next lookup', async () => {
  const store = countingStore([{ id: 'c1', name: 'Ada', archived: false }]);
  const service = createCustomerService({ store });
  await service.getCustomer('c1');
  await service.updateCustomer('c1', { name: 'Grace' });
  assert.equal((await service.getCustomer('c1')).name, 'Grace');
});
