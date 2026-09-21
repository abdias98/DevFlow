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
  const cache = new Map();

  return {
    // Resolves the customer, or null when there is none (or it is archived and
    // includeArchived is not set).
    async getCustomer(id, { includeArchived = false } = {}) {
      if (cache.has(id)) return cache.get(id);
      const customer = await store.find(id);
      const result = !customer || (customer.archived && !includeArchived) ? null : customer;
      cache.set(id, result);
      return result;
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
