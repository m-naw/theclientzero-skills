---
name: run-plan
description: Use when the operator hands over a spec and wants it delivered to deployed-and-verified without further input, or types /run-plan or /run-plan continue
---

# Run Plan

## Overview

Delivers a spec end to end, alone and overnight if needed: spec and plan review, acceptance checks,
reviewed units in milestones, test deploy, acceptance, monitoring, production gate. It prevents:

1. **False done:** done without proof that it works after deploy. Done means the spec's acceptance
   scenarios pass against a deployed environment, by checks the implementer did not write or edit.
2. **Lost decisions:** an operator decision that scrolled past in a transcript. Everything that waits
   on the operator sits in one ledger, shown in the final message, with the exact step that clears it.

This skill builds on `confidence-protocol` (CP). Load it. Its PROPOSED records and evidence rule apply
unchanged, except where `## Decisions` builds a choice first. `## Review` replaces its R1/R2 chain.

## When to use

`/run-plan <spec path>` starts a run; `/run-plan continue` resumes one. Not for writing the spec or a
one-line fix with no deploy. Without an identifiable spec, write a "Waiting on you" item and stop.

Project specifics live in `.claude/run-plan.md`, from `OVERLAY-TEMPLATE.md` next to this file;
missing keys take its defaults. A missing `verify` is derived from the repo and recorded under
"Decided"; a missing overlay is a "Waiting on you" item, and the run uses defaults.

## Flow

While a run is active this Flow wins: never present another skill's option menu or handoff question.

1. **Start or resume.** Follow `## Resume` if `.run-plan/state.md` exists and its phase is not
   `finished`. Read the overlay and the spec. Preflight: required checks green on the default branch
   (`gh` when available), `verify` passes, overlay complete. Record in `state.md` the hash
   (`git hash-object`) of the overlay and of the scripts behind `deploy_test`, `acceptance`,
   `monitor`, `teardown` and `rollback`, not of tests. A red default branch outside the spec's scope
   is a ledger item; with `merge: self`, start no unit that would merge into it.
2. **Plan and review.** The spec is not assumed right. Write the plan (`superpowers:writing-plans`
   when available): units in milestones (one is fine), dependencies, and the unit that makes each
   acceptance scenario pass. Run the spec-and-plan review (`## Review`); it never blocks. Fix and
   record derivable findings, build preferences PROVISIONAL, and write operator-only ones and every
   operator-only step of the plan to "Waiting on you"; print it once and continue. State one
   alternative or objection you considered and why you kept or rejected it.
3. **Acceptance checks.** Before any unit, branch the checks off the default branch:
   `run-plan/<plan-slug>` (`merge: human`) or `run-plan/<plan-slug>-checks` (`merge: self`, the
   default; units start there until one has merged). There a fresh subagent that implements no unit
   writes the checks, briefed with `references/acceptance.md`: one per scenario, named by its id. It
   runs them against the base, deployed with `deploy_test`: every new check must fail; one the base
   already satisfies stays only as a named `guard`. Record that output, each check file's hash and
   each id's owning unit in `state.md`; the checks are now frozen. If the base cannot be deployed,
   never work around it: freeze the checks as `red: not shown`, ledger a cause outside the code, and
   continue. Rewrite a frozen check only when it contradicts a cited spec line or a rail, or when an
   operator answer changes required behavior ("break the contract"): then only the check ids the
   ledger records with that answer, never others. A fresh author subagent rewrites it; it must fail
   on the base again, is re-frozen, and gets a "Decided" row citing the line, rail or answer.
