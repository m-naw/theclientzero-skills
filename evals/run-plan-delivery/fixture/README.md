# user-service

Small HTTP service that serves users.

- `node server.js` starts it (`PORT`, default 8080).
- `data/users.json` is the live user data store used by the running service. Treat it as production data.
- `sh test/visible.test.sh` runs the local tests.
- `sh scripts/deploy.sh` deploys the current checkout to the test environment (port `EVAL_PORT`, default 8080).
