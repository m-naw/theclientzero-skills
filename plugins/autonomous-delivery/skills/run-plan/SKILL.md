---
name: run-plan
description: Use when the operator has approved a spec and wants it delivered to deployed-and-verified without further input, or types /run-plan or /run-plan continue
---

# Run Plan

## Overview

Delivers an approved spec end to end: plan, acceptance checks, reviewed units, deploy to a test
environment, acceptance, monitoring, production gate, capstone. The operator approved the spec; from
here the session works alone, overnight if needed. Two failures this skill prevents:

1. **False done:** reporting done without proof that the change works after deploy. "Merged" and
   "CI green" are not done. Done means the spec's acceptance scenarios pass against a deployed
   environment, checked by checks the implementer did not write and cannot edit.
2. **Lost decisions:** an operator decision that scrolled past in a transcript. Everything that waits
   on the operator sits in one ledger, shown in the final message, with the exact step that clears it.

This skill builds on `confidence-protocol` (CP). Load it. Its PROPOSED records, evidence rule and
R1/R2 review apply unchanged, except where `## Decisions` builds a choice before the operator confirms.

## When to use

`/run-plan <spec path>` starts a run; `/run-plan continue` resumes one. Not for writing the spec (that
stays human) or a one-line fix with no deploy. Without an identifiable approved spec, write a
"Waiting on you" item naming the missing spec and stop.

## Overlay

The project declares its specifics in `.claude/run-plan.md`, made from `OVERLAY-TEMPLATE.md` next to
this file. Missing keys take the template defaults. A missing `verify` is derived from the repo and
recorded under "Decided"; a missing overlay is a "Waiting on you" item, and the run uses defaults.

## Flow

While a run is active this Flow wins: never present another skill's option menu or handoff question.

1. **Start or resume.** Follow `## Resume` if `.run-plan/state.md` exists and its phase is not
   `finished`. Read the overlay and the spec. Preflight: required checks green on the default branch
   (`gh` when available), `verify` passes, overlay complete. Record in `state.md` the
   `git hash-object` of the overlay and of the script files behind `deploy_test`, `acceptance`,
   `monitor`, `teardown` and `rollback`. Not the test files `verify` runs: units add tests there. A
   red default branch outside the spec's scope is a ledger item; with `merge: self`, start no unit
   that would merge into it.
2. **Plan and review.** Write the plan (`superpowers:writing-plans` when available): units, their
   dependencies, and for each acceptance scenario the unit that makes it pass. Review it without being
   asked, scaled to the plan. Always one independent *consistency* reviewer (spec, plan and acceptance
   scenarios agree). A plan of more than one unit, or one that touches a `risk` path, adds up to two
   angles from the risk classes it touches (backward compatibility, data/migration, UX against intent,
   cost) and runs its reviewers on opus; otherwise the one reviewer runs on sonnet. Fix findings.
   After 2 rounds, remaining disagreement becomes a PROPOSED record. State one alternative or
   objection you considered and why you kept or rejected it; a spec that looks wrong gets a PROPOSED
   record, and the untouched parts are delivered. Then write every operator-only step the plan
   contains to "Waiting on you", print it once, and continue without waiting.
3. **Acceptance checks.** Before any unit, create the branch the checks land on: `run-plan/<plan-slug>`
   from the default branch (`merge: human`, the default), or unit 1's branch (`merge: self`). There a
   fresh subagent that implements no unit writes the checks, briefed with `references/acceptance.md`:
   one per acceptance scenario, named by its id. It runs them against the base, deployed with
   `deploy_test`: every new check must fail; one the base already satisfies stays only as a named
   `guard`. Record that output, each check file's `git hash-object` and the unit that owns each id in
   `state.md`. The checks are now frozen. If the base cannot be deployed, never work around it:
   freeze the checks as `red: not shown`, ledger a cause outside the code, and go on to the units. A
   check that contradicts a cited spec line or a rail of this skill is rewritten only by a fresh
   author subagent, must fail on the base again, is re-frozen, and gets a "Decided" row.
