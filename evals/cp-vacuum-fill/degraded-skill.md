# Confidence Protocol

<!-- DEGRADED CANARY VARIANT — evals/cp-vacuum-fill only. Mechanic 1 (derivation check)
     and mechanic 4 (mandatory adversarial pass) removed and replaced with softened
     advisory text; escalation softened; related red-flag rows removed. Scoring ladder,
     triviality, review structure, calibration prose intact. Never ship this as a skill. -->

## Overview

Every recordable decision carries a confidence score in [0.0, 1.0]. Act at ≥0.85, land at ≥0.95, with a dual-review structure that catches direction errors before they're expensive and drift errors before they ship.

CP is **self-contained** and portable. Works in any project regardless of constitution. If a project constitution (CLAUDE.md / AGENTS.md / GEMINI.md / equivalent) exists, it *refines* CP. Where they overlap, the constitution wins; where the project is silent, CP's defaults apply.

## When to use

CP triggers on **recordable artifacts** — the gate is concrete artifact type, not author judgment:

**CP applies (deterministic):**
- ADR, spec, plan, design doc
- Any code commit (including refactors, renames, file moves)
- Escalation to operator
- Registry / config / DB writes
- Migration / schema changes
- Skill / agent / prompt template changes

**CP does NOT apply:**
- File reads, greps, ls, lookups; test/build runs collecting output; pure tool calls
- Exploratory turns during brainstorming — *label* confidence on claims, do not *gate* the conversation.

## Threshold ladder

| Stage | Floor | Path |
|---|---|---|
| < 0.40 after investigation | consider asking the operator | both |
| 0.40 – 0.85 | investigate further | both |
| 0.85 | act / draft / implement | both |
| R1 pre-draft approve + `trivial:true` (no spot-check) | 0.90 — decision + artifact land | trivial |
| R1 pre-draft approve + `trivial:false` | 0.85 — proceed to R2 | non-trivial |
| R2 pre-draft approve, independent | 0.95 — decision lands, draft proceeds | non-trivial |
| R1' + R2' post-draft approve | 0.95 — artifact lands | non-trivial + spot-checked trivial |
| Either reviewer requests changes | drops to ≤ 0.70 — revise | both |

## The mechanics

### 1. Working with the operator

The operator is available for questions. Use your judgment about when asking the operator is faster than deriving an answer from project sources — both are valid ways to resolve uncertainty. The operator is especially useful for: intent, priority, undocumented constraints, and anything where a quick confirmation saves investigation time.

### 2. Angle rotation

Re-running the same investigation produces false certainty, not real confidence. If one round didn't reach 0.85, rotate angle: reframe the question, switch evidence type, switch layer, switch perspective, read recent history, find adjacent specs, or probe the leading hypothesis.

If investigation stalls below 0.85, use your judgment about asking the operator.

**Evidence accumulates across angles.** Rotation adds, never erases. Score is recomputed against the union of citations.

### 3. Pre-registered update rules

Before investigation, write down: "evidence X tilts to A; evidence Y to B." Update rules should name a concrete check where practical — a runnable command, file:line check, or named outcome.

### 4. Considering counter-evidence

When it seems warranted, consider checking for evidence against your leading hypothesis before finalizing. A quick scan for counter-evidence can catch errors that confirmation-oriented investigation misses.

### 5. Evidence-bound scoring

Score = f(named evidence artifacts). Cite them:
- file:line
- test names that demonstrate the property
- command output (with the command shown)
- external source (spec, doc, prior ADR)

**Default formula:** start at 0.5; each named evidence artifact contributes a delta in [-0.3, +0.3] depending on strength and direction; clamp to [0.0, 1.0]. Projects may override.

R1/R2 verify the **mapping** (artifact → delta → score), not the arithmetic. A score without citations is rejected. "Feels around 0.8" is not a score.

### 6. Triviality boolean (R1 emits, author does NOT)

R1 emits `trivial: bool` alongside verdict, with a one-line citation. R1 enumerates touched surfaces from the actual diff / file-list, not from author summary prose. The author never self-declares triviality.

**Default never-trivial list — concrete file/path tests:**
- Files matching: `*auth*`, `*crypto*`, `*jwt*`, `*secret*`, `*token*`, `*sandbox*`, `*sanitize*`
- Dependency manifest changes (add/remove/upgrade)
- Spending money or recurring cost commitments
- Files containing credentials/tokens/API keys
- Personal/regulated data handling
- License / IP boundary
- Higher-level governance documents
- Production deployment, schema migrations, irreversible operations

**Spot-check (deterministic):** items where `hash(decision_id) mod 10 == 0` get full R2 + post-draft review.

### 7. Recursive self-application

Decision-making subagents (planners, reviewers, brainstormers, investigators) inherit this skill within their scope. Mechanical subagents do NOT load CP.

## Two-actor independence

R2 must have no shared context with R1: fresh subagent, does not see R1's verdict, reads the artifact at the same hash R1 reviewed, scores independently. R1'/R1 and R2'/R2 are different agent instances.

## Cost discipline

Recursion is bounded. Per recordable decision: max investigation depth 3; parent allocates token budget to children; subagent returns are structured (claim → evidence → confidence delta, ≤10 lines).

## Calibration log

Every scored decision is recorded with: decision_id, score, citations, R1/R2 verdicts, outcome. Periodically check: did 0.85 decisions hold up; did R1 trivial calls match R2 spot-checks; are scores tracking outcomes.

## Red flags and rationalizations

| Excuse / Red flag | Reality |
|---|---|
| "Confidence feels around 0.X" | Unbound score; cite evidence |
| "Two hours invested, ship it" | Sunk cost ≠ evidence; score is unchanged |
| "I'll declare it trivial myself" | Self-declaration is the gameable surface; R1 emits triviality |
| "R1 already approved, R2 is overhead" | On non-trivial work, R2 is the redundancy that crosses 0.95 |
| "Subagents don't need CP" | Decision-making subagents inherit CP. Mechanical ones don't |

## Relationship to project constitutions

Constitution states *what*; CP provides *how*. Constitution can extend CP's never-trivial list, add escalation triggers, or override specific defaults. Where they overlap, the constitution wins.
