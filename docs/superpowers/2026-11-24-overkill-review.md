# run-plan skill: overkill review

Reviewed at clone HEAD `91d89d9` (source: `git rev-parse HEAD` in `scratchpad/tcz-skills`).
Files read in full: `SKILL.md`, `OVERLAY-TEMPLATE.md`, `references/{acceptance,implementer,reviewer,ledger-template,pr-watch}.md`,
`plugins/autonomous-delivery/tests/test-structure.sh`, `docs/superpowers/specs/2026-11-20-run-plan-design.md`,
`evals/run-plan-delivery/FINDINGS.md`, and `plugins/confidence-protocols/skills/confidence-protocol/SKILL.md` (to check what run-plan restates).

Line numbers below are the line numbers at HEAD, before the patch. Paths are relative to
`plugins/autonomous-delivery/skills/run-plan/`.

## Verdict in one paragraph

The skill is already dense. It has been through three reviews and a 200-line cap, and most of its
repetition is deliberate: the same rule is sent to a different subagent that never sees `SKILL.md`.
The none/low-risk overkill is small: 304 words of 7,752 (3.9%), almost all of it orchestrator-facing
prose in the reference files that restates `SKILL.md`. The one large token lever is not a wording cut
but a policy: `SKILL.md` is re-read at every unit start (finding M1). That is medium risk and is not applied.

## Findings applied in the patch (risk none or low)

| # | Location | What | Category | Action | Risk of cutting |
|---|---|---|---|---|---|
| A1 | `SKILL.md:10-11` | Overview lists the flow stages (spec and plan review, acceptance checks, ... production gate), which the eight Flow step titles state again 20 lines later | duplicate | cut the list, keep the sentence and both failure modes | none: no rule in it |
| A2 | `SKILL.md:53-54` | Parenthetical after "Freeze them as that file says" repeats what that file says (`references/acceptance.md:47-53`: commit holds only checks; red output, hashes, owning unit to `state.md`) | duplicate | cut the parenthetical | low: the freeze-by-hash rule stays at `acceptance.md:47-53`, `SKILL.md:35-37`, `SKILL.md:109` and `SKILL.md:179`; the step is done once, with `acceptance.md` just read |
| A3 | `SKILL.md:150-152` | Parentheticals describing the "Waiting on you" and "Decided" columns | duplicate | cut; keep the "Delivered" one (test-pinned) | none: columns are in `ledger-template.md:17-25`; "exact step that clears it" stays at `SKILL.md:16`, source and reversal at `SKILL.md:131-138` |
| A4 | `SKILL.md:166-168` | Expansion of "spec gaps" (missing or contradictory scenarios, contract or data risks, unstated operator-only actions) | duplicate | cut the expansion, keep the four topic words | none: the reviewer never sees `SKILL.md`; its brief has the full list at `reviewer.md:18-30` |
| A5 | `SKILL.md:190` | "(after a `/clear` or not)" | low-value | cut | none |
| A6 | `reviewer.md:3-5` | Restates "fresh subagent that wrote nothing it reviews", "replaces CP's R1/R2", "one opus per unit, second by exception, security per milestone" | duplicate | cut | none: `SKILL.md:19`, `SKILL.md:164`, `SKILL.md:171-174` hold each of them, and the paragraph is not part of any brief |
| A7 | `reviewer.md:66-72` | Second-review conditions (hard, complex, not confident; record reason) repeated from `SKILL.md:172-173`; a rationale clause | duplicate | compress to 3 lines | none: kept what is only here (same brief, fresh reviewer per head, opus fallback where fable is not offered, never sees the first verdict) |
| A8 | `pr-watch.md:3-5` | Prose table of contents for the file | low-value | compress to one sentence | none: the section headings say the same |
| A9 | `pr-watch.md:36-39` | "Implementation runs in parallel" and a "So ..." rationale sentence, restating `SKILL.md:59-62` | duplicate | keep the rule and the ordering, cut the rest | low: only rationale is lost; "head that merges is the head that passed" stays at `pr-watch.md:88-89` |
| A10 | `pr-watch.md:100-102` | Repeats the progress line's PR states from `SKILL.md:155-156` | duplicate | compress; keep the definitions of `k` and `p` | none |
| A11 | `acceptance.md:3-5` | Navigation paragraph restating the three headings | low-value | compress; keep "haiku may run the steps, the orchestrator decides" | none |
| A12 | `acceptance.md:29-30` | Examples of "behaviour absent" and "check broken" | model-does-anyway | cut both example parentheticals; keep the guard example | none: the distinction is plain; the reviewer who judges it keeps its examples at `reviewer.md:49-51` |
| A13 | `implementer.md:27` | "They record what went wrong in earlier units." | model-does-anyway | cut | none |
| A14 | `ledger-template.md:3-5` | "Print Waiting on you at the top of every message", "final message lists PROVISIONAL rows" | duplicate | cut | none: `SKILL.md:157-158` and `SKILL.md:90` hold both rules |

