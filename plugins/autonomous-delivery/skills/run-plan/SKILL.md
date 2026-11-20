---
name: run-plan
description: Use when the operator has approved a spec and wants it delivered to deployed-and-verified without further input, or types /run-plan or /run-plan continue
---

# Run Plan

## Overview

Delivers an approved spec end to end: plan, reviewed units, deploy to a test environment, acceptance,
monitoring, production gate, capstone. The operator approved the spec; from here the session works
alone. Two failures this skill prevents:

1. **False done:** reporting done without proof that the change works after deploy. "Merged" and
   "CI green" are not done. Done means the acceptance scenarios pass against a deployed environment.
2. **Lost decisions:** an operator decision that scrolled past in a transcript. Everything that waits
   on the operator sits in one ledger, shown at every checkpoint, with the exact step that clears it.

This skill builds on `confidence-protocol` (CP). Load it. Its preference gate, PROPOSED records,
evidence rule and R1/R2 review apply unchanged; this skill adds only where things go.

## When to use

- The operator approved a spec (brainstorming is done) and says to deliver, run or ship it.
- `/run-plan <spec path>` starts a run. `/run-plan continue` resumes one from `.run-plan/state.md`.

Do not use for: discussing or writing the spec (that stays human); a one-line fix with no deploy;
work with no approved spec. Without an identifiable approved spec, write a "Waiting on you" item
naming the missing spec and stop.

## Overlay

The project declares its specifics in `.claude/run-plan.md`, made from `OVERLAY-TEMPLATE.md` next to
this file: `verify`, `deploy_test`, `acceptance`, `monitor`, `window`, `rollback`, `done_at`, `merge`,
`prod`, `risk`, `protected`. Missing keys take the template defaults (`merge: human`, `prod: human`,
`rollback: none`). A missing
`verify` is derived from the repo (test script, CI config) and recorded under "Decided" with its source.
A missing overlay is a "Waiting on you" item with a proposed overlay; the run continues on defaults.

## Flow

1. **Start or resume.** Follow `## Resume` if `.run-plan/state.md` exists. Read the overlay and the
   spec. Preflight: required checks green on the default branch (`gh` when available), `verify`
   passes, overlay complete. A red default branch outside the spec's scope is a ledger item; start
   no unit that would merge into it.
2. **Plan and review.** Write the plan (`superpowers:writing-plans` when available). Then run a review
   panel without being asked. Always: *consistency* (spec, plan and acceptance scenarios agree) and
   *security*. Add up to two angles from the risk classes the plan touches: backward compatibility,
   data/migration, UX against intent, cost. Each reviewer is an independent subagent. Fix findings.
   After 2 rounds, remaining disagreement becomes a CP PROPOSED record.
