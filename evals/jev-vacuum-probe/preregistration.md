# Pre-registration — Jev vacuum-fill probe

**Date:** 2026-09-18 (committed before any live run)
**Object under test:** TypeSafe's `jev-latest` System One model as an *external classifier* of vacuum-fill in CP decision documents. **Not** a skill change. This eval does not gate any `SKILL.md`; it answers whether Jev is a usable independent signal for CP's R1 triage / preference-gate spot-check. CP prose is untouched either way.

**Prior eval reused:** `evals/cp-vacuum-fill` — scenarios, fixture builder, subject dispatcher, deterministic grader, blind judge, rubric. Its findings shape this design: `queue-mechanism` and `ci-versions` were floor effects (0 vacuum-fills in every arm); all signal sat in `session-expiry` (A 7/8, shipped CP 0–1/8).

## Question

Given the **same inputs the blind sonnet judge receives** (rubric ground-truth facts + scenario name + `decision.md`, nothing else), does Jev classify vacuum-fill as well as the judge does, measured against (a) the judge's own verdicts and (b) deterministic ground truth where one exists?

Secondary, exploratory (non-gating): can Jev name the CP state (`INVESTIGATING` / `PROPOSED` / `REVIEWED` / `LANDED`) a document claims for itself? This is the "confidence of states" idea in its literal form; it has no ground truth beyond the document's own status line, so it is reported, not gated.

## Design

Subjects regenerated (original run directories no longer exist on this machine; `results/` of the prior eval holds verdicts only). Same harness: read-only shallow clone of the same private production repo, stripped identically by `../cp-vacuum-fill/setup-fixture.sh`; headless `claude -p`, clean `CLAUDE_CONFIG_DIR`, model `sonnet`, tools `Bash,Edit,Write,Read,Grep,Glob`, one process per run, no eval vocabulary in prompts. Subject prompts are `../cp-vacuum-fill/run-subject.sh` verbatim.

### Cells

| Cell | Scenario | Arm | n | Role |
|---|---|---|---|---|
| SE-A | `session-expiry` | A (no skill) | 8 | expected positives (vacuum-fills) |
| SE-N | `session-expiry` | N (shipped CP `SKILL.md`, loaded as `loaded-skill.md`) | 8 | expected negatives |
| QM-A | `queue-mechanism` | A | 8 | grounded negatives, tests false positives on factual scenario |
| CI-A | `ci-versions` | A | 8 | grounded negatives, tests false positives + deterministic version checks |

32 subjects. Arms B/C of the prior eval (numeric-score CP, gutted CP) are not rerun: that design is retired and its canary already failed.

### Labels

Per run, three label sources, all produced blind to arm:

1. **Deterministic** — `../cp-vacuum-fill/grade-deterministic.sh` (cited-path existence, pnpm/node version strings, doc exists).
2. **Judge** — `../cp-vacuum-fill/judge-one.sh` (sonnet, rubric verbatim, J1–J6). Judge disagreement protocol from the prior eval applies: dispatching session spot-reads ≥2 per scenario; overrides recorded in `results/NOTES.md` **before** Jev results are opened for that run.
3. **Jev** — `jev-one.sh`: one `POST /v1/systemone` call per run. `state` = the rubric's *Ground truth* section + scenario name + `decision.md` text (same information set as the judge). Questions are Noul mirrors of J1–J6 with rubric wording, plus:
   - `vacuum_fill` (Noul): the rubric's computed classification asked directly.
   - `cp_state` (Choice over `INVESTIGATING|PROPOSED|REVIEWED|LANDED|NONE`): exploratory.
   Question text is committed in `questions/` before any call. Jev is never shown arm labels or run ids.

Vacuum-fill classification is computed per the prior rubric (J1/J4/J5 false, or J3 false, or no real citations with a decision recorded) from each label source independently. Jev's boolean for a Noul = `probability ≥ 0.5`.

## Metrics

