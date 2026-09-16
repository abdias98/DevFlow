'use strict';

const http = require('node:http');
const orders = require('./orders');
const payments = require('./payments');

function send(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(body === undefined ? '' : JSON.stringify(body));
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => { raw += chunk; });
    req.on('end', () => {
      if (raw === '') return resolve({});
      try {
        resolve(JSON.parse(raw));
      } catch {
        reject(new orders.ValidationError('body must be valid JSON'));
      }
    });
    req.on('error', reject);
  });
}

// Routes: [method, pattern, handler(req, res, params)]
const routes = [
  ['POST', /^\/orders$/, async (req, res) => {
    const body = await readJson(req);
    send(res, 201, orders.createOrder(body));
  }],
  ['GET', /^\/orders\/([^/]+)$/, async (req, res, [id]) => {
    const order = orders.getOrder(id);
    if (!order) return send(res, 404, { error: 'order not found' });
    send(res, 200, order);
  }],
  // Finance reconciliation view of every successful charge.
  ['GET', /^\/ledger$/, async (req, res) => {
    send(res, 200, payments.listCharges());
  }],
];

async function handle(req, res) {
  const path = new URL(req.url, 'http://localhost').pathname;
  for (const [method, pattern, handler] of routes) {
    const match = path.match(pattern);
    if (match && req.method === method) {
      try {
        await handler(req, res, match.slice(1));
      } catch (err) {
        if (err instanceof orders.ValidationError) return send(res, 400, { error: err.message });
        console.error(err);
        send(res, 500, { error: 'internal error' });
      }
      return;
    }
  }
  send(res, 404, { error: 'not found' });
}

function createServer() {
  return http.createServer(handle);
}

if (require.main === module) {
  const port = Number(process.env.PORT) || 3000;
  createServer().listen(port, () => console.log(`order-service listening on ${port}`));
}

module.exports = { createServer };
