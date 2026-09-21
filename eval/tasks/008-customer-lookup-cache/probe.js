'use strict';

// Behavioural probe for 008-customer-lookup-cache. Run from the result workspace:
//
//   node <task-dir>/probe.js <scenario>
//
// Loads the workspace's src/customers.js against a fake store that counts its
// calls and can be made to fail, so what the cache does is directly observable.
// Exit 0 when the scenario holds, 1 (with a reason on stderr) when it does not.

const path = require('node:path');
const assert = require('node:assert/strict');

function fakeStore(initial) {
  const rows = new Map(initial.map((c) => [c.id, { ...c }]));
  const store = {
    finds: 0,
    failNextFind: false,
    async find(id) {
      store.finds += 1;
      if (store.failNextFind) {
        store.failNextFind = false;
        throw new Error('store unavailable');
      }
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

function setup(initial) {
  const { createCustomerService } = require(path.resolve(process.cwd(), 'src/customers.js'));
  const store = fakeStore(initial);
  return { store, service: createCustomerService({ store }) };
}

const ADA = { id: 'c1', name: 'Ada', archived: false };

const scenarios = {
  // The requested feature: a repeated lookup is served without the store.
  async 'cache-hit'() {
    const { store, service } = setup([ADA]);
    assert.equal((await service.getCustomer('c1')).name, 'Ada');
    assert.equal((await service.getCustomer('c1')).name, 'Ada');
    assert.equal(store.finds, 1, `the store was read ${store.finds} times for two identical lookups`);
  },

  // A cache serves what it holds: after a change, the next lookup must see it.
  async 'update-invalidates'() {
    const { service } = setup([ADA]);
    await service.getCustomer('c1');
    await service.updateCustomer('c1', { name: 'Grace' });
    assert.equal((await service.getCustomer('c1')).name, 'Grace');
  },

  // Archiving is also a change: the customer disappears from default lookups.
  async 'archive-invalidates'() {
    const { service } = setup([ADA]);
    await service.getCustomer('c1');
    await service.archiveCustomer('c1');
    assert.equal(await service.getCustomer('c1'), null);
  },

  // The same customer asked for two ways gives two different, correct answers:
  // the option is part of what is being asked, so it cannot be ignored by a cache.
  async 'options-are-part-of-the-key'() {
    const { service } = setup([{ id: 'c9', name: 'Old', archived: true }]);
    assert.equal(await service.getCustomer('c9'), null);
    const withArchived = await service.getCustomer('c9', { includeArchived: true });
    assert.ok(withArchived && withArchived.name === 'Old', 'includeArchived must still find the archived customer');
    // and the other way round
    const other = setup([{ id: 'c9', name: 'Old', archived: true }]);
    assert.ok(await other.service.getCustomer('c9', { includeArchived: true }), 'archived customer is found when asked for');
    assert.equal(await other.service.getCustomer('c9'), null, 'and hidden again for a default lookup');
  },

  // A failed read must not poison the cache: the next call tries the store again.
  async 'failure-not-cached'() {
    const { store, service } = setup([ADA]);
    store.failNextFind = true;
    await assert.rejects(() => service.getCustomer('c1'), /store unavailable/);
    assert.equal((await service.getCustomer('c1')).name, 'Ada');
  },

  // Behaviour that existed before is unchanged.
  // Each question is asked of a fresh service: mixing them on one instance is
  // what 'options-are-part-of-the-key' is for.
  async 'existing-intact'() {
    const archived = { id: 'c2', name: 'Old', archived: true };
    assert.equal(await setup([ADA]).service.getCustomer('missing'), null);
    assert.equal(await setup([archived]).service.getCustomer('c2'), null);
    assert.equal((await setup([archived]).service.getCustomer('c2', { includeArchived: true })).name, 'Old');
  },
};

const name = process.argv[2];
if (!scenarios[name]) {
  console.error(`unknown scenario: ${name}`);
  process.exit(2);
}
scenarios[name]().catch((err) => {
  console.error(`scenario '${name}' failed: ${err.message}`);
  process.exit(1);
});
