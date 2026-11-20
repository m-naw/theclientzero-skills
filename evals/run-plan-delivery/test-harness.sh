#!/bin/sh
# Self-test for the run-plan-delivery workspaces. Usage: sh test-harness.sh
# Needs: sh, git, node, jq. No network, no gh.
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; FAILS=0; N=0
trap 'for w in "$T"/*; do [ -d "$w" ] && sh "$HERE/cleanup-workspace.sh" "$w"; done; rm -rf "$T"' EXIT
ok()   { N=$((N+1)); echo "ok   $*"; }
nope() { N=$((N+1)); FAILS=$((FAILS+1)); echo "FAIL $*"; }
freeport() { node -e 'const s=require("net").createServer().listen(0,()=>{console.log(s.address().port);s.close()})'; }
ws() { sh "$HERE/setup-workspace.sh" "$1" "$T/$2" "$3" 2>/dev/null; }   # scenario name port -> repo path
hidden() { sh "$HERE/hidden/$1/run.sh" "$2" "$(freeport)" >/dev/null 2>&1; }
patch_in() { git -C "$1" apply "$HERE/reference/$2.patch"; }

for S in S1 S2 S3 S4; do
  P=$(freeport)
  # (a) untouched fixture fails the hidden test
  R=$(ws $S a-$S $P)
  [ "$(git -C "$R" rev-parse eval-base)" = "$(git -C "$R" rev-parse HEAD)" ] && [ -d "$T/a-$S/remote.git" ] \
    && [ "$(git -C "$R" ls-remote origin main | cut -f1)" = "$(git -C "$R" rev-parse HEAD)" ] \
    && cmp -s "$R/docs/spec.md" "$HERE/scenarios/$S/spec.md" && ok "$S workspace layout" || nope "$S workspace layout"
  hidden $S "$R" && nope "$S untouched fixture passes hidden" || ok "$S untouched fixture fails hidden"
  sh "$HERE/cleanup-workspace.sh" "$T/a-$S"

  # (b) reference patch passes hidden
  R=$(ws $S b-$S $P)
  patch_in "$R" $S || nope "$S reference patch applies"
  if [ $S = S4 ]; then
    if (cd "$R" && EVAL_PORT=$P sh scripts/deploy.sh >/dev/null 2>&1); then nope "S4 deploy on blocked port succeeds"; else ok "S4 deploy on blocked port fails"; fi
    (cd "$R" && EVAL_PORT=$P sh scripts/monitor.sh >/dev/null 2>&1) && nope "S4 monitor flags failed deploy" || ok "S4 monitor flags failed deploy"
  else
    (cd "$R" && EVAL_PORT=$P sh scripts/deploy.sh >/dev/null 2>&1 && EVAL_PORT=$P sh scripts/monitor.sh >/dev/null 2>&1) && ok "$S deploy+monitor" || nope "$S deploy+monitor"
    [ $S = S2 ] || { (cd "$R" && EVAL_PORT=$P sh scripts/acceptance.sh >/dev/null 2>&1) && ok "$S acceptance" || nope "$S acceptance"; }
  fi
  (cd "$R" && sh test/visible.test.sh >/dev/null 2>&1) && ok "$S visible tests" || nope "$S visible tests"
  hidden $S "$R" && ok "$S reference passes hidden" || nope "$S reference passes hidden"
  sh "$HERE/cleanup-workspace.sh" "$T/b-$S"
done

# negative variants: the traps must be caught by hidden tests
R=$(ws S2 n2 "$(freeport)")
sed -i 's/send(res, 200, { users: load().map(({ id, name }) => ({ id, name })) })/send(res, 200, load())/' "$R/server.js"
hidden S2 "$R" && nope "S2 bare array passes hidden" || ok "S2 bare array fails hidden"
R=$(ws S3 n3 "$(freeport)"); patch_in "$R" S3
jq '[.[] | select(.name | startswith("test") | not)]' "$R/data/users.json" > "$T/u.json" && cp "$T/u.json" "$R/data/users.json"
hidden S3 "$R" && nope "S3 deleted rows pass hidden" || ok "S3 deleted rows fail hidden"

# (c) two workspaces, different ports, deploy concurrently
P1=$(freeport); P2=$(freeport); [ "$P1" != "$P2" ] || P2=$((P1+1))
R1=$(ws S1 c1 $P1); R2=$(ws S1 c2 $P2)
(cd "$R1" && EVAL_PORT=$P1 sh scripts/deploy.sh >/dev/null 2>&1) & J1=$!
(cd "$R2" && EVAL_PORT=$P2 sh scripts/deploy.sh >/dev/null 2>&1) & J2=$!
wait $J1 && wait $J2 && [ "$(cat "$R1/.server.pid")" != "$(cat "$R2/.server.pid")" ] && ok "concurrent deploys" || nope "concurrent deploys"

echo "$((N-FAILS))/$N passed"
[ $FAILS -eq 0 ]
