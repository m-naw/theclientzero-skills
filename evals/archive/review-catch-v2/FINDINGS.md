# Findings — review-catch v2

**Date:** 2026-08-07. All arms complete; grades in `results/`.

## Results (catch rate of 6 fabricated-count seeds)

| Arm | n | Catch | False alarms |
|---|---|---|---|
| R1-alone (independent, verify-mandated) | 16 | **99.0%** | 0 |
| R1+R2 union (8 pairs) | 8 | 100% | 0 |
| L (lazy, tools) | 6 | 94.4% | 0 |
| NT (no tools — canary) | 6 | **0.0%** | 0 |

## Pre-registered verdicts

- **V2 verification-dependence canary: PASS** — without tools, zero seeds caught; the flaw class genuinely requires verification.
- **V1 headroom: FAIL → eval VOID.** R1-alone at 99% leaves no room to measure a second reviewer's marginal (+1.0 pt observed, non-gating).
- H1 observational: reviews catch fabricated counts essentially perfectly *when counting is salient*, with zero miscounts of true claims across 28 runs.
- **H2 does not fire**; mandatory R2 neither validated nor demoted by this eval.

## The discovery inside the void

v1's discriminating seed (a fabricated count buried among prose claims: 8/16 caught) vs v2 (an explicit inventory of counts: 16/16 on five seeds, 15/16 on the sixth). Same flaw class, same model, same verification cost — the difference is **salience**. The reviewer bottleneck at this tier is *noticing that a claim needs checking*, not the checking itself. A discriminative v3 must bury quantitative claims at low salience inside long mixed artifacts — a materially harder fixture-design problem, noted for future work.

## Accumulated position after two attempts

Two ceiling-voided evals; R2 marginal measured +4.2 and +1.0 points, neither gateable. There is **no measured evidence that a mandatory second reviewer adds catches at this tier**, and no valid measurement that it doesn't (live, uncontrolled session evidence exists of R1 and R2 catching disjoint real defects on governance artifacts). Whether mandatory R2 stays is therefore not derivable from any source — per the confidence protocol's own preference gate, that choice is the operator's to pin, recorded as such.

## Operator pin (2026-08-07)

Presented with both voided measurements and the live disjoint-catch evidence, the operator pinned: **R2 mandatory only on never-trivial surfaces** (auth, money, PII/regulated data, governance, migrations, irreversible operations); other non-trivial work lands on R1 plus the deterministic spot-check. Implemented in the CP SKILL.md review section; the text change passed CP's vacuum-fill gate (run N3).
