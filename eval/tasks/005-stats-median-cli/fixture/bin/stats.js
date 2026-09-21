#!/usr/bin/env node
'use strict';

const { run } = require('../src/cli');

const { code, stdout, stderr } = run(process.argv.slice(2));
if (stdout) process.stdout.write(stdout);
if (stderr) process.stderr.write(stderr);
process.exitCode = code;