3. **Units.** One implementer subagent per unit, briefed with `references/implementer.md`: test-first,
   stop rather than guess, run `verify`. Before merge, review per CP with `references/reviewer.md`:
   R1 triage on every diff (sonnet); R2 at the same hash (opus) for never-trivial surfaces (CP's list
   plus the overlay's `risk` paths) and for CP's spot-check. Required checks green. No subagents
   available: CP solo mode applies, nothing passes PROPOSED, and with `merge: self` you stop merging
   and ledger each PR. Then merge per overlay `merge`:
   - `self`: the session merges after required checks pass. Allowed only when the overlay states that
     branch protection with required checks exists. Otherwise treat as `human`.
   - `human` (default): the PR becomes a "Waiting on you" item; start the next independent unit.
     Never stack PRs.

   One PR per unit. Write each unit's lessons to `state.md` before the next unit starts.
4. **Definition of done.** Per unit or per plan, as `done_at` says. See `## Definition of done`.
5. **Production.** Per overlay `prod`. `human` (default): a "Waiting on you" item with a
   business-language summary of the change, its risk, and the exact deploy command. `auto` applies
   only to the risk classes the overlay names. Never deploy client production on your own otherwise.
6. **Capstone.** Review the whole change, then run a security review (`/security-review` when
   available). Triage every follow-up by value, cost and risk: *do now* (cheap, in scope), *ledger*
   (the operator's call) or *drop* (with the reason). State where you stop and why.
7. **Final message.** "Waiting on you" first, then the status word from `## Definition of done`,
   then the evidence.

Never do anything on the overlay's `protected` list, and never take an operator-only action:
irreversible, client-facing, money, security exception, client production. A destructive migration or
data deletion is operator-only in every environment, except throwaway local test data the run itself
created. Each is a "Waiting on you" item; everything else continues.

Never break an existing contract (API shape, schema, CLI output) that users depend on. Break it only
when the spec states in words that existing clients will break. Otherwise ship additively (a new
field or version) and make removal of the old shape a "Waiting on you" item.

## Definition of done

Done means the change works in a running environment against the acceptance scenarios. Merged, CI
green and local tests passing are steps on the way, not done. Run `references/acceptance.md`:

1. `deploy_test` → `acceptance` → `monitor` for its window, on the code that ships: after merge for
   `merge: self`, on the PR head for `merge: human`.
2. A step that fails, times out, errors, or is skipped or not run counts as failed. The cause does
   not matter: a port taken, an expired credential and a flaky environment are failures too.
3. On failure: fix with data (logs, monitor output, screenshots), at most 2 rounds. Then run the
   overlay's `rollback` command if it declares one, and add a "Waiting on you" item with the evidence.
   With `rollback: none` (the default), never revert on your own: ledger the failure.
4. Never edit, weaken or delete an acceptance scenario or test to make it pass.
5. Report exactly one status per unit, backed by command output:
   - **done**: every step passed against the deployed environment.
   - **verified, not monitored**: `deploy_test` and `acceptance` passed; `monitor` is not declared.
   - **verified locally**: `deploy_test` or `acceptance` is not declared; `verify` passed.
   - **not done**: any step failed or did not run. Say which, and what clears it.

   The plan's status is its worst unit status. Any status below **done** goes in the ledger and the
   final message.

## Decisions

Apply CP's preference gate unchanged. Before deciding, derive: spec, ADRs, code, docs, conventions,
or a focused investigation.

- **Derivable:** decide, and record under "Decided" with the citing source (`file:line`, a test, a
  command and its output). When the derivation is uncertain, one verification subagent with a
  different angle checks it first. A recommendation is allowed only when evidence pins it.
- **Residual preference** (taste, priority, risk appetite that no source pins) or **operator-only**:
  write a CP PROPOSED record and make it a "Waiting on you" item. Park only the affected piece;
  everything else continues. Never establish the preference yourself, even when it is reversible.

Never ask the operator a question during a run. Never call `AskUserQuestion`. If the operator would
answer "the recommended option", the evidence pins it: derive it and record it. The ledger is the
only operator channel: no PR comments or issues addressed to the operator.

## Ledger

`.run-plan/ledger.md`, from `references/ledger-template.md`, has exactly three sections:

- `## Waiting on you`: item, why it is the operator's, recommendation, exact step that clears it,
  since when.
- `## Decided`: decision, citing source, CP state, how it was verified.
- `## Follow-ups`: value, cost, risk, verdict.

Rules:
- Keep `.run-plan/` out of git: add it to `.git/info/exclude` unless `.gitignore` covers it.
- Print "Waiting on you" at the top of every checkpoint message and of the final message, even when
  it is empty ("none").
- When you add an item and a push-notification tool exists, send one notification with its first line.
- A "Waiting on you" item leaves only when its clearing step has happened. Move it to "Decided" with
  the evidence.

## Models and effort

| Work | Model | Effort |
|---|---|---|
| Tests, builds, greps, other mechanical runs | haiku | medium |
| Implementation and fixes | sonnet | medium |
| R1 triage | sonnet | medium |
| Plan, architecture, R2, security review, capstone, high-risk units | opus | high for security and high-risk, else medium |

The reviewer is never the implementer's instance. Choose the cheapest model that is adequate.

## Disagreement

At plan review and at capstone, state at least one alternative or objection you considered, and why
you kept or rejected it. Agreement without a stated alternative is a skipped step. If the spec itself
looks wrong, say so in a PROPOSED record; deliver the parts the objection does not touch.

## Resume

`.run-plan/state.md` holds: phase, current unit, done units, next step, and **Lessons** (what went
wrong in earlier units and how to avoid it). It replaces any handoff document. Update it at every
unit boundary.

- Stay thin: delegate reads, test runs and implementation to subagents; keep only their summaries.
- When context passes about 60% (heuristic: auto-compaction is near, or three units are done in this
  session), or the work is too large for one session: update `state.md`, print "Waiting on you",
  then end with exactly these two lines and nothing after them:

  ```
  /clear
  /run-plan continue
  ```
- On `/run-plan continue`: read `state.md`, the ledger and the overlay. Check what already landed
  (`git log`, open PRs, the deployed state) before you repeat any step. Carry on from "next step".

## Red flags

| Thought | Reality |
|---|---|
| "CI is green, so it's done" | Done needs acceptance passing against a deployed environment. |
| "It's merged, so it's done" | Merge is step 3 of 7. Run `## Definition of done`. |
| "Deploy failed for an unrelated reason, I'll report done anyway" | A failed or skipped step is a failed step. Status is **not done**, plus a ledger item. |
| "The acceptance check is flaky, I'll skip it" | Skipped counts as failed. Fix it with data or ledger it. |
| "I'll adjust the scenario so it matches what I built" | Editing a scenario to pass is faking acceptance. |
| "The spec says delete, so I delete" | Deleting data is operator-only. Ledger it and deliver the rest. |
| "The spec says change the response, so the old shape can go" | A silent contract break is a failure. Ship additively; removal of the old shape goes to "Waiting on you" unless the spec says in words that existing clients will break. |
| "I'll ask which option they prefer" | Derive it. If no source pins it, write a PROPOSED record to the ledger. No questions. |
| "It's reversible, so I'll just pick" | Reversibility does not make a preference derivable. Ledger it, park that piece only. |
| "This one decision blocks everything, I'll wait" | Park only the affected piece; run everything else. |
| "The reviewers agree, so do I" | State the alternative you considered and why you rejected it. |
| "The operator will read the transcript" | They read the ledger. A decision outside it is lost. |
| "I'll merge, the overlay says `self`" | Only when the overlay states branch protection with required checks exists. |
| "I'll write a handoff note for the next session" | Write `state.md` and end with `/clear` then `/run-plan continue`. |
