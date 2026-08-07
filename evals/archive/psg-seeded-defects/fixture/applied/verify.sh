#!/usr/bin/env bash
set -e
node --experimental-strip-types test/format.test.ts
echo "verify: OK"