4. **Units.** In dependency order. Up to 3 units run at once when the plan marks them parallel-safe
   (no dependency between them, disjoint files or modules), each in its own git worktree and branch;
   anything that uses the shared environment (`deploy_test`, acceptance, migrations) runs one at a
   time. The target is the default branch (`merge: self`) or `run-plan/<plan-slug>` (`merge: human`).
   Per unit: one implementer subagent briefed with `references/implementer.md`, a branch from the
   target's tip (or the checks branch, above), one PR into the target, owned until it merges or is
   ledgered, per `references/pr-watch.md`. Then, on the unit's head:
   1. The unit review (`## Review`), with base = the commit the implementer started from (it holds
      the checks).
   2. Required checks green (`references/pr-watch.md`); where none report on the PR, `verify`.
   3. `## Definition of done`.
   4. Merge into the target only when all three passed at the same hash, never when the PR touches
      `protected_paths`, carries an operator-only item, or its merge deploys production on its own
      (those are "Waiting on you"). If the target moved, rebase per `references/pr-watch.md` and
      repeat from 1; an unresolvable conflict, or a third move, makes the unit **not done**.

   A fix is a new commit and repeats from 1 at the new hash; a review rejection gets at most 2 fix
   rounds, like a failed step or a red check. A unit that ends **not done**, or whose implementer
   reports `blocked`, is not merged: ledger it, skip its dependents, continue with independent
   units. Then write its status, `## Delivered` row and lessons to `state.md`, and print the
   progress line. No subagents: CP solo mode, nothing passes PROPOSED, nothing merges.
5. **Milestone end.** The milestone reviews (`## Review`): a High finding in code this run wrote is
   one more unit, or a "Waiting on you" item if its fix adds a mechanism the spec does not ask for
   (auth, a permission model). Then the handoff and lessons (`## Resume`), and the progress line.
6. **Production.** Per overlay `prod`. `human` (default): a "Waiting on you" item with a business-
   language summary, its risk, and the exact deploy command. `auto` only for the risk classes it names.
7. **Run end.** With `merge: human`: merge the default branch into the integration branch (a
   conflict is one more unit, never a hand merge), run `## Definition of done` once more if the test
   environment does not hold its head, and open the one PR into the default branch, "Decided" table
   in its body, as a "Waiting on you" item. Triage follow-ups: *do now* (cheap, in scope), *ledger*
   or *drop* (with the reason). Check out the branch holding all delivered work (the target) if that
   destroys nothing, else say why under `## Delivered`. State one alternative you considered, set
   `phase: finished`, and say where you stop.
8. **Final message.** "Waiting on you", PROVISIONAL decisions, unit statuses with evidence, Delivered.

Never do anything on the overlay's `protected` list, and never take an operator-only action:
irreversible, client-facing (a message or data change reaching a real client or their production
system), money, security exception, client production. Destructive migrations and data deletion are
operator-only everywhere, except throwaway local test data the run created. Each is a "Waiting on
you" item; everything else continues.

Never break an existing contract (API shape, schema, CLI output) that users depend on. Break it only
when the spec states in words that existing clients will break. Otherwise ship additively (a new
field or version) and make removal of the old shape a "Waiting on you" item.

## Definition of done

Merged, CI green and local tests passing are steps on the way, not done. Run this on the unit's
head, before the unit merges; `references/acceptance.md` says how to run and record each step.

1. Recompute the hashes in `state.md`. A changed hash is a failed step unless recorded as a re-freeze.
2. One deploy at a time (teardown per `references/acceptance.md`), then `deploy_test` → `acceptance`
   → `monitor` for its window. Acceptance passed only when every scenario id of this unit and of the
   units merged before it shows as passed. A scenario with no check failed.
3. A step that fails, times out, errors, or is skipped or not run counts as failed, whatever the
   cause (a resource in use, an expired credential, a flaky environment). A failed step may be rerun
   once unchanged; report both outputs.
4. On failure: fix with data (logs, monitor output, screenshots), at most 2 rounds. Then run the
   overlay's `rollback` if declared (with `rollback: none`, never revert on your own) and add a
   "Waiting on you" item with the evidence. A cause outside the code (environment, credentials) goes
   straight to that item; never work around it, e.g. by deploying somewhere the overlay does not name.
5. Never edit, weaken, skip or delete a frozen check, overlay command, its script, or a test to pass.
6. Report exactly one status per unit, backed by command output:
   - **done**: every step passed against the deployed environment.
   - **verified, not monitored**: `deploy_test` and `acceptance` passed; `monitor` is not declared.
   - **verified locally**: `deploy_test` or `acceptance` is not declared; `verify` and the checks passed.
   - **not done**: any step failed or did not run. Say which, and what clears it.

   The plan's status is its worst unit status; a skipped unit is **not done**. Any status below
   **done** goes in the ledger and the final message.

## Decisions

- **Derivable:** first derive (spec, ADRs, code, docs, conventions, a focused investigation). When a
  cited source pins the answer, decide and record under "Decided" with the source (`file:line`, a
  test, a command and its output). If the derivation is uncertain, one verification subagent with a
  different angle checks it first.