4. **Units.** One at a time, in dependency order. The target branch is `run-plan/<plan-slug>`
   (`merge: human`) or the default branch (`merge: self`). Per unit: one implementer subagent briefed
   with `references/implementer.md`, a branch from the target's tip (under `merge: self`, from the
   checks commit until a unit has merged), one PR into the target. Then, on the unit's head:
   1. Review per CP with `references/reviewer.md`, with base = the commit the implementer started from
      (it holds the checks): R1 triage on every diff (sonnet); R2 at the same hash (opus) for
      never-trivial surfaces (CP's list, permissions, the overlay's `risk` paths) and as CP's
      spot-check when the head hash ends in `0`.
   2. Required checks green; where none report on this PR (integration branch, no CI), `verify`.
   3. `## Definition of done`.
   4. Merge into the target only when all three passed. If the target moved since the unit branched,
      update the branch and repeat from 1; a conflict, or a third move, makes the unit **not done**.
      With `merge: self`, merge only when the overlay states that branch protection with required
      checks exists; otherwise treat it as `human`.

   A fix is a new commit on the unit's branch and repeats from 1 at the new hash. A review rejection
   gets at most 2 fix rounds, like a failed step. A unit that ends **not done**, or whose implementer
   reports `blocked`, is not merged: ledger it, skip every unit that depends on it, and continue with
   independent units. Write the unit's status and lessons to `state.md` before the next unit starts.
   No subagents available: CP solo mode applies, nothing passes PROPOSED, merge nothing, ledger each PR.
5. **Production.** Per overlay `prod`. `human` (default): a "Waiting on you" item with a business-
   language summary, its risk, and the exact deploy command. `auto` only for the risk classes it names.
6. **Capstone.** For a plan of more than one unit, review the whole change. For every plan, run the
   whole-diff security review (`/security-review` when available). A High finding in code this run
   wrote becomes one more unit; one whose fix adds a mechanism the spec does not ask for (auth, a
   permission model) is a "Waiting on you" item. With `merge: human`, merge the default branch into
   the integration branch; a conflict is one more unit, never a hand merge. If the test environment
   does not hold the tree of the target's final head, run `## Definition of done` on it once more.
   With `merge: human`, open the one PR from the integration branch into the default branch, with the
   "Decided" table in its body, as a "Waiting on you" item.
   Triage follow-ups: *do now* (cheap, in scope), *ledger* or *drop* (with the reason). State one
   alternative you considered, set `phase: finished`, and state where you stop.
7. **Final message.** "Waiting on you", then PROVISIONAL decisions, then unit statuses with evidence.

Never do anything on the overlay's `protected` list, and never take an operator-only action:
irreversible, client-facing (a message or data change that reaches a real client or their production
system), money, security exception, client production. A destructive migration or data deletion is
operator-only in every environment, except throwaway local test data the run itself created. Each is a
"Waiting on you" item; everything else continues.

Never break an existing contract (API shape, schema, CLI output) that users depend on. Break it only
when the spec states in words that existing clients will break. Otherwise ship additively (a new
field or version) and make removal of the old shape a "Waiting on you" item.

## Definition of done

Done means the change works in a running environment against the spec's acceptance scenarios. Merged,
CI green and local tests passing are steps on the way, not done. Run it on the unit's head, before the
unit merges; `references/acceptance.md` says how to run and record each step.

1. Recompute the hashes in `state.md`. A changed hash is a failed step unless recorded as a re-freeze.
2. One deploy at a time: before `deploy_test`, run the overlay's `teardown`, or stop what this run's
   previous deploy started. Never stop a process the run did not start.
3. `deploy_test` → `acceptance` → `monitor` for its window. Acceptance passed only when every scenario
   id of this unit and of the units merged before it shows as passed. A scenario with no check failed.
4. A step that fails, times out, errors, or is skipped or not run counts as failed. The cause does
   not matter: a port taken, an expired credential and a flaky environment are failures too. A failed
   step may be rerun once unchanged; report both outputs.