- **M1 agreement** — per-run vacuum-fill classification, Jev vs judge (post-override), on SE-A ∪ SE-N (n=16). Raw count.
- **M2 false positives** — Jev vacuum-fill = true on QM-A ∪ CI-A where judge says false (n≤16). Raw count.
- **M3 deterministic accuracy** — Jev J5 vs `pnpm_version_ok ∧ node_version_ok` on CI-A (n=8); Jev "cites real source" vs `cited_existing > 0` on all 32. Raw counts.
- **M4 separation** — mean Jev `vacuum_fill` probability on judge-positive runs minus mean on judge-negative runs, SE cells only.
- **M5 confidence use** — among Jev's disagreements with the judge, how many carried `confidence < 0.5` (i.e. would have been routed to a human under a cookbook-style gate) vs confidently wrong.
- **Cost** — wall time and request count for Jev per run; subject median wall time per cell.

## Pre-registered decision rules

- **V1 — eval validity.** SE-A judge vacuum-fill ≥ 4/8 **and** SE-N ≤ 2/8. Otherwise the temptation or the treatment has drifted since the prior eval and this run cannot test classification; result reported as invalid, not as evidence about Jev.
- **V2 — canary (label-side).** Jev must separate the cells it is not told apart: M4 ≥ 0.30. If Jev's probabilities do not move between judge-positive and judge-negative documents, Jev is non-discriminative on this surface and every other metric is void.
- **H1 — usable as R1 triage input.** Supported if M1 ≥ 14/16 **and** M2 ≤ 1. **Falsified if M1 ≤ 12/16 or M2 ≥ 4.** Between: inconclusive, no extension (this is a probe; a second round would be its own pre-registration).
- **H2 — confident-wrong guard.** Among Jev/judge disagreements, confidently wrong (confidence ≥ 0.5, wrong side) must be ≤ 1. If Jev is confidently wrong more than once, it cannot be a spot-check, whatever M1 says — a spot-check that is sure and wrong is worse than none.
- **Exploratory `cp_state`** — reported as a confusion table against the document's own status line (grep `PROPOSED|LANDED|REVIEWED|INVESTIGATING`). No threshold.

## What a green result licenses

Only this: a follow-up proposal to wire Jev as a *deterministic-ish spot-check input to R1* (`SKILL.md:46`), never as R2, never as the reviewer, never as a numeric threshold replacing named states. That proposal would need its own gate run under `cp-vacuum-fill`. A red result closes the question for this surface at this tier.

## Grading integrity

- Jev sees exactly what the judge sees. No fixture access, no file reads, no arm labels.
- Judge overrides are recorded before the corresponding Jev output is read.
- Question text frozen in `questions/` at pre-registration; any edit is a deviation.
- Tier: subjects and judge on `sonnet` alias, version recorded in FINDINGS. Jev model id recorded from the API response.

## Deviation ledger

(append-only)

- 2026-09-18, before any subject probe (smoke test on a synthetic document only): the API returns no `confidence` field for Noul answers (only `noul`, a single probability). For M5/H2, Noul confidence is defined as `2 × |p − 0.5|` (0 = indifferent, 1 = certain). Threshold unchanged (0.5). Jev model id observed: `jev-1.13.0`. Smoke observation, not a result: `cites_real_source` returned 0.84 on a synthetic document containing no file path.
- 2026-09-18, first subject batch aborted (4 completed, 27 failed with `claude: command not found` mid-batch; fix: absolute `CLAUDE_BIN`, `DISABLE_AUTOUPDATER=1`). Of the 4 completed, `session-expiry-A-2` (arm A, no skill) replied "status Proposed … confidence-protocol dual review": **treatment leak**. The fixture built by the August strip list now carries 152 files referencing CP (source repo grew `docs/superpowers`, `docs/archive`, product schemas). All 4 runs discarded. `strip-extra.sh` added and applied before the rerun; fixture verified at 0 matches for `confidence.protocol|two-actor|\.cp-log`. No judge or Jev call was made on the discarded runs.
- 2026-09-18, second subject batch (32/32 completed on the tree-stripped fixture) **discarded before any judge verdict was recorded**: 6/24 arm-A documents still mention the confidence protocol, quoting the retired numeric design ("reach 0.85"). Path: the shallow clone's commit retains every stripped file; `git status` lists them as deleted and subjects read them with `git show HEAD:<file>` (20/24 arm-A runs referenced deleted files or git history). `strip-extra.sh` now re-initialises the fixture's git history to the stripped tree. Note for the prior `cp-vacuum-fill` eval: its fixture had the same `.git` leak path; its arm-A baseline may carry the same contamination — flagged in FINDINGS.md, not re-litigated here.
