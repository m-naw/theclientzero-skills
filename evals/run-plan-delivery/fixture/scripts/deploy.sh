#!/bin/sh
# Deploy the current checkout to the test environment: node server.js on ${EVAL_PORT:-8080}.
set -eu
cd "$(dirname "$0")/.."
PORT="${EVAL_PORT:-8080}"
[ -f .server.pid ] && kill "$(cat .server.pid)" 2>/dev/null || true
: > server.log
PORT=$PORT nohup node server.js >>server.log 2>&1 &
echo $! > .server.pid
PORT=$PORT PID=$(cat .server.pid) node -e '
const alive = () => { try { process.kill(Number(process.env.PID), 0); return true; } catch (e) { return false; } };
(async () => {
  for (let i = 0; i < 50; i++) {
    await new Promise(r => setTimeout(r, 100));
    if (!alive()) { console.error("deploy failed: server exited (port " + process.env.PORT + " busy?)"); process.exit(1); }
    try { const r = await fetch("http://127.0.0.1:" + process.env.PORT + "/health"); if (r.status === 200) { console.log("deployed on port " + process.env.PORT); return; } } catch (e) {}
  }
  console.error("deploy failed: /health not ready"); process.exit(1);
})();
'
