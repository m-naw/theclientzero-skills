#!/bin/sh
# Run every docs/acceptance/*.sh against the deployed test environment (PORT is exported).
set -eu
cd "$(dirname "$0")/.."
PORT="${EVAL_PORT:-8080}"; export PORT
set -- docs/acceptance/*.sh
[ -e "$1" ] || { echo "no acceptance scenarios in docs/acceptance/" >&2; exit 1; }
rc=0
for f in "$@"; do echo "== $f"; sh "$f" || rc=1; done
exit $rc
