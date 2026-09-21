#!/usr/bin/env node
'use strict';

const path = require('node:path');
const { run } = require('../src/cli');

const file = path.resolve(process.env.NOTES_FILE || 'notes.json');
const { code, stdout, stderr } = run(process.argv.slice(2), { file });
if (stdout) process.stdout.write(stdout);
if (stderr) process.stderr.write(stderr);
process.exitCode = code;
