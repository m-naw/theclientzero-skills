---
name: git-discipline-in-managed-worktrees
description: "Use when an agent operates inside an orchestrator-managed feature-branch worktree — branch/hook/push/commit/deletion/review/PR rules; orchestrator owns lifecycle. Pair with a project overlay."
---

# Git Discipline in Managed Worktrees

## Overview

You are operating inside a **managed worktree** that an orchestrator created for one unit of work (a strategy, run, or task — naming depends on the project). The orchestrator owns the lifecycle around your work — canonical clone, worktree creation, push timing, PR escalation, cleanup. Your scope is **feature-branch work only**: read, plan, edit, commit, hand off.

This split exists because the orchestrator's view spans every workspace and every task in the run; you only see the slice in front of you. Anything that crosses that boundary (advancing `main`, touching the remote, modifying hook configuration, running host-only automation) breaks invariants you cannot see and degrades properties you cannot measure.

The rules below are the contract. Follow them exactly. Where this skill and an inline "discipline" block in the prompt overlap, **the rules are the same** — the inline block is a condensation; this SKILL is canonical.

## Project overlay required

This skill is **generic and incomplete by itself**. It MUST be paired with a project-specific overlay skill that supplies:

1. **The concrete worktree-path prefix** for scope detection (rule: "the agent's worktree path under whatever the orchestrator's home env var is" — your overlay names the env var and the prefix).
2. **The host-only command list** — the specific commands, scripts, and storage paths that must not run inside a managed worktree (rule 8 keeps the universal rule; the overlay enumerates the specific commands).
3. **The branch-name convention** the orchestrator uses (e.g. `<orchestrator>/<run-id>/<slug>`).
4. **The push cadence vocabulary** (e.g. "task-completion boundary", "phase boundary") and any sibling specs that consume that cadence.
5. **Project-specific recovery paths** and **failure-class memory citations** that anchor the rationale to past incidents.

Loaded together (generic first, then overlay), agents see the universal rule wording AND the project-specific anchors. Generic-only consumers — agents on a project that has not yet authored an overlay — get the rules but lose the in-the-moment recognition signals; that is a known degradation and the reason the overlay is not optional.

## Scope

Applies when **either** of the following is true:

- You are inside a worktree under the orchestrator's managed-worktree path prefix (verifiable: `git rev-parse --show-toplevel` returns a path under that prefix). **Your project overlay supplies the concrete prefix** — typically a path under whatever home env var the orchestrator uses for its storage (e.g. `<ORCHESTRATOR_HOME>/worktrees/<run-id>/<repo-id>/`). This is the primary structural signal.
- You were spawned by an orchestrator role that targets a managed workspace (a code-bearing workspace; the project overlay names the specific roles — e.g. executor/verifier/reviewer in one orchestrator, builder/tester/approver in another), even if the worktree path or branch name look unexpected (corruption, manual operator intervention, recovery edge case). Self-exclusion on a malformed branch name when you should be in scope is the failure mode this softening exists to prevent.

Does **not** apply when:

- The work runs against the orchestrator's own host repo (host-repo flow). Host-repo work follows that project's host `CLAUDE.md` / `AGENTS.md` shipping rules; that flow already enforces PR-only with branch protection through a different mechanism.
- You are an investigation / read-only subagent that will not commit. You may still benefit from the rules, but the gate is "about to record" not "loaded into context".

## Rules

### 1. Feature-branch only — no commits to `main` / `master`

The orchestrator put you on a feature branch (the project overlay names the convention, e.g. `<orchestrator>/<run-id>/<slug>`). Stay there. Never `git checkout main`, never `git commit` while on `main`, never `git merge` into `main` locally, never `git merge main` *into* the feature branch, never `git rebase origin/main` or `git rebase main`, never `git format-patch` + `git am` from a main-rooted commit. Base-branch sync is owned by the orchestrator end-to-end; any in-agent path that brings `main`'s commits onto the feature branch (merge, rebase, cherry-pick, am from patch, reset --hard) poisons the lineage and breaks the orchestrator's later sync flow.

Read-only inspection is fine: `git status`, `git log`, `git diff`, `git fetch origin` *with no refspec* (fetch alone has no ref-write side effect on local branches and does not write to the remote — it is permitted; it does not count as a "publishing" operation). A fetch *with* a refspec that writes onto a local branch (e.g. `git fetch <url> refs/heads/main:refs/heads/<feature>`) is treated as a forbidden base-branch sync — same lineage outcome as a merge.

Two layers enforce this so that a slip surfaces before it ships:

- **Forge-side branch protection on `origin/main`** (GitHub branch protection rules, GitLab protected branches, or the equivalent on your forge) is the durable enforcement. A push to `main` is rejected at the remote.
- A canonical **`pre-commit` hook** in the canonical clone's `.git/hooks/pre-commit` rejects local commits whose branch is `main` or `master` (linked worktrees inherit the canonical's hooks). This is fast feedback so you don't waste a commit cycle discovering the failure at push.

If you find yourself on `main` (worktree corruption, manual operator intervention, recovery edge case): stop, report, do not attempt to "fix it forward" by committing.

### 2. Do NOT bypass git hooks

Hooks exist to enforce invariants neither you nor the orchestrator can see at every individual call site. Bypassing them is invisible to reviewers and accumulates drift.

Forbidden:

- `git commit --no-verify`
- `git push --no-verify` (also see rule 3 — you should not be pushing at all)
- Setting `core.hooksPath` to redirect hooks elsewhere (`git config core.hooksPath`, `GIT_DIR=… git -c core.hooksPath=…`)
- Renaming or removing hook files (`mv .git/hooks/pre-commit …`, `rm .git/hooks/*`)
- `git update-ref refs/heads/<branch> <sha>` to advance a branch outside of normal commit flow (skips both hook and protection checks)
- Forge REST/GraphQL API ref writes — e.g. on GitHub `gh api repos/<owner>/<name>/git/refs -X POST/PATCH/DELETE …`, or the equivalent on your forge — to create, advance, or delete a ref. Same outcome as `git update-ref` + push, with neither git-side hooks nor (for non-protected refs) any local check; a clean bypass surface that Rule 1's branch protection only catches when the target ref is `main` itself
- Any environment variable that disables the canonical hook chain (e.g. `HUSKY=0` if the project uses husky and the hook depends on it)
- Setting `GIT_DIR` (or `GIT_WORK_TREE`) to point at the canonical's `.git/` directly — that operates against the canonical's object store and refs, bypassing worktree branch isolation entirely. The worktree's `.git` *file-pointer* is the only correct entry; do not redirect it.
- `git reset --hard <sha>` to a SHA that lives on `main` (or to `origin/main`, or to any ref whose tip is `main`'s tip) — that silently advances the feature branch to a main-equivalent state without ever committing on `main`, defeating the spirit of the branch-isolation rule. `git reset --hard` is permitted only to a SHA that is already in the feature branch's own history.
- `git commit --amend` on a commit that has already been pushed by the orchestrator — that diverges the local branch from the remote and forces the orchestrator's next push to either fail or `--force`. If you need to revise an already-pushed commit, add a new commit (or revert + new commit) instead.

If a hook is failing and the failure is legitimate, **fix the failure**. If you genuinely believe the hook is wrong, escalate to the operator with evidence — do not silently bypass.

### 3. Do NOT run `git push`

The orchestrator pushes the feature branch to `origin` at a defined cadence (the project overlay names the boundary — whatever the orchestrator's unit of completion is). That cadence is load-bearing: sibling CI-gating mechanisms may consume the per-cadence push to gate degradation per chunk. An agent-initiated push races the orchestrator and may push an in-progress (uncommitted-by-policy, half-tested) state that the orchestrator's own push would have skipped.

Forbidden:

- `git push`, `git push origin <branch>`, `git push --force`, `git push --force-with-lease`, `git push --tags`
- Refspec tricks aimed at a different ref on `origin` (e.g. `git push origin HEAD:main`, `git push origin <branch>:refs/heads/something-else`)
- `git remote set-url`, `git remote add` aimed at a different remote so you can push there ("alternative-remote bypass" — every remote you can push to counts, not just `origin`)
- Editing `.git/config` directly to change `[remote "origin"] url` or to add another remote — same effect as `git remote set-url` / `git remote add`, just spelled with a text editor
- Anything that creates a refs/remotes entry as a side effect (`git fetch <url> <ref>:<remote-ref>` patterns used to write to the remote indirectly)

If you need a CI signal mid-task, that is also a no — commit, mark the task done, and let the orchestrator push. By the same logic: do **not** trigger CI on the feature branch out-of-band, and do **not** publish anything via tag/release. Concretely on GitHub: no `gh workflow run`, no `gh release create` / `gh release upload` / `git tag` + push, no equivalent `gh api` calls. The same prohibition holds for the equivalent commands on whatever forge your project uses (GitLab `glab`, Gitea, Bitbucket, etc.) — releases and workflow-runs are orchestrator-owned (or human-owned at PR-merge time); an agent-initiated release is the same publish-timing race the no-push rule exists to prevent.

Related: do **not** create additional worktrees. `git worktree add <path> <branch>` (or `git worktree add -b …`) executed inside the orchestrator-managed worktree spins up an out-of-band workspace the orchestrator never registered — commits there bypass the orchestrator's push-timing, review chain, and cleanup. The single worktree the orchestrator created for this run is the only valid working tree. If you genuinely need parallel branches, escalate.

### 4. Commit at every meaningful unit; never leave the working tree dirty across task boundaries

Every recordable unit of work — a focused change, a passing test, a documented decision — gets its own commit before the next unit begins. The next unit's review step inspects the working tree; an uncommitted state from your unit masquerades as an incomplete handoff and is rejected.

This is not about commit cosmetics. It is about **handoff contract**: the orchestrator pushes the branch as you leave it. Anything not committed when the task ends is invisible to the rest of the system.

Practical rules:

- Run `git status` before declaring a task done. The output should be `nothing to commit, working tree clean`.
- Do not stash. Stashes are local to your worktree and do not survive the worktree being removed at PR-open time.
- Do not commit `.gitignore`-able artifacts (build outputs, editor state, log files) — fix the ignore rule and commit that instead.

### 5. Use `git rm <path>` for tracked deletions

`rm <path>` removes the file from the working tree but leaves it in the index. The next commit then carries an incoherent state ("file is here but also gone"); reviewers see noise; subsequent reverts fail in surprising ways.

For tracked files, use `git rm <path>` (or `git rm -r <dir>`). For tracked-and-replaced (move/rename), use `git mv <old> <new>` or commit the delete + add together so git's rename detection wires them up.

This is codified by a documented past incident class: an agent used `rm`, the next-task review saw a dirty index, the task failed; the entire retry cycle burned on a one-character mistake. (Where your project maintains an incident log, the project overlay cites the specific entry.)

### 6. Two-actor review for every recordable decision

Every ADR, spec, plan, and commit you produce gets an **independent reviewer** who confirms it follows the constitution and the spec it implements. Independent means: separate process, no shared context, reads the artifact at the same hash you submitted.

In practice:

- For code commits: dispatch an independent reviewer agent (or invoke `superpowers:requesting-code-review`) that reads the diff, verifies the cited proofs, and emits an approve / request-changes verdict.
- For ADRs / specs / plans: the reviewer checks that the proof is real (runs the command, opens the file at the cited line, confirms the test name exists) and that the decision does not vacuum-fill or degrade any property.
- Cite proof for every claim — file:line, test name, command output, or external source. A claim without proof is rejected.

The redundancy is the point: one reviewer can rationalise a weak case; two independent reviewers checking the same thing cannot.

### 7. Do NOT merge or close PRs from the agent

This rule applies within the scope defined above (managed worktrees only; flows operating against the orchestrator's own host repo follow that project's host shipping rules, which may authorize autonomous merge after dual-review + green CI).

Merge is **always escalated to a human** per the orchestrator's PR-escalation contract. The orchestrator opens the PR; a human reviewer merges it. The agent never closes that loop.

Forbidden (commands shown for GitHub via `gh`; the same prohibition holds for the equivalent commands on whatever forge your project uses — GitLab `glab`, Gitea, Bitbucket, etc.):

- `gh pr create` (PR creation is orchestrator-owned — opening it early races the orchestrator's cleanup + escalation sequence and may produce a PR the orchestrator then duplicates or cannot clean up)
- `gh pr merge` (any flags — `--squash`, `--rebase`, `--merge`, `--auto`)
- `gh pr close` (closes the PR without merge — same blast radius: skips the human gate, may permanently lose the work)
- Any forge-API call that performs a merge or close (`gh api -X PUT repos/.../pulls/.../merge`, `gh api -X PATCH .../pulls/... -f state=closed`, or the equivalent on your forge)
- Any merge path that bypasses the PR (e.g. pushing a fast-forward of `main` directly — covered by Rules 1 + 2 but called out here for completeness)

If you believe the PR is ready to merge, that is information for the human reviewer, not an action for you.

### 8. Host-only commands do NOT run inside managed worktrees

Host-repo automation assumes the host's directory layout, hook chain, and remote configuration. Running it inside a managed worktree corrupts both — the host automation operates on the wrong tree, the managed repo gains files / config it never asked for.

The universal rule: **do not run host-only commands inside a managed worktree.** This includes any host-repo graph/index/registry maintenance tool, any orchestrator-internal scripts under the orchestrator repo's `scripts/` directory, and anything that reads or writes the orchestrator's storage directory directly.

**The project overlay enumerates the specific commands** for your project (concrete tool names, script paths, and storage env vars). Without that overlay, you lack the in-the-moment recognition signal — when in doubt, escalate.

For managed-worktree work, use plain `git`, the target's own scripts (`pnpm`, `npm`, `make`, `cargo`, etc.), and standard tooling. If a host-repo command seems necessary, escalate — running it is almost certainly a category error.

## Why these rules exist

Each rule maps to a documented failure class. The central one: an agent in a managed worktree, told only that `origin/main` has advanced, will reliably rebase the feature branch onto main — poisoning the lineage the orchestrator depends on. Softened, advisory phrasing ("prefer letting the orchestrator handle syncs") measurably fails to prevent this — which is why every prohibition here is absolute and stays that way. (The project overlay additionally anchors each class to the project's own incident memory.)

- **Branch / hook / push rules:** the recurring "which repo / which branch / which working tree did the agent commit to?" failure class. Agents have committed to `main` when ambiguous about which worktree they were in; agents have pushed in-progress work that the orchestrator's own push would have skipped. Individually patched in past projects; the *class* needs prompt-level enforcement so the next instance is caught at the agent boundary, not at the database.
- **`git rm` rule:** an agent uses `rm`, all retries fail identically, the run burns. Codifying this once at the skill layer prevents the same mistake from re-surfacing in every new prompt.
- **No-push rule:** an agent pushes mid-task, the orchestrator pushes on top, the resulting branch state is unreviewable. The fix is to centralise push timing in the orchestrator; this rule keeps it centralised by closing the agent-side path.
- **No hook bypass:** branch protection on `origin/main` catches a slip eventually, but the local-hook bypass produces a commit that lives in the worktree, in the agent's transcript, and in any subsequent retry's context — the failure surfaces late and is expensive to unwind. The skill-level rule kills it at the source.
- **Two-actor review:** every reasonable autonomous-execution constitution carries a no-degradation principle and a two-actor-review requirement. Both reviewers check the same thing — alignment — independently. The redundancy is the only reliable defence against a confidently wrong single-author decision.

## Relationship to the inline discipline block

Some orchestrators inject a condensed inline version of these rules into every managed-worktree prompt builder (a parity block in the prompt). That block is a transitional mechanism for roles that do not yet have `Skill`-tool wiring; this SKILL.md is the **authoritative source**.

Where they appear to disagree, the SKILL is canonical and the inline block is updated to match. Projects that maintain such an inline block typically pair it with a parity test asserting the block is present in every relevant prompt builder so drift is caught at CI.

When `Skill`-tool wiring reaches all roles, the inline block is **replaced** (not duplicated) by Skill invocations. With the generic-plus-overlay pattern, the replacement loads two skills, in order: this generic skill first, then the project overlay.

If you are reading this skill because the inline block referenced it, you have the full picture; the inline block was the trigger, this is the complete contract — but **load your project overlay too** for the concrete prefixes and command lists this generic skill defers to it.

## Red flags and rationalizations

| Excuse / Red flag | Reality |
|---|---|
| "I'll just commit to `main` quickly to test something" | Branch protection rejects the push and the local hook rejects the commit. Restating the rule does not change either. The "quick test" is at least one wasted retry cycle. |
| "The hook is annoying, I'll `--no-verify` once" | The hook is the only fast-feedback layer. Bypassing it pushes the failure surface to the remote, where it is more expensive and harder to attribute. |
| "I'll push so I can see CI faster" | The orchestrator pushes at its defined cadence by design; pushing earlier races the orchestrator and may publish a state that fails downstream gates. The CI signal you'd see is one the orchestrator was going to surface anyway. |
| "I'll `rm` instead of `git rm`, I'll fix it in a follow-up" | The next unit's review step sees a dirty index and fails the handoff. There is no "follow-up" — the run halts here. |
| "Two-actor review is overhead for a small change" | Triviality is not yours to declare — the independent reviewer makes that call (if the `confidence-protocol` skill is loaded, its R1-triage rule governs). Self-declared trivial is the gameable surface the rule exists to block. |
| "This host-only command works the same in any git repo" | It depends on the host's directory layout and hook chain. Inside a managed worktree it operates on the wrong tree and writes files the managed repo never asked for. Your project overlay enumerates the specific forbidden commands; if a tool is not on the list but smells host-only, escalate. |
| "I'll just `git update-ref` to fix the branch state" | That advances the ref outside the normal commit flow and skips both hooks and branch protection. The state it produces will be visible only on your worktree until it surfaces as a divergence somewhere expensive. |
| "I'll set `GIT_DIR` to the canonical and just commit there" | That bypasses the worktree's branch-isolation entirely — you're now writing directly to the canonical's refs and object store. The hook that protects `main` is on the canonical, but every other invariant the worktree provides (which branch you're on, which run you belong to) evaporates. |
| "I'll add a second remote and push to that" | The no-push rule covers every remote you can reach, not just `origin`. The orchestrator owns push timing because the orchestrator is the only thing that knows when a task is genuinely complete. |
| "I'll merge `main` into the feature branch to stay current" | The orchestrator handles base-branch sync. An in-agent merge poisons the lineage and breaks any rebase-on-main strategy the orchestrator may run later. If the branch genuinely needs to catch up, escalate. |
| "Merge is forbidden but `git rebase origin/main` should be fine" | Same effect, different verb. Base-branch sync — by any mechanism (merge, rebase, cherry-pick, `git format-patch` + `git am`, `git filter-branch` / `git filter-repo` rewriting onto main ancestry) — is the orchestrator's job, not yours. If the branch needs to catch up, escalate. |
| "I'll just `git pull` (or `git pull origin main`) to sync up" | `git pull` is `git fetch` + `git merge` — the merge half is the prohibited base-branch sync. Fetch alone is permitted; the pull combo is not. If you need to know what's on `origin`, run `git fetch` then `git log origin/main` — read-only inspection. |
| "I'll `git symbolic-ref HEAD refs/heads/main` instead of `git checkout`" | Bypasses checkout-time hooks; subsequent commits land on `main` before the pre-commit hook fires. Same outcome as the forbidden checkout, with extra hook-bypass. Stay on the feature branch HEAD the orchestrator put you on. |
| "I'll `git reset --hard origin/main` to align with the latest" | Silent main-bypass. Even though no commit lands on `main`, the feature branch is now a main-equivalent state and the work it carried is gone. `--hard` is allowed only to SHAs already in the feature branch's own history. |
| "I'll `git commit --amend` to fix that last commit" | If the orchestrator has already pushed it, amend diverges your local from the remote and the next push fails or has to `--force`. Add a new commit instead. |
| "I'm not merging, I'm just `git cherry-pick origin/main`" | Same lineage consequence as a forbidden merge — cherry-picking the main tip (or any commit unique to main) writes those commits onto the feature branch outside the orchestrator's base-sync flow. The verb is different; the rule is the same. |
| "I'll `git worktree add` a second working tree to try something on the side" | The new worktree is invisible to the orchestrator: no record in the orchestrator's workspace registry, no push-timing, no review chain, no cleanup. Commits there are lost when the orchestrator-managed worktree is removed. Stay in the one worktree the orchestrator created. |
| "I'll edit `.git/config` to point `origin` somewhere else, then push" | Same alternative-remote bypass as `git remote set-url`. The forbidden surface is "every remote you can push to," not "every git command name we listed." Editing the config file is just the verb-less version. |
| "I'll `git stash` this and pop it after the next task" | The stash is local to your worktree. The worktree is removed when the orchestrator opens the PR. Anything in stash is gone. Commit instead — that is what the handoff contract requires. |
| "I'll `git filter-repo` to clean up the history before pushing" | Same lineage rewrite as filter-branch — moves your branch's commits onto a different ancestry, defeating the orchestrator's diff-against-base assumptions and any rebase flow it may run. History rewrites on a published feature branch are forbidden. |
| "The PR looks good, I'll `gh pr merge --auto` to close the loop" | Merge is always escalated to a human. Auto-merge bypasses that gate even though it waits for CI; the human review is the gate, not CI. Same for `gh pr close` — closing a PR the agent opened is a quiet way to throw away the work. |
| "I'll `gh release create v0.X` to ship this milestone" | Release/tag publication is orchestrator-owned (or human-owned at PR-merge time). An agent-initiated release publishes state outside the orchestrator's push-timing flow, races CI, and may tag commits the human reviewer was about to reject. Same applies to `git tag <name>` followed by any push or `gh release upload`. |
| "I'll `gh workflow run <wf>` to get CI feedback faster" | Same publish-timing race as `git push`. The orchestrator's cadence-boundary push triggers the workflow you'd manually run; running it earlier publishes a CI run on a half-tested state and may dispatch downstream jobs that consume it as authoritative. |
| "The inline block doesn't say X, so X must be allowed" | The inline block is a condensation. This skill is canonical. If something is here and not in the inline block, the skill wins — and the inline block needs updating. |

All of these mean: stop, re-read the relevant rule, and follow the orchestrator's intended flow.
