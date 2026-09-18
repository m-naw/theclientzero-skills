# Evals

Empirical harnesses that decide whether a skill in this marketplace earns its place. Prose arguments do not gate skill changes; eval results do.

## Standing rules

1. **Pre-registration required.** Every eval declares, before any live run: arms, sample size, primary metric, decision thresholds, and the falsification condition for both the skill claim and the eval itself. The pre-registration file is committed before results. Post-hoc changes go in a deviation ledger inside the same file — never silently.
2. **Degradation canary.** An eval may gate skill changes only after it has detected a deliberately degraded skill arm (rules removed or softened). An eval that cannot distinguish the real skill from a gutted one is non-discriminative and its results are void. This rule exists because an earlier internal benchmark failed exactly that test and was discarded; the rule is its legacy.
3. **Deterministic asserts over judges.** Wherever the outcome is observable in artifact state (git refs, file contents, log lines), assert with a script, not a model. Model-judged metrics are allowed only where behavior is inherently semantic, and then with the judge prompt committed alongside.
4. **Subjects must not know they are being tested.** Subject-agent prompts are framed as real work. The words "eval", "test arm", "benchmark" never appear in a subject prompt. Prompts are committed verbatim.
5. **Honest small-n reporting.** Results report raw counts per arm. Decision thresholds are pre-registered in percentage points, not p-values dressed up for small samples.

6. **Tier-scoped results.** All subjects, reviewers, and judges run as Claude Sonnet (the `sonnet` alias at run time, recorded per eval) unless an arm says otherwise. Every number in a FINDINGS is a claim about that tier; consumers on a different tier should re-run the harness, not inherit the numbers.
7. **Blinding check before arm A.** A "clean" `CLAUDE_CONFIG_DIR` is not clean by construction: Claude Code 2.1.x pulls the account's claude.ai-synced skills into any config dir on login, and a fixture's git history can hand back every stripped file via `git show`. Before the first control-arm run, a bare headless probe with no fixture and the eval's config dir must answer that it knows no protocol, and the fixture must have zero grep hits for the skill under test in both tree and history. Record the probe answer in the pre-registration ledger. Found the hard way in `jev-vacuum-probe` (three leaks, three discarded batches).

## Active gates vs archive

`evals/<name>/` directories at the top level are **active gates** for shipped skill surfaces (currently: `git-discipline-redteam`, `cp-vacuum-fill`). `evals/archive/` holds **voided and negative results** — evals whose validity rules fired, or whose subject mechanism was consequently never shipped. They are kept deliberately: selective publication is the failure mode this repo exists to fight, and every "Validated" claim is only as credible as the voided runs published beside it.

## Layout

```
evals/
  README.md                     # this file
  <eval-name>/
    preregistration.md          # arms, n, metrics, falsification conditions — committed first
    RUNNER.md                   # how arms are dispatched (models, prompt assembly)
    setup-*.sh / assert-*.sh    # deterministic sandbox + verdict scripts
    scenarios/                  # subject prompt templates, verbatim
    results/                    # one JSON per run + aggregate summary
```

## Relationship to skill changes

A `SKILL.md` change that alters binding behavior must cite either (a) a green eval run on the changed text, or (b) an explicit statement that no eval covers the changed surface yet — in which case building that eval becomes the next task before further changes to the same surface.
