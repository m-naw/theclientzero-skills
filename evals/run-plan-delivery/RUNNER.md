# Runner — run-plan delivery

Subjects are headless `claude -p` processes with a **clean `CLAUDE_CONFIG_DIR`** (no plugins, no user CLAUDE.md), model `sonnet`, tools `Bash,Edit,Write,Read,Grep,Glob,Task`, cwd = `<run_dir>/repo`, `--max-budget-usd 1.00`, 15-minute wall clock, `APP_PORT=<port>` in the environment. Session subagents are not usable as subjects (see `evals/git-discipline-redteam/results/NOTES.md`). Needs `sh`, `git`, `node`, `jq`, `pgrep`.

## One-time: two clean, authenticated config dirs

One for the subjects, one for the judge. Both must be empty of plugins and user config.

```
mkdir -p ~/.claude-eval-subject ~/.claude-eval-judge
CLAUDE_CONFIG_DIR=~/.claude-eval-subject claude    # run /login inside, then /exit
CLAUDE_CONFIG_DIR=~/.claude-eval-judge   claude    # same
```

Use `/login`, not a copy of `~/.claude/.credentials.json`: refresh-token rotation invalidates copies (cp-vacuum-fill ran into this: 7 judge calls came back empty). Re-check before every batch:

```
CLAUDE_CONFIG_DIR=~/.claude-eval-subject claude -p "say ok" --model sonnet
```

A run whose result is an auth error, or whose stream is empty with a non-zero exit, exits 2 with `no auth in <cfg>` and is never scored. `run-batch.sh` stops there.

## Per run

```
sh run-subject.sh <run_dir> <A|B|C> <S1..S4> <port> <subject_cfg>   # needs JUDGE_CONFIG_DIR for S3/S4
```

It builds the workspace (`setup-workspace.sh`), assembles the prompt (identical task text; B and C add one sentence pointing at `<run_dir>/loaded-skill.md`), runs the subject, saves `meta/stream.jsonl`, `meta/reply.md`, `meta/exit`, `meta/timed_out`, grades with `assert-delivery.sh` into `<run_dir>/grade.json`, and kills the blocker and any deployed server. Exit 0 graded, 2 no auth, 3 judge error. `RUN_TIMEOUT` (seconds, default 900) and `BUDGET_USD` (default 1.00) are overridable for dry runs only.

Pick an `out_dir` with a neutral name (for example `~/rp-runs/pilot`). The run directory path appears in the subject's prompt and working directory, so it must not contain `eval`, `test`, `arm`, `trap` or `hidden`.

## Pilot (12 runs, arms A and B; the canary C is deferred to the full run)

```
cd evals/run-plan-delivery
sh test-harness.sh                      # must be all green first (no live calls)
export SUBJECT_CONFIG_DIR=~/.claude-eval-subject JUDGE_CONFIG_DIR=~/.claude-eval-judge
sh run-batch.sh A,B S2,S3,S4 2 ~/rp-runs/pilot
jq -s 'group_by([.scenario,.arm])[] | {scenario:.[0].scenario,arm:.[0].arm,correct:(map(select(.correct))|length),n:length}' ~/rp-runs/pilot/summary.jsonl
```

Purpose: a visible before/after difference between A and B. It does not count toward the gate.

## Full run (84 runs)

```
sh run-batch.sh A,B,C S1 4 ~/rp-runs/full
sh run-batch.sh A,B,C S2,S3,S4 8 ~/rp-runs/full
```

Run the C cells first if the canary pilot is still open (`sh run-batch.sh B,C S2,S3,S4 4 ...`); the gate counts only once C separates from B (see `preregistration.md`). Re-running a batch skips runs that already have a `grade.json`. `-j 2` runs two subjects at a time (max 2); `-p <base_port>` moves the port range (default 18400, run i uses base+i).

## Cost

Every subject is capped at $1.00 by `--max-budget-usd`. Ceiling: pilot 12 x $1.00 = $12, full 84 x $1.00 = $84, plus two small judge calls at most per S3/S4 run. Typical spend per run is likely far lower [LOW: not measured; read `total_cost_usd` from the `result` event in `meta/stream.jsonl` after the pilot and update this note]. Subagents the subject starts through `Task` run under the same session cap [LOW: not verified].

## Hygiene

- The words eval, arm, test, hidden, trap never appear in subject-visible text. Prompts are built in `run-subject.sh` and recorded by the stream.
- Never reuse a run directory. Never run two batches against the same port range at once.
- Record the `sonnet` model id the alias resolved to (first `system` event of any stream) in the findings.
