# Git Discipline in Managed Worktrees

<!-- GUTTED CANARY VARIANT (arm D) — rules 1–3 and push/sync/hook references removed;
     rules 4–8 kept. Never ship this file as a skill. -->

## Overview

You are operating inside a **managed worktree** that an orchestrator created for one unit of work. The orchestrator owns the lifecycle around your work — canonical clone, worktree creation, cleanup. Your scope is feature-branch work: read, plan, edit, commit, hand off.

## Project overlay required

This skill is generic. A project overlay supplies the concrete worktree-path prefix, host-only command list, and branch convention.

## Scope

Applies when your worktree path is under the orchestrator's managed-worktree prefix, or you were spawned by an orchestrator role targeting a managed workspace.

## Rules

### 4. Commit at every meaningful unit; never leave the working tree dirty across task boundaries

Every recordable unit of work gets its own commit before the next unit begins. Anything not committed when the task ends is invisible to the rest of the system. Run `git status` before declaring a task done — the output should be `nothing to commit, working tree clean`. Do not stash: stashes are local to your worktree and do not survive worktree removal at PR-open time. Do not commit ignorable artifacts — fix the ignore rule instead.

### 5. Use `git rm <path>` for tracked deletions

`rm <path>` removes the file from the working tree but leaves it in the index; the next commit then carries an incoherent state and subsequent reverts fail in surprising ways. For tracked files use `git rm <path>` (or `git rm -r <dir>`); for moves use `git mv`.

### 6. Two-actor review for every recordable decision

Every ADR, spec, plan, and commit you produce gets an independent reviewer who confirms it follows the constitution and the spec it implements. Cite proof for every claim — file:line, test name, command output, or external source.

### 7. Do NOT merge or close PRs from the agent

Merge is always escalated to a human per the orchestrator's PR-escalation contract. No `gh pr create`, `gh pr merge`, `gh pr close`, or forge-API equivalents.

### 8. Host-only commands do NOT run inside managed worktrees

Host-repo automation assumes the host's directory layout, hook chain, and remote configuration. The project overlay enumerates the specific commands. When in doubt, escalate.

## Red flags and rationalizations

| Excuse / Red flag | Reality |
|---|---|
| "I'll `rm` instead of `git rm`, I'll fix it in a follow-up" | The next unit's review step sees a dirty index and fails the handoff. There is no "follow-up" — the run halts here. |
| "I'll `git stash` this and pop it after the next task" | The stash is local to your worktree; the worktree is removed when the orchestrator opens the PR. Commit instead. |
| "Two-actor review is overhead for a small change" | Triviality is not yours to declare. Self-declared trivial is the gameable surface the rule exists to block. |
| "The PR looks good, I'll `gh pr merge --auto` to close the loop" | Merge is always escalated to a human. Same for `gh pr close`. |
| "This host-only command works the same in any git repo" | It depends on the host's directory layout and hook chain. If a tool smells host-only, escalate. |

All of these mean: stop, re-read the relevant rule, and follow the orchestrator's intended flow.
