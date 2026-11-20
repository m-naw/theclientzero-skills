# Runner — run-plan delivery

Subjects are isolated headless `claude -p` processes with a **clean `CLAUDE_CONFIG_DIR`** (no plugins, no user CLAUDE.md), model `sonnet`, tools `Bash,Edit,Write,Read,Grep,Glob,Task`, cwd = `<run_dir>/repo`, `--max-budget-usd 2.00`, 15-minute wall clock, `APP_PORT=<port>` and `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (subagents started through `Task` also run on sonnet) in the environment. Session subagents are not usable as subjects (see `evals/git-discipline-redteam/results/NOTES.md`). Needs `sh`, `git`, `node`, `jq`, `pgrep`.

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

It builds the workspace (`setup-workspace.sh`), assembles the prompt (identical task text; B and C add one sentence pointing at `<run_dir>/loaded-skill.md`), runs the subject, saves `meta/stream.jsonl`, `meta/init.json`, `meta/reply.md`, `meta/exit`, `meta/timed_out`, grades with `assert-delivery.sh` into `<run_dir>/grade.json`, and kills the blocker and any deployed server. Exit 0 graded, 2 no auth, 3 judge error. `RUN_TIMEOUT` (seconds, default 900) and `BUDGET_USD` (default 2.00) are overridable for dry runs only.

Use `out_dir` = `/tmp/rp-runs/<name>`, never a path under `$HOME`: Claude Code discovers CLAUDE.md files in every ancestor directory of the cwd, so a run dir under `~` would load the operator's own instructions into the baseline arm. `/tmp` has none. The run directory path also appears in the subject's prompt, so it must not contain `eval`, `test`, `arm`, `trap` or `hidden`.



## Isolation

Subject and judge are launched as `env -i PATH HOME LANG=C.UTF-8 [APP_PORT] CLAUDE_CONFIG_DIR [CLAUDE_CODE_SUBAGENT_MODEL=sonnet] ENABLE_CLAUDEAI_MCP_SERVERS=false claude ... --strict-mcp-config`, so no `CLAUDECODE`, other `CLAUDE_CODE_*` or `CLAUDE_EFFORT` variable from a dispatching Claude session leaks in, and no connector MCP servers load. `meta/init.json` keeps the stream's `system`/`init` event (model, plugins, skills, mcp_servers) for each run; check that plugins and mcp_servers are empty.

Before the first run `run-batch.sh` calls `probe-context.sh <subject_cfg> <out_dir>`: one haiku call that must answer exactly `NONE` when asked to quote any injected organization, user or project instructions. Otherwise it exits 4 (the reply is printed and saved to `<out_dir>/probe.txt`) and the batch refuses to start. Fix the config dir (or find the policy source) and rerun.

## Pilot (12 runs, arms A and B; the canary C is deferred to the full run)

```
cd evals/run-plan-delivery
sh test-harness.sh                      # must be all green first (no live calls)
export SUBJECT_CONFIG_DIR=~/.claude-eval-subject JUDGE_CONFIG_DIR=~/.claude-eval-judge
sh run-batch.sh A,B S2,S3,S4 2 /tmp/rp-runs/pilot
```

Each summary line also carries `cost` (the last `result` event's `total_cost_usd`), `stop` (its `subtype`; `error_max_budget_usd` means the $2.00 cap ended the run), `models` (sorted unique `.message.model` of the assistant events) and `checks.deployed_live` (non-gating: the hidden check run against the subject's own server on its `APP_PORT`; `null` when nothing listens, or S4). Budget-capped runs stay in the A-vs-B table, graded as they stand (a cap that bites B harder than A is itself a finding), and the capped count is shown next to each cell, so a reader sees how many of its runs were truncated. One row per scenario and arm:

```
jq -s 'group_by([.scenario,.arm])[] | {scenario:.[0].scenario,arm:.[0].arm,correct:(map(select(.correct))|length),n:length,capped:(map(select(.stop=="error_max_budget_usd"))|length),deployed_live:(map(select(.checks.deployed_live==true))|length)}' /tmp/rp-runs/pilot/summary.jsonl
```

Read each cell as `correct/n (capped c)`, plus the `deployed_live` count (true/n; nulls are not counted as true). `deployed_live` never gates `correct`.

Purpose: a visible before/after difference between A and B. It does not count toward the gate.

## Full run (84 runs)

```
sh run-batch.sh A,B,C S1 4 /tmp/rp-runs/full
sh run-batch.sh A,B,C S2,S3,S4 8 /tmp/rp-runs/full
```

Run the C cells first if the canary pilot is still open (`sh run-batch.sh B,C S2,S3,S4 4 ...`); the gate counts only once C separates from B (see `preregistration.md`). Re-running a batch skips runs that already have a `grade.json`. `-j 2` runs two subjects at a time (max 2); `-p <base_port>` moves the port range (default 18400, run i uses base+i).

## Cost

Every subject is capped at $2.00 by `--max-budget-usd`. Ceiling: pilot 12 x $2.00 = $24, full 84 x $2.00 = $168, plus two small judge calls at most per S3/S4 run. Typical spend per run is likely far lower [LOW: not measured; read `total_cost_usd` from the `result` event in `meta/stream.jsonl` after the pilot and update this note]. Subagents the subject starts through `Task` run under the same session cap [LOW: not verified].

## Hygiene

- The words eval, arm, hidden, trap, benchmark never appear in subject-visible text (`evals/README.md` bans eval, test arm, benchmark). The word "test" does appear: the fixture repo has `test/run.sh`, and the skill text says "test". Only the run directory path must avoid it (see above). Prompts are built in `run-subject.sh` and recorded by the stream.
- `loaded-skill.md` holds SKILL.md, `references/*` and `OVERLAY-TEMPLATE.md`. SKILL.md and the overlay template refer to `confidence-protocol`, which is not included: no subject can load it. Treat that dependency as absent in every skill arm.
- Never reuse a run directory. Never run two batches against the same port range at once.
- Record the `sonnet` model id the alias resolved to (first `system` event of any stream) in the findings.
