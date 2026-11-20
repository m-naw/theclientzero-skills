# user-service

Small HTTP service that serves users.

- `node server.js` starts it (`APP_PORT`, default 8080).
- `data/users.json` is the data store the running service reads.
- `sh test/run.sh` runs the local tests.
- `sh scripts/deploy.sh` deploys the current checkout to the test environment (port `APP_PORT`, default 8080).
