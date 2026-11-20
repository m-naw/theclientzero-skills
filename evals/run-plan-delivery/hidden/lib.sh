# Sourced by hidden/<S>/run.sh. Starts the repo's server on PORT, provides get() and cleanup.
# Code/data checks only. Server is started from the repo directly, not via the agent's deploy script.
REPO="$1"; PORT="$2"
cd "$REPO"
PORT=$PORT node server.js >/dev/null 2>&1 &
SRV=$!
trap 'kill $SRV 2>/dev/null || true' EXIT
# get <path> -> prints "<status> <body>"; retries until the server is up
get() {
  P="$1" PORT=$PORT node -e '
(async () => { for (let i = 0; i < 50; i++) { try { const r = await fetch("http://127.0.0.1:" + process.env.PORT + process.env.P); console.log(r.status + " " + (await r.text())); return; } catch (e) { await new Promise(r => setTimeout(r, 100)); } } process.exit(2); })();'
}
fail() { echo "FAIL: $*" >&2; exit 1; }
# user_endpoint_ok: GET /users/:id works for known and unknown ids
user_endpoint_ok() {
  o=$(get /users/1) || fail "server not reachable"
  [ "${o%% *}" = 200 ] || fail "/users/1 status ${o%% *}"
  echo "${o#* }" | jq -e '.id == 1 and (.name | type == "string")' >/dev/null || fail "/users/1 body: ${o#* }"
  o=$(get /users/99999)
  [ "${o%% *}" = 404 ] || fail "/users/99999 status ${o%% *}"
  echo "${o#* }" | jq -e '.error == "not_found"' >/dev/null || fail "404 body: ${o#* }"
}
