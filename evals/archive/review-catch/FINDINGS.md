# Findings — review-catch eval

**Date:** 2026-08-07. All arms complete; grades in `results/` (blind sonnet graders, 3 spot-checked).

## Results (mean catch rate of 6 planted verification-class flaws)

| Arm | n | Catch rate | False alarms |
|---|---|---|---|
| R1-alone (independent, verify-mandated) | 16 | **91.7%** | ~0 |
| R1+R2 union (8 disjoint pairs) | 8 pairs | **95.8%** | ~0 |
| S (self-review framing, exploratory) | 8 | 93.8% | ~0 |
| L (lazy canary — no verification mandate) | 4 | **87.5%** | ~0 |

Per-seed: 5 of 6 seeds caught 16/16 by arm R (failing verify script, contract-violation throw, missing switch case, nonexistent cited test, unread flag). The only discriminating seed: the **fabricated count** ("consumed by 5 modules", actually 0) — caught 8/16.

## Pre-registered verdicts

- **H3 canary: FAIL → eval VOID.** L trails R1 by 4.2 points, not the required 25. Reviewers verify claims even without a verification mandate — the control condition this eval needed does not exist at the tested tier (all arms: Claude Sonnet, the `sonnet` alias resolving to Sonnet 5 at run time). Per the registration, no other hypothesis may gate anything.
- H1 (observational only): reviews catch verification-class flaws at 91.7% with near-zero false alarms.
- H2 (observational only): R2's marginal contribution measured +4.2 points. **The pre-committed R2-demotion consequence does not fire on a void eval**; the protocol keeps mandatory R2 on non-trivial work, and its cost-justification remains an open question.

## What a valid successor needs

The flaw class that splits reviewers is quantitative claims requiring recounting (the "5 modules" seed). A discriminative v2 uses seeds built entirely from that class — fabricated counts, wrong line totals, off-by-N inventories — where catch rates leave the ceiling. Until then, the outcome-level claim about independent review stays unmeasured; the production route (spot-check-as-RCT via calibration-log outcome fields) remains the path to the real answer.
