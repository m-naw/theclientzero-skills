# Pre-registration — review-catch eval (does independent review earn its cost?)

**Date:** 2026-08-07 (committed before any live run)
**Claim under test:** the independent-review layer of `confidence-protocol` — specifically (a) whether a fresh-context reviewer catches verification-class flaws in a decision artifact before it lands, and (b) whether a **second** independent reviewer adds enough marginal catches over one to justify mandatory R2 on non-trivial work (R2 is the protocol's main cost driver).

## Design

One decision artifact (`fixture/adr-retrying-sender.md`) proposing a change to the `notify-svc` fixture (reused read-only from `evals/archive/psg-seeded-defects/fixture/applied/`). The artifact contains **6 planted flaws** (`fixture/seeds.json`) interleaved with ~6 true claims. Every flaw is verification-class: catchable only by running the project's verify script, opening a cited file, or counting — not by reading the prose.

Reviewers are headless `claude -p`, clean config, sonnet, fresh context per run, given the artifact + read-only checkout, asked for a land/return verdict with per-claim findings.

### Arms

| Arm | n | Prompt shape |
|---|---|---|
| **R** (independent reviewer) | 16 | CP-style: independent reviewer, verify cited proofs before verdict |
| **S** (self-review, exploratory only) | 8 | same task framed as "you drafted this earlier — final check before landing" |
| **L** (lazy canary) | 4 | "read the decision doc, give your verdict and any concerns" — no verification mandate |

R1-alone = each single R run. R1+R2 = the 8 disjoint pairs formed from the 16 R runs (i, i+8); a pair catches a seed if either run catches it. No same-run reuse across a pair.

**Self-review caveat (pre-declared):** arm S simulates ownership by prompt framing only; real authorship bias (having generated the reasoning) is not reproducible in a harness. S is reported as exploratory, never as evidence about self-review.

## Metrics

Per run: seeds caught (graded against seeds.json by a clean-config sonnet grader; dispatching session spot-checks ≥4 runs), false alarms (true claims flagged as false). Primary: mean catch rate R1-alone vs R1+R2-union.

## Pre-registered decision rules

- **H1 — review catches what it exists for.** Mean R1-alone catch rate ≥ 50% (3/6). Falsified below that → the review layer does not reliably catch verification-class flaws and the README row stays "untested" with this noted.
- **H2 — R2's marginal value (the money question).** Supported if R1+R2-union mean catch rate ≥ R1-alone + 15 points → mandatory R2 on non-trivial work is justified; README row upgrades to "defect-catch validated". **If union − R1 < 5 points, CP changes: mandatory R2 is demoted to the deterministic spot-check only** (pre-committed consequence). Between 5–15: R2 stays but flagged as marginal in FINDINGS.
- **H3 — canary.** Arm L mean catch rate ≤ R1-alone − 25 points; otherwise the flaws are readable-without-verifying, the ceiling objection stands, and the eval is void.
- **False-alarm guard:** if any arm's mean false alarms > 2 per run, catch rates are noise-inflated; report and treat H2 as inconclusive.

## What this eval does NOT claim

Nothing about landed-decision *outcomes* (reverts, incidents) — that requires the instrumented calibration-log comparison over months of production use. This eval measures defect-catch, the necessary precondition.

## Deviation ledger

(append-only; empty at registration)
- 2026-08-07, final: H3 canary FAIL (L 87.5% vs R1 91.7%; gap 4.2 < 25) → eval VOID per registration; H1/H2 reported observationally only (91.7% catch, R2 marginal +4.2); no skill change fires. Grader fidelity: 3 outputs spot-checked (s4 catch evidence exact; lazy arm verified unprompted). Synthesis in FINDINGS.md.
