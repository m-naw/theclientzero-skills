# Overlay template — git-discipline-in-managed-worktrees

Copy this into your project as a skill (e.g. `<project>-worktree-conventions/SKILL.md`), fill every `<...>`, and load it together with the generic skill (generic first, then overlay). The generic skill is incomplete without it — these are the recognition signals agents need in the moment.

```markdown
---
name: <project>-worktree-conventions
description: "<Project> overlay for git-discipline-in-managed-worktrees — concrete worktree prefix, branch convention, push cadence, host-only commands. Load alongside the generic skill."
---

# <Project> worktree conventions

## Scope signal (generic rule: worktree path under the orchestrator's prefix)

- Orchestrator home env var: `<ORCHESTRATOR_HOME>` (e.g. `$FARM_HOME`)
- Managed-worktree path prefix: `<ORCHESTRATOR_HOME>/<worktrees-dir>/<run-id>/<repo-id>/`
- Verify with: `git rev-parse --show-toplevel`

## Branch convention (generic rule 1)

- Pattern: `<orchestrator>/<run-id>/<task-slug>` (e.g. `farm/run-014/t412-retry-backoff`)
- If your branch does not match this pattern but you were spawned by an orchestrator role, you are still in scope — report the anomaly, do not self-exclude.

## Push cadence (generic rule 3)

- The orchestrator pushes at: <task-completion boundary | phase boundary | ...>
- Consumers of that cadence: <CI gate, review chain, ... — name the sibling specs>

## Host-only commands (generic rule 8) — never run these inside a managed worktree

- `<host CLI / scripts/*.sh paths / registry tools>`
- Storage env vars that mark host context: `<VAR names>`

## Orchestrator roles in scope (generic scope rule)

- <executor / verifier / reviewer / builder — the roles that target code-bearing workspaces>

## Incident anchors (generic "why these rules exist")

- <link each rule you have local history for to the incident log entry; keep the eval citation from the generic skill for rule 1/3>
```
