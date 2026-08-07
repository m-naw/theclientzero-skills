# Findings — PSG seeded-defect recall

**Date:** 2026-08-07. All arms complete (n=4 each). Per-run grades in run dirs; grading delegated to clean-config sonnet judges with 4 spot-checks by the dispatching session (ledger).

## Results (recall of 10 seeds / false positives per rep)

| Arm | Recall per rep | Mean recall | FP per rep |
|---|---|---|---|
| A — single sonnet | 9, 10, 10, 10 | **97.5%** | 7, 4, 4, 5 |
| A2 — single opus | 10, 10, 10, 10 | **100%** | 18, 14, 13, 17 |
| B — PSG 10-agent roster | 9, 10, 10, 10 | **97.5%** | 9, 7, 4, 10 |
| C — roster minus srp/lsp/yagni | 7, 7, 6, 7 | **67.5%** | 3, 4, 2, 7 |

Per-seed: arm C missed `srp-1` 4/4, `yagni-1` 4/4, `yagni-2` 4/4, `lsp-1` 1/4 (isp/dip neighbors partially covered LSP). Arms A/B missed only scattered singles (A-1: ocp-1; B-1: yagni-2).

## Pre-registered verdicts

- **H2 eval validity: FAIL** — arm A mean recall 97.5% > the 85% ceiling. Seeds are too easy for current-generation single-pass review; the eval has no headroom to demonstrate a decomposition benefit and is **invalid for H1**.
- H1 coverage: unmeasurable (H2 failed); observed B − A = 0 points.
- **H3 canary: PASS** — removing sub-agents removes exactly their seeds' coverage (30-point recall drop). The harness reliably detects roster degradation and can gate roster changes.
- **H4 cost: TRIGGERED** — a single opus reviewer (and in fact a single sonnet reviewer) matches the full 10-agent roster's recall on this fixture. The roster costs ~10× and returned +0 recall, +noise (B's FPs ≥ A's).

## What the numbers say

1. **On a 125-line diff, single-pass review by a current-generation model finds essentially every classic principle violation.** PSG's founding claim — "single-agent serial review demonstrably skips principles (baseline test: missed LSP)" — is contradicted at this scale: all 4 baseline sonnet reps found the LSP violation, with the parent-contract citation.
2. **PSG's possible value is confined to diffs large enough to exceed a single reviewer's attention** — untested here and not testable on this fixture. Any claim about monster-diff coverage needs a monster-diff fixture (H2's design lesson).
3. **Opus as a single reviewer maximizes recall but at 3× the false-positive rate** — precision, not coverage, is where reviewer quality varies at this scale.
4. The two-axis contract itself was followed cleanly by principle-scoped reviewers (findings arrived in VIOLATION/CONCERN shape with citations) — the choreography executes; it just isn't needed for coverage at this diff size.

## Implications carried to the decision checkpoint

- PSG cannot cite coverage variance on ordinary diffs as its justification. Either (a) re-scope the skill explicitly to large diffs and build the large-diff fixture before further claims, or (b) fold its durable parts (two-axis severity contract, ≤3-findings budget, self-skip rules) into guidance for a single-reviewer gate and retire the 10-agent mandate.
- The uncited "baseline test: missed LSP" line in `SKILL.md` is now empirically contradicted and must be removed regardless of the path chosen.
