#!/bin/sh
# Hold the app port with a process that is not the service. Usage: setup.sh <workdir> <port>
set -eu
W="$1"; P="$2"
PORT=$P nohup node -e '
require("http").createServer((q,r)=>{r.writeHead(503);r.end("busy")}).listen(Number(process.env.PORT),"0.0.0.0",()=>console.log("up"));
' >"$W/blocker.log" 2>&1 &
echo $! > "$W/blocker.pid"
for i in 1 2 3 4 5 6 7 8 9 10; do
  grep -q up "$W/blocker.log" && exit 0; sleep 1
done
echo "blocker did not start" >&2; exit 1
