# Pre-registration — PSG seeded-defect recall

**Date:** 2026-08-06 (committed before any live run)
**Skill under test:** `plugins/confidence-protocols/skills/principles-shipping-gate/SKILL.md` — its core claim: parallel per-principle decomposition removes the coverage variance of single-pass review ("reviewer skips a principle they don't think applies").

## Question

Does PSG's per-principle decomposition find more seeded principle violations — with lower variance across repetitions — than a single-pass review of the same diff? And is the 10-agent roster earning its cost against a single stronger-model reviewer?

## Design

Fixture: a small TypeScript service (committed under `fixture/`) plus a PR-style unified diff introducing **seeded violations** with a ground-truth manifest (`fixture/seeds.json`): SRP, OCP, LSP, YAGNI (×2: dead class + dead flag), typing (×2: `any` public surface + untyped export), declared-standards breach, failing verification script, and one advisory-roster anti-pattern (primitive obsession). Seeds are planted before any arm runs and never adjusted afterward.

Reviewers are headless `claude -p`, clean config, given the base checkout + diff. The PSG arms execute the skill's choreography as written (the dispatcher plays the orchestrator role the skill addresses): one fresh reviewer per principle with the skill's violation/concern contract, aggregated per the skill's two-axis rule.

### Arms (n = 4 repetitions each)

| Arm | Shape |
|---|---|
| **A** | single sonnet reviewer, generic prompt: "review for code-quality principles (SOLID, YAGNI, typing, verification, project standards); findings as file:line + scenario" |
| **A2** | same prompt, single **opus** reviewer (answers the roster-vs-stronger-model cost question) |
| **B** | PSG as specified: 7 blocking + 3 advisory principle-scoped sonnet reviewers, ≤3 findings each, two-axis aggregation |
| **C** (degraded canary) | PSG roster with `srp`, `lsp`, `yagni` sub-agents removed, everything else identical |

## Metrics

- **Recall**: seeded violations found / total seeds (a seed counts as found if any finding cites its file and overlapping lines, or unambiguously describes it; matching table filled by the dispatching session against seeds.json, recorded per run).
- **Variance**: per-arm across-rep spread of recall (max−min and per-seed hit consistency). PSG's claim is specifically about variance.
- **Precision**: findings not matching any seed = false positives (rate per run).
- **Contract fidelity** (arm B/C only): % findings emitted in the skill's violation/concern shape with file:line + scenario.

## Pre-registered decision rules

- **H1 — coverage.** Supported if arm B mean recall ≥ arm A mean recall + 15 percentage points, or arm B min-recall ≥ arm A min-recall + 20 points (variance channel). **Falsified if B ≤ A on both.**
- **H2 — eval validity.** Arm A mean recall must be ≤ 85% (otherwise seeds too easy — no headroom to detect decomposition benefit; eval invalid).
- **H3 — canary.** Arm C must miss ≥ 2 of the 3 seeds owned by removed sub-agents (srp/lsp/yagni) on ≥ half its reps while arm B finds them; otherwise the eval cannot detect roster degradation and is void.
- **H4 — cost question (reported, not gating).** If A2 (single opus) recall ≥ B recall − 5 points, the 10-agent roster's cost is not justified by coverage alone; PSG's shape should be revisited.

## Deviation ledger

(append-only)

- 2026-08-07, final: seed-matching delegated to clean-config sonnet graders (`grade-recall.sh`) instead of hand-filling by the dispatching session; 4 grader outputs spot-checked (A-1 miss list, B-1 miss list, C-2 absence of SRP findings, A-1 LSP/SRP finding text) — all accurate. Results: H2 FAIL (baseline 97.5% > 85% ceiling — eval invalid for H1), H3 PASS (canary: 30-point drop tracks removed sub-agents), H4 triggered (single reviewer ≡ 10-agent roster). Synthesis in FINDINGS.md.
- 2026-08-07, ops: subject/judge dispatches require re-copying `~/.claude/.credentials.json` into the clean config before each batch (OAuth refresh rotation invalidates stale copies) and an absolute `CLAUDE_BIN` (nvm PATH flakiness in non-interactive shells).
