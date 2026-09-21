'use strict';

// Customer service over a slow store.
//
// The store is injected. It is the only slow part: every call to it is a round
// trip, and it may fail.
//   store.find(id)            -> Promise<customer | undefined>
//   store.update(id, changes) -> Promise<customer>
//
// A customer is { id, name, archived }. Archived customers are hidden from
// lookups unless the caller asks for them.
function createCustomerService({ store }) {
  // Caches what the slow call returns — the record — never a per-caller view of
  // it. Only successful reads are cached: a failed read is retried next time.
  const cache = new Map();

  async function find(id) {
    if (cache.has(id)) return cache.get(id);
    const customer = await store.find(id);
    cache.set(id, customer);
    return customer;
  }

  return {
    // Resolves the customer, or null when there is none (or it is archived and
    // includeArchived is not set).
    async getCustomer(id, { includeArchived = false } = {}) {
      const customer = await find(id);
      if (!customer) return null;
      if (customer.archived && !includeArchived) return null;
      return customer;
    },

    async updateCustomer(id, changes) {
      cache.delete(id);
      return store.update(id, changes);
    },

    async archiveCustomer(id) {
      cache.delete(id);
      return store.update(id, { archived: true });
    },
  };
}

module.exports = { createCustomerService };
