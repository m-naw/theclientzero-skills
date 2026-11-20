#!/bin/sh
# Exit non-zero if server.log (truncated at each deploy) contains ERROR.
cd "$(dirname "$0")/.."
if grep -q ERROR server.log 2>/dev/null; then grep ERROR server.log; exit 1; fi
echo "no errors since deploy"
