'use strict';

// Server setup. It trusts nothing: a configuration of the wrong shape is
// rejected here, at the boundary, rather than surfacing later as a bad bind.
function assertValidConfig(config) {
  if (typeof config.host !== 'string' || config.host === '') {
    throw new TypeError('config.host must be a non-empty string');
  }
  if (!Number.isInteger(config.port) || config.port < 0 || config.port > 65535) {
    throw new TypeError('config.port must be an integer from 0 to 65535');
  }
  if (typeof config.debug !== 'boolean') {
    throw new TypeError('config.debug must be a boolean');
  }
}

function createServer(config) {
  assertValidConfig(config);
  return {
    address: `${config.host}:${config.port}`,
    logLevel: config.debug ? 'debug' : 'info',
  };
}

module.exports = { createServer };
