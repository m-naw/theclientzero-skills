# TheClientZero Skills

By [TheClientZero](https://x.com/TheClientZero) · [LinkedIn](https://www.linkedin.com/in/milosz-naworski)

Claude Code plugins that teach AI agents to **slow down before making consequential decisions** — and prove, with evals committed in this repo, whether each rule actually changes agent behavior.

Once installed, these skills trigger automatically at the right moments — decisions, merges, orchestrated worktree runs — without you having to think about it.

---

## What makes this marketplace different

Every skill here is validated by a falsification harness in [`evals/`](evals/). The evals are **development-time infrastructure for this repo** — skills are plain instructions with no runtime dependency on them. Each eval pre-registers arms, sample sizes, and the conditions under which the skill (or the eval itself) is declared falsified — before any run. Rules that fail their evals don't ship.

**What's measured, honestly:**

| Question a buyer should ask | Answer |
|---|---|
| Do agents actually commit the failure `git-discipline` prevents? | Yes — in a sandboxed orchestrator worktree, baseline agents corrupted the branch lineage **4/4** times when told main had advanced; with the skill loaded, **0/8**. Raw runs: `evals/git-discipline-redteam/` |
| Does `confidence-protocol` actually stop agents from deciding things that are yours to decide? | Yes — baseline agents unilaterally established an unpinned policy **7/8** times; with the skill, **0/8**. Raw runs: `evals/cp-vacuum-fill/` |
| Does the shipping gate's single review pass actually catch violations? | A single review pass catches **97.5%** of seeded violations — but that number belongs to *any* careful reviewer, skill or no skill (the eval measured the gate's marginal recall at zero on ordinary diffs). What the gate adds is structure: per-item verdicts so skipped principles are visible, two-axis blocking that resists severity-gaming, and verification-must-run. Raw runs: `evals/archive/psg-seeded-defects/` |
| Is everything here proven? | No. Whether a second independent reviewer improves what ships is **unmeasured** — two defect-catch evals voided themselves by their own validity rules (`evals/archive/review-catch/`, `evals/archive/review-catch-v2/`). The second-reviewer requirement is therefore scoped by an explicit, recorded operator decision (mandatory only on high-stakes surfaces: auth, money, regulated data, governance, migrations) rather than shipped as an unexamined default. |
---

## The problem this solves

LLMs are trained to produce a fluent, plausible answer to whatever you ask. When they don't know something, they don't stop — they fill the gap. In agentic workflows, the gap-filling that still happens at current model quality is specific, and it is what these skills target:

**Preference usurpation.** Ask an agent to "record the decision" on something no document pins down — 15-minute vs 8-hour admin sessions — and it will investigate beautifully, then establish policy it has no authority to set. Measured here at 7/8 baseline occurrences.

**Agents going rogue in orchestrators.** An agent inside a managed git worktree, told main has advanced, will helpfully rebase onto it — silently breaking the orchestrator's sync flow. Measured at 4/4 baseline occurrences.

**Unverified completion claims.** Merges declared done without running the project's own verification, skipped principles, gamed severity labels.

---

## Skills

### `confidence-protocol`

> Use before recording any decision that outlasts the conversation: a commit, a plan, an ADR, a config change.

Decisions move through named states — `INVESTIGATING → PROPOSED → REVIEWED → LANDED` — instead of pseudo-numeric confidence scores. The core rule is the **preference gate**: an agent must never establish a choice that no derivable source pins down (taste, priority, risk appetite, policy). The allowed output is a `PROPOSED` record: recommendation, cited evidence, and the named question the operator must pin. Factual claims require citations; independent review (with reviewer-owned triviality triage and a deterministic spot-check) moves a decision to `REVIEWED`; without reviewer infrastructure, nothing passes `PROPOSED` — an agent cannot promote its own work by reviewing itself.

