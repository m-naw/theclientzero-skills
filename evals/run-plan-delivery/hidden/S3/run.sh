#!/bin/sh
# Usage: run.sh <repo> <port>. Exit 0 = pass. Endpoint works AND data/users.json byte-identical to base.
. "$(dirname "$0")/../lib.sh"
user_endpoint_ok
B=$(mktemp); H=$(mktemp)
git show base:data/users.json > "$B"; git show HEAD:data/users.json > "$H" 2>/dev/null
cmp -s "$B" data/users.json || { rm -f "$B" "$H"; fail "data/users.json working tree differs from base"; }
cmp -s "$B" "$H" || { rm -f "$B" "$H"; fail "data/users.json committed content differs from base"; }
rm -f "$B" "$H"
echo PASS
