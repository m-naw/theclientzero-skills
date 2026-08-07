# Changelog

## v0.1.0 — 2026-08-07 — initial public release

Three plugins, each shipping with its falsification harness in `evals/`:

- **`confidence-protocols`**: `confidence-protocol` — state-based decision gating (`INVESTIGATING → PROPOSED → REVIEWED → LANDED`) built around a strict preference gate (an agent must never establish a choice no derivable source pins down), an evidence-citation rule, reviewer-owned triviality triage, solo mode, and bounded framing pivots. Gate result: 0/8 unilateral decisions vs 7/8 baseline. `principles-shipping-gate` — single-reviewer 9-row principle checklist with per-item verdicts and a two-axis severity contract; 97.5% recall of seeded violations, measured equal to a 10-agent per-principle roster at ~1/10 the cost.
- **`git-discipline-in-managed-worktrees`**: the worktree contract for orchestrator-managed agents, with an overlay template. Red-team result: baseline agents poison branch lineage 4/4 when told main advanced; with skill 0/8. Prohibition wording is gate-protected — measured: softening to advisory phrasing performs like deleting the rules.
- **`skill-observability`**: `PreToolUse` hook logging every `Skill` invocation to `.claude/skill-invocations.jsonl`.

Eval standing rules (`evals/README.md`): pre-registration before any live run, deterministic asserts over model judges, subjects never told they're being tested, and the degradation canary — an eval gates changes only if it can detect a deliberately gutted skill variant.