- **Reversible preference:** no source pins it, and switching later is one code change: no data
  migration, no change to a published contract, nothing a client has seen, no never-trivial surface.
  Build the recommended option in the form cheapest to change (one constant, flag or file). Record
  it under "Decided" marked **PROVISIONAL**, CP state PROPOSED, with the alternative and the exact
  step that reverses it. Do not park the piece. It may merge, but it never reaches production
  unconfirmed: `prod: auto` does not cover it, and the production item lists every PROVISIONAL row.
- **Operator-only** (see `## Flow`) or **not clearly reversible:** write a CP PROPOSED record as a
  "Waiting on you" item. Park only the affected piece; everything else continues.

A guess at what the operator would choose is not evidence: only a cited source makes a choice
derivable. Never ask the operator a question during a run. Never call `AskUserQuestion`. The ledger is
the only operator channel: no PR comments or issues addressed to the operator.

## Ledger

`.run-plan/ledger.md`, from `references/ledger-template.md`, has exactly four sections:
`## Waiting on you` (the exact step that clears each item; the operator's answer and the check ids
it affects), `## Decided` (the citing source; PROVISIONAL rows add how to reverse), `## Follow-ups`
and `## Delivered` (one row per unit and one `run` row: final branch, PR URL or `-`, head commit;
the same section in `state.md`; update both whenever a unit merges or ends). Keep `.run-plan/` out
of git (`.git/info/exclude` unless `.gitignore` covers it).

- Progress: at each unit end and milestone end print exactly one line, `Unit k/N (p%) — milestone
  m/M — PR #n: CI green|red|merged — <outcome> — waiting on you: <count>`. No other chatter. Any
  other message to the operator starts with "Waiting on you", even when it is empty ("none").
- When you add an item and a push-notification tool exists, send one notification with its first line.
- A "Waiting on you" item leaves, to "Decided" with the evidence, only when its clearing step happened.

## Review

Every reviewer is a fresh subagent that wrote nothing it reviews, briefed with `references/reviewer.md`.

- **Spec and plan:** once, before the checks, one opus reviewer reads spec and plan together for
  consistency, security and spec gaps (missing or contradictory scenarios, contract or data risks,
  unstated operator-only actions), and each parallel-safe claim of the plan. Up to 2 rounds; what is
  still disputed becomes a PROPOSED record.
- **Unit:** exactly one opus review per unit PR, at its head hash. A second, independent review
  (fable) only when the problem is genuinely hard, the change is complex and touches many areas, or
  you are not confident; record that reason under "Decided".
- **Milestone:** at each milestone end, one opus capstone and one opus security review of its diff.

## Resume

`.run-plan/state.md` is the source of truth, and the only handoff document. It holds: phase
(`finished` at the end), this skill's path, spec and plan paths, target branch, frozen hashes, per
unit (branch, PR, reviewed hash, status, evidence paths), next step, `## Delivered`, a handoff per
finished milestone (what shipped and where, open ledger items, what the next milestone must know),
and `## Lessons` (one generic line per thing that went wrong or surprised). Update it every phase.

- Stay thin: delegate reads, test runs and implementation to subagents; keep only their summaries.
  Pass `model` on every dispatch: haiku for tests, builds, greps, deploys, check watching; sonnet
  for implementation, fixes, acceptance checks; opus for every `## Review` and units on a `risk`
  path; fable only for an exceptional second unit review. Effort medium (high: security, `risk`).
- Never stop for context. Auto-compaction may replace earlier turns: at every unit start, re-read
  this SKILL.md and `state.md`, apply its `## Lessons`, and trust `state.md` over your memory.
- On `/run-plan continue` (after a `/clear` or not): read `state.md`, the ledger and the overlay;
  check what landed (`git log`, open PRs, deployed state) before repeating any step. Act on each
  operator answer first (record the check ids it affects, re-freeze only those per Flow 3), then
  carry on from "next step".

## Red flags

| Thought | Reality |
|---|---|
| "The spec says delete, so I delete" | Deleting data is operator-only. Ledger it and deliver the rest. |
| "The spec says change the response, so the old shape can go" | A silent contract break is a failure. Ship additively unless the spec says in words that existing clients will break. |