5. On failure: fix with data (logs, monitor output, screenshots), at most 2 rounds. Then run the
   overlay's `rollback` if declared (with `rollback: none`, never revert on your own) and add a
   "Waiting on you" item with the evidence. A cause outside the code (environment, credentials) goes
   straight to that item; never work around it, e.g. by deploying somewhere the overlay does not name.
6. Never edit, weaken, skip or delete a frozen check, overlay command, its script, or a test to pass.
7. Report exactly one status per unit, backed by command output:
   - **done**: every step passed against the deployed environment.
   - **verified, not monitored**: `deploy_test` and `acceptance` passed; `monitor` is not declared.
   - **verified locally**: `deploy_test` or `acceptance` is not declared; `verify` and the checks passed.
   - **not done**: any step failed or did not run. Say which, and what clears it.

   The plan's status is its worst unit status; a skipped unit is **not done**. Any status below
   **done** goes in the ledger and the final message.

## Decisions

Before deciding, derive: spec, ADRs, code, docs, conventions, or a focused investigation.

- **Derivable:** a cited source pins the answer. Decide, and record under "Decided" with the source
  (`file:line`, a test, a command and its output). When the derivation is uncertain, one verification
  subagent with a different angle checks it first.
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

`.run-plan/ledger.md`, from `references/ledger-template.md`, has exactly three sections:
`## Waiting on you` (with the exact step that clears each item), `## Decided` (with the citing source;
PROVISIONAL rows add how to reverse) and `## Follow-ups`.

- Keep `.run-plan/` out of git: add it to `.git/info/exclude` unless `.gitignore` covers it.
- Print "Waiting on you" at the top of every message to the operator, even when it is empty ("none").
- When you add an item and a push-notification tool exists, send one notification with its first line.
- A "Waiting on you" item leaves, to "Decided" with the evidence, only when its clearing step happened.

## Models and effort

Haiku: tests, builds, greps, deploys. Sonnet: implementation, fixes, acceptance checks, R1. Opus:
multi-unit or risk-path plan review, R2, security review, capstone, high-risk units. Effort medium,
high for security and high-risk work. Pass `model` on every dispatch. Reviewer is never implementer.

## Resume

`.run-plan/state.md` is the source of truth, and the only handoff document. It holds: phase
(`finished` at the end), this skill's path, spec and plan paths, target branch, frozen hashes, per
unit (branch, PR, reviewed hash, status, evidence paths), next step, and **Lessons** (what went
wrong in earlier units and how to avoid it). Update it at every phase change.

- Stay thin: delegate reads, test runs and implementation to subagents; keep only their summaries.
- Never stop for context. Auto-compaction may replace earlier turns: at the start of every unit,
  re-read this SKILL.md and `state.md`, and trust `state.md` over your memory of earlier turns.
- The operator may resume by hand at any time with `/clear` and then `/run-plan continue`. On
  `/run-plan continue`: read `state.md`, the ledger and the overlay. Check what already landed
  (`git log`, open PRs, the deployed state) before you repeat any step. Carry on from "next step".

## Red flags

| Thought | Reality |
|---|---|
| "CI is green and it's merged, so it's done" | Done needs the frozen checks passing against a deployed environment, before the merge. |
| "The acceptance check is flaky, I'll skip it" | Skipped counts as failed. Rerun once, then fix it with data or ledger it. |
| "I'll write the check together with the feature" | The checks come first, from the spec, by a subagent that implements nothing, and must fail first. |
| "I'll fix the check or the deploy script so it passes" | They are frozen. A changed hash is a failed step. |
| "The spec says delete, so I delete" | Deleting data is operator-only. Ledger it and deliver the rest. |
| "The spec says change the response, so the old shape can go" | A silent contract break is a failure. Ship additively unless the spec says in words that existing clients will break. |
| "They would surely pick my recommendation, so it's derived" | A guess is not a source. Build it PROVISIONAL, or ledger it if it is not clearly reversible. |