**Real example:** asked to set an admin-session lifetime policy, a CP-loaded agent documents current behavior (7-day expiry, cited to file and test), recommends an option, explicitly marks the choice as an unpinned preference, and records the question for the operator — instead of writing `Status: Decided`.

### `principles-shipping-gate`

> Use before merging a PR or claiming completion on non-trivial code.

One reviewer, one pass, a fixed 9-item principle checklist (SOLID, YAGNI, typing, verification-must-run, project standards, named anti-patterns) with an explicit verdict per item — a skipped row means the gate didn't run. Findings follow a two-axis contract: only a concrete, file-cited violation from a blocking row blocks; advisory rows and vague concerns never do, closing severity-gaming in both directions. Parallel per-principle decomposition survives only as an explicitly-unvalidated escalation for large diffs.

### `git-discipline-in-managed-worktrees`

> Use when an AI agent operates inside an orchestrator-managed git worktree.

The validated contract for worker agents in orchestrated pipelines: stay on your feature branch (no merge/rebase/cherry-pick/reset from main — the orchestrator owns sync), never push, never bypass hooks, commit before handoff, `git rm` for deletions, never merge or close PRs. The prohibitions are absolute because the eval showed advisory phrasing performs like deletion. Generic by design — pair it with a project overlay; [`OVERLAY-TEMPLATE.md`](plugins/git-discipline-in-managed-worktrees/skills/git-discipline-in-managed-worktrees/OVERLAY-TEMPLATE.md) is included.

### `skill-observability` plugin

Ships a `PreToolUse` hook (`plugins/skill-observability/hooks/log-skill-call.sh`) that appends one JSON line to `.claude/skill-invocations.jsonl` per `Skill` tool call — the telemetry base for verifying that skills actually fire in your sessions. `jq` required; user-typed `/slash` invocations are not logged (different hook surface); subagent skill calls are logged with agent metadata. Honest status: in the one production deployment inspected, the hook had never shipped to the installed plugin and **no invocation telemetry exists anywhere yet** — install this plugin explicitly and verify a line appears in the log before trusting skill-fire claims.

---

## Cost

Lean by eval-driven design — every subagent a skill mandates has to earn its place against a measured baseline.

| Skill | What costs money | Rough cost per invocation |
| --- | --- | --- |
| `confidence-protocol` — trivial path | R1 triage read | **≈ $0.05 – $0.15** |
| `confidence-protocol` — non-trivial | R1 + independent R2 at pinned hash | **≈ $0.20 – $0.60** |
| `principles-shipping-gate` | one reviewer pass over the diff | **≈ $0.05 – $0.30**; large-diff escalation ≈ $1+ |
| `git-discipline-in-managed-worktrees` | pure instruction-following | **Negligible** |

Order-of-magnitude estimates, not quotes. Keep diffs small; run gates at PR boundaries; let the trivial path do its job.

---

## Evals

`evals/` contains three harnesses (red-team sandbox for git discipline, real-repo vacuum-fill for CP, seeded-defect recall for the shipping gate), their pre-registrations, raw per-run grades, and FINDINGS. Standing rules (`evals/README.md`): pre-registration before runs, deterministic asserts over judges wherever possible, subjects never told they're being tested, and the **degradation canary** — an eval may gate skill changes only if it can detect a deliberately gutted variant. Skill changes that alter gated surfaces must cite a green gate run.

Methodology scars are documented in the ledgers, including: session subagents are unusable as eval subjects (an installed marketplace leaks into their context and contaminates baselines), and visible canary labels make subjects detect the test and self-correct.

---

## Install

In Claude Code:

```
/plugin marketplace add m-naw/theclientzero-skills
/plugin install confidence-protocols@theclientzero
/plugin install git-discipline-in-managed-worktrees@theclientzero
/plugin install skill-observability@theclientzero
```

Skills activate via the `Skill` tool — only when their trigger matches. To verify they actually fire, install `skill-observability` and check `.claude/skill-invocations.jsonl` after a session.

## License

MIT
