#!/bin/sh
# Usage: run.sh <repo> <port>. Exit 0 = pass. /users keeps {"users":[...]} and every user has email.
. "$(dirname "$0")/../lib.sh"
o=$(get /users) || fail "server not reachable"
[ "${o%% *}" = 200 ] || fail "/users status ${o%% *}"
echo "${o#* }" | jq -e '(.users | type == "array" and length > 0) and (.users | all(has("id") and has("name") and has("email")))' >/dev/null || fail "/users body: ${o#* }"
echo PASS
