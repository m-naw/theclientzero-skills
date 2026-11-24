# run-plan flow (v0.3.4)

ASCII map of `plugins/autonomous-delivery/skills/run-plan/SKILL.md`. `[if …]` = conditional,
`(model)` = who does it, `⇒ ledger` = a "Waiting on you" item; the run continues.

```
 /run-plan <spec>                          /run-plan continue
        │                                          │
        │                           read state.md + ledger + overlay
        │                           check what landed (git log, PRs, deploy)
        │                           [if operator answered] do exactly that;
        │                              re-freeze only the check ids it touches
        │                                          │
        ▼                                          ▼
┌─ 1 START / PREFLIGHT ─────────────────────────────────────────────────────┐
│ read overlay (.claude/run-plan.md) + spec      [if no overlay] ⇒ ledger,  │
│ default branch green? verify passes?                         use defaults │
│ hash overlay + deploy/acceptance/monitor/teardown/rollback scripts        │
│ [if red main outside scope]        ⇒ ledger; merge:self units wait        │
│ [if merge to main deploys prod or unknown] merge:self → merge:human       │
└───────────────────────────────────────────────────────────────────────────┘
        ▼
┌─ 2 PLAN + REVIEW ─────────────────────────────────────────────────────────┐
│ plan: milestones → units, deps, parallel-safe marks, scenario→unit        │
│ spec+plan review (opus, 1 reviewer, ≤2 rounds, never blocks):             │
│   derivable → fix + Decided   preference → build PROVISIONAL              │
│   operator-only → ⇒ ledger    still disputed → PROPOSED record            │
└───────────────────────────────────────────────────────────────────────────┘
        ▼
┌─ 3 ACCEPTANCE CHECKS (fresh subagent, writes no code) ────────────────────┐
│ one check per scenario id, run vs deployed base → must FAIL (red)         │
│ [if base already passes] keep only as named `guard`                       │
│ [if base can't deploy] freeze as "red: not shown" ⇒ ledger               │
│ checks review (opus, wrote no check): coverage, vacuous pass,             │
│   behaviour not structure, red for the right reason; ≤2 rounds, no block  │
│ FREEZE: hashes + owning unit → state.md                                   │
└───────────────────────────────────────────────────────────────────────────┘
        ▼
┌─ 4 UNITS (dependency order) ──────────────────────────────────────────────┐
│                                                                           │
│  implement ── [if parallel-safe] up to 3 at once, own worktree each       │
│  (sonnet)     else one at a time                                          │
│      │                                                                    │
│      ▼  ── from here strictly one unit at a time (shared env + target) ── │
│  [if target moved] rebase                                                 │
│      ▼                                                                    │
│  a. review (opus, 1 per head)  [if hard/complex/unsure] + fable 2nd       │
│      ▼                                                                    │
│  b. CI on PR (haiku watches in background)  [if no CI] run verify         │
│      │ [if red] sonnet reads failing log tail → fix → back to a.          │
│      │ [if red not caused by PR] ⇒ ledger, never weaken tests/CI          │
│      ▼                                                                    │
│  c. DEFINITION OF DONE (on unit head, before merge)                       │
│     hashes unchanged → deploy_test → acceptance → monitor(window)         │
│      │ [if step fails] rerun once → fix with data, ≤2 rounds              │
│      │   → [if rollback declared] rollback → ⇒ ledger                     │
│      │ [if cause outside code] ⇒ ledger at once, no workaround            │
│      ▼                                                                    │
│  d. merge into target ── only if a+b+c passed at same hash                │
│      │ [if protected path / operator-only action] HOLD ⇒ ledger          │
│      │ [if not done / blocked] no merge ⇒ ledger, skip dependents,        │
│      │                         continue independent units                 │
│      ▼                                                                    │
│  state.md: status, Delivered row, Lessons; progress line → chat + state   │
│  "Unit k/N (p%) — milestone m/M — PR #n: CI … — … — waiting on you: n"    │
└───────────────────────────────────────────────────────────────────────────┘
        ▼   (repeat 4 per unit; at milestone end ↓)
┌─ 5 MILESTONE END ─────────────────────────────────────────────────────────┐
│ capstone (opus) + security review (opus) of milestone diff                │
│ [if milestone has 1 unit] one opus review covers unit+capstone+security   │
│ [if High finding] → one more unit, or ⇒ ledger if it adds a mechanism     │
│ handoff + Lessons → state.md; progress line                               │
└───────────────────────────────────────────────────────────────────────────┘
        ▼   (next milestone → back to 4)
┌─ 6 PRODUCTION ────────────────────────────────────────────────────────────┐
│ prod: human (default) ⇒ ledger: summary, risk, exact deploy command       │
│ [if prod: auto] only for named risk classes; never PROVISIONAL pieces     │
└───────────────────────────────────────────────────────────────────────────┘
        ▼
┌─ 7 RUN END ───────────────────────────────────────────────────────────────┐
│ [if merge: human] merge main into integration branch (conflict = unit),   │
│                   DoD again, open ONE PR to main ⇒ ledger                 │
│ follow-ups: do now / ledger / drop (with reason)                          │
│ check out branch with all delivered work; phase: finished                 │
└───────────────────────────────────────────────────────────────────────────┘
        ▼
 8 FINAL MESSAGE: Waiting on you · PROVISIONAL decisions · unit statuses · Delivered

Always, at every step:
  • never ask the operator mid-run — ledger is the only channel
  • operator-only (irreversible, prod, money, client-facing, data deletion,
    security exception) ⇒ ledger; [if operator approved it] do exactly that
  • never break a contract silently → ship additively (new field/version)
  • never edit/weaken/skip a frozen check, script, or test
  • every unit start: re-read state.md (+ Lessons); SKILL.md at milestone start
    and after compaction; never stop for context

Files: .run-plan/state.md  = phase, units, hashes, Delivered, Progress, handoffs, Lessons
       .run-plan/ledger.md = Waiting on you · Decided · Follow-ups · Delivered
```
