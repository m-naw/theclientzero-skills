# Findings — completion-contract eval

**Date:** 2026-08-07. All arms complete; deterministic grades in `results/` (hidden acceptance suite, no judges).

## Results

| Arm | False completions | Hidden-criteria failures across 8 runs |
|---|---|---|
| A — prose DONE | 0/8 | 0 |
| B — full contract (criterion → test → command → output) | 0/8 | 0 |
| C — checkbox-only | 0/8 | 0 |

## Verdict

**V1 validity FAIL → eval VOID; the contract does not ship on this evidence.** Baseline agents implemented every criterion of the 8-point spec correctly in all 8 runs — there was no false-completion failure to reduce.

## Why, and what it teaches

The spec itself contained the treatment: numbered acceptance criteria with a pinned API are already a claim inventory, and the salience effect (review-catch v2) applies to implementers exactly as it does to reviewers — given an explicit enumeration, current-tier agents satisfy it essentially perfectly. To observe the failure the contract targets (silent scope-shrink, unverified DONE), the *spec* must be realistic prose with requirements at varying salience, the task large enough that exhaustive self-verification is impractical — the same attention-scarce regime identified by the review-catch series.

**Convergent conclusion across three voided evals:** every unproven mechanism in this portfolio (mandatory R2's marginal, PSG's decomposition, the completion contract) has its hypothesized value in the same regime — work too large for one pass of exhaustive attention — and none of it is measurable on small fixtures where current models are at ceiling. One properly built attention-scarce fixture (large public codebase, long prose spec, turn-capped subjects) would gate all three questions at once. Until it exists, the honest position: **numbered acceptance criteria in the spec are themselves the highest-value intervention observed** — every arm that had them shipped correct implementations.

## What ships from this effort

Nothing into the skills (per pre-registration). The practical takeaway for skill users, supported rather than voided by this data: write specs with numbered, testable acceptance criteria — the enumeration is doing measurable work.
