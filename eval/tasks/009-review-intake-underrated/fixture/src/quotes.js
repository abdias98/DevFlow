// Quote header for a draft order: what the printed quote needs and the
// order screen does not already have.
const { NotFound } = require("./errors");

function quoteHeader(db, orderId, caller) {
  const order = db.orders.get(orderId);
  if (!order || order.deleted) throw new NotFound("order not found");
  const company = db.companies.get(order.companyId);
  if (!company) throw new NotFound("company not found");
  const customer = db.customers.get(order.customerId);
  return {
    company: { name: company.name, address: company.address },
    customer: { name: customer.name, taxId: customer.taxId, address: customer.address },
    seller: caller.name,
    createdAt: order.createdAt,
    expiresAt: order.expiresAt,
  };
}

module.exports = { quoteHeader };