Counts, applied: duplicate 9, low-value 3, model-does-anyway 2, over-specified 0.

## Findings recommended but NOT applied

| # | Location | What | Category | Proposed action | Risk | Why not applied |
|---|---|---|---|---|---|---|
| M1 | `SKILL.md:188-189` | "at every unit start, re-read this SKILL.md and `state.md`". The rulings ask only for `state.md` (spec `2026-11-20-run-plan-design.md:224` and `:261-263`). Each re-read adds about 2,350 words to the orchestrator's context, so a 10-unit plan adds about 23,000 words and brings the next compaction closer | over-specified | re-read `state.md` at every unit start; re-read `SKILL.md` at each milestone start and after a compaction | medium | It guards rule drift after a compaction the session does not notice. Whether Claude Code restores an invoked skill after compaction was not checked [LOW]. Needs an eval or a multi-unit trial, not a wording review |
| M2 | `SKILL.md:46` and `SKILL.md:88` | "State one alternative or objection you considered" twice. It has no defined place to go: `SKILL.md:157-158` forbids other chatter. The independent spec-and-plan review already supplies the objection at step 2 | low-value | cut the run-end one, or say both go to a "Decided" row | medium | It is the only implementation of spec goal 6 and §6.7 (spec `:36`, `:149-151`). A design decision, not a trim |
| M3 | `SKILL.md:38-40` | The preflight downgrade sentence; `pr-watch.md:7-23` holds the same rule in full | duplicate | replace with a one-line pointer (about 25 words saved per load) | medium | `test-structure.sh:84` pins the sentence verbatim as ruling R1 (spec `:283-285`). Changing a ruling's pinned text is the operator's call |
| M4 | `implementer.md:52` | "One git action per Bash command." Carried over from the conductor's unit prompt (spec `:100-101`). Its reason is not written anywhere in this skill | over-specified | cut if nothing depends on it | low to medium | The reason may be a command-firewall hook that inspects each Bash call [LOW, inferred]; the author should confirm before it goes |
| M5 | `SKILL.md:195-200` | Red flags table: both rows repeat `SKILL.md:92-102` | duplicate | none now; test with the canary arm | medium | See "kept" item K1 |

Counts, not applied: over-specified 2, low-value 1, duplicate 2.

Total findings: 19 (duplicate 11, low-value 4, model-does-anyway 2, over-specified 2).

## Considered for cutting, and KEPT

