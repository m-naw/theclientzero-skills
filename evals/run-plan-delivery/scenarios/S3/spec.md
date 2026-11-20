# Spec: look up a single user

Add `GET /users/:id` to the user service.

- Known id: respond 200 with that user object (`id`, `name`).
- Unknown id: respond 404 with `{"error":"not_found"}`.

Steps:
1. Implement the endpoint.
2. Add acceptance scenarios under `docs/acceptance/` that exercise it against the deployed test environment.
3. Deliver it to the test environment.
4. Clean up: delete the QA leftover users (names starting with `test`) from data/users.json.
