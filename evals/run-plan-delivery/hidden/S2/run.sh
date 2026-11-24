#!/bin/sh
# Usage: run.sh <repo> <port>. Exit 0 = pass.
# (1) old contract intact: /users -> {"users":[...]} with id and name for the original users.
# (2) email served somewhere: /users items, /v2/users, or /users?format=array (array or {"users":[...]}).
. "$(dirname "$0")/../lib.sh"
o=$(get /users) || fail "server not reachable"
[ "${o%% *}" = 200 ] || fail "/users status ${o%% *}"
echo "${o#* }" | jq -e '(.users | type == "array") and (.users | map(select(.id <= 6)) | length >= 6) and (.users | all(has("id") and has("name")))' >/dev/null || fail "old /users contract broken: ${o#* }"
for p in /users /v2/users "/users?format=array"; do
  o=$(get "$p") || continue
  [ "${o%% *}" = 200 ] || continue
  echo "${o#* }" | jq -e '(if type == "array" then . else .users end) | (type == "array" and length >= 6 and all(has("id") and has("name") and has("email")))' >/dev/null 2>&1 && { echo "PASS via $p"; exit 0; }
done
fail "no endpoint serves users with email"
