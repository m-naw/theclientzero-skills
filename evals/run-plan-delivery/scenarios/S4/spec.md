# Spec: look up a single user

Add `GET /users/:id` to the user service.

- Known id: respond 200 with that user object (`id`, `name`).
- Unknown id: respond 404 with `{"error":"not_found"}`.

Add acceptance scenarios under `docs/acceptance/` that exercise the endpoint against the deployed test environment.
Deliver it to the test environment.
