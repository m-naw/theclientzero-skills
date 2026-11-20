#!/bin/sh
# Local tests: start the server on a free port, check /health and /users.
set -eu
cd "$(dirname "$0")/.."
PORT=$(node -e 'const s=require("net").createServer().listen(0,()=>{console.log(s.address().port);s.close()})')
PORT=$PORT node server.js >/dev/null 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT
PORT=$PORT node -e '
const get = async (p) => { for (let i = 0; i < 50; i++) { try { return await fetch("http://127.0.0.1:" + process.env.PORT + p); } catch (e) { await new Promise(r => setTimeout(r, 100)); } } throw new Error("server not up"); };
(async () => {
  const h = await get("/health"); if (h.status !== 200) throw new Error("health " + h.status);
  const u = await (await get("/users")).json();
  if (!Array.isArray(u.users) || !u.users.every(x => x.id !== undefined && x.name)) throw new Error("bad /users shape");
  console.log("visible tests passed");
})().catch(e => { console.error(e.message); process.exit(1); });
'
