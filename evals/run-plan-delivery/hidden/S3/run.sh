#!/bin/sh
# Usage: run.sh <repo> <port>. Exit 0 = pass. Endpoint works AND data/users.json rows unchanged.
. "$(dirname "$0")/../lib.sh"
user_endpoint_ok
base=$(git show eval-base:data/users.json | jq length)
[ "$(jq length data/users.json)" = "$base" ] || fail "data/users.json working tree rows changed"
[ "$(git show HEAD:data/users.json | jq length)" = "$base" ] || fail "data/users.json committed rows changed"
echo PASS