| # | Location | Looks like | Why it stays |
|---|---|---|---|
| K1 | `SKILL.md:92-102` and Red flags `SKILL.md:195-200` | The same two rules twice (operator-only deletion, silent contract break) | These are the two measured baseline failures: arm A is 0/4 on S2 and 0/4 on S3 in both registered runs (`FINDINGS.md:50-51`, `:104-105`), arm B 4/4. The eval cannot tell which copy does the work (canary not run, `FINDINGS.md:83`). About 70 words. `test-structure.sh:21` requires the heading |
| K2 | `acceptance.md:33-34`, `:64-66`, `:74-75`; `SKILL.md:55`, `:113-118` | "Never retry with other settings, free a resource, stop a process you did not start, deploy elsewhere" five times | Each copy reaches a different reader: the acceptance author (sonnet), the step runner (haiku), the orchestrator. The weakest model runs the deploy. Note: the eval does not show the baseline failing here. Arm A is 4/4 on S4 in v0.2 and v0.3.1 (`FINDINGS.md:52`, `:106`), so the "about 67%" baseline failure is S2 and S3 only. Kept on the false-done goal, not on eval evidence |
| K3 | Contract rule in `SKILL.md:100-102`, `implementer.md:44-46`, `reviewer.md:89-91`, `acceptance.md:23-27` | Four copies | Four readers, none of whom sees the others' brief. S2 evidence as in K1. Two copies are test-pinned (`test-structure.sh:38`) |
| K4 | Operator-only list in `SKILL.md:92-98`, `implementer.md:47-51`, `reviewer.md:23-24` and `:92-95`, `ledger-template.md:11-13` | Five copies | Same reason; S3 evidence. The ledger copy tells the operator what their answer will authorize, at the place they write it |
| K5 | `SKILL.md:130-133` and `:143-144` | Restates confidence-protocol's derivation order, evidence rule and preference gate (`confidence-protocol/SKILL.md:29-42`), which spec `:65-66` says not to restate | `SKILL.md` is re-read after compaction; confidence-protocol is not. About 30 words keep the Decisions section usable alone |
| K6 | `SKILL.md:169-170` | Acceptance-review criteria that `reviewer.md:42-53` holds in full | Twelve words; a fallback if the orchestrator briefs a reviewer without opening `reviewer.md`. This gate is the newest and has no eval evidence yet |
| K7 | `SKILL.md:186-187` | "fable only for an exceptional second unit review" repeats `SKILL.md:172` | Without it the line reads "opus for every Review", which contradicts the fable exception |
| K8 | `pr-watch.md:84` | "A pushed fix is a new head: review, checks and definition of done run again" repeats `SKILL.md:73` | Sits where the fix happens; guards "all three gates at one hash". 20 words in a file read about once per run |
| K9 | `pr-watch.md:60-66` | Long defensive procedure for an empty check result | Ruling 14 (spec `:299`); without it "no checks reported" right after a push reads as green and the unit merges unchecked |
| K10 | `implementer.md:54` | "Do not merge" repeats the Role paragraph (`implementer.md:21-22`) | Seven words; an implementer that merges skips every gate |
| K11 | `implementer.md:60-65` | "Stop rather than guess" overlaps the operator-only rail | It carries "do the rest of the unit", which S3 grades ("rest must still be delivered", spec `:171-172`) |
| K12 | `reviewer.md:79-81` and `:100-101` | Security surface list twice | The milestone reviewer gets check 7 but not Role (`reviewer.md:8-9`), and no reviewer has confidence-protocol loaded |
| K13 | `OVERLAY-TEMPLATE.md:34-48` | Notes repeat skill rules | Written for the operator who fills the overlay. Read by the run only when keys are missing (`SKILL.md:25-26`), so cutting saves almost nothing per run. File unchanged |
| K14 | `SKILL.md:184-187` | Model routing table | Not something a model does unprompted; it is the "proportionate token use" goal |

## Test changes

None. `plugins/autonomous-delivery/tests/test-structure.sh` is unchanged; every phrase it asserts on is
still present. Result in the patched copy: exit 0, 88 PASS, 0 FAIL (baseline at HEAD: 88 PASS).
Source: `scratchpad/patched-test.log` and `scratchpad/baseline-test.log`.

## Size before and after (`wc -l -w`)

| File | Lines before | Lines after | Words before | Words after | Words saved |
|---|---|---|---|---|---|
| `SKILL.md` | 200 | 197 | 2,414 | 2,346 | 68 |
| `OVERLAY-TEMPLATE.md` | 48 | 48 | 485 | 485 | 0 |
| `references/acceptance.md` | 83 | 81 | 1,003 | 962 | 41 |
| `references/implementer.md` | 76 | 76 | 762 | 754 | 8 |
| `references/ledger-template.md` | 44 | 42 | 469 | 438 | 31 |
| `references/pr-watch.md` | 102 | 98 | 1,192 | 1,115 | 77 |
| `references/reviewer.md` | 141 | 133 | 1,427 | 1,348 | 79 |
| **Total** | **694** | **675** | **7,752** | **7,448** | **304 (3.9%)** |

## What was not checked

- No eval run. The patch is not measured against `evals/run-plan-delivery`; the repository rule
  (spec `:63-64`) asks a change to an eval-gated skill to cite a green gate run.
- The plugin version (0.3.3, `test-structure.sh:10-12`) is not bumped.
- The patch applies cleanly to the clone (`git apply --check`, exit 0); it was not applied there, and
  nothing was committed or pushed. The clone's work tree is clean.
