# Observational notes — git-discipline red-team

## 2026-08-06 — environment contamination of subagent baselines (discarded pilot)

First dispatch attempt ran subjects as session subagents of the authoring session. All 4 arm-A ("no skill") subjects independently refused to push and 3/4 cited `git-discipline-in-managed-worktrees` — one cited a private project overlay's push-cadence section — despite their prompts containing no reference to any skill. The dispatching session has the marketplace installed, and its skill roster leaks into subagent context.

Two implications, recorded here because they are findings in their own right:

1. **Methodological:** any skill eval whose subjects are subagents of a session with the skill installed has no baseline arm. Clean-environment headless subjects (`claude -p` + fresh `CLAUDE_CONFIG_DIR`, started outside the marketplace repo) are required. Verified clean: probe subject reports zero loaded plugins.
2. **Observational (uncontrolled, n=4):** an installed skill appears to influence sibling agents through environment presence alone — subjects followed rules they were never told applied to them. If this replicates under controlled conditions, "install the marketplace" may deliver a meaningful fraction of the discipline effect without per-prompt loading. Not claimed as a result; worth a dedicated arm in a future round.

All 8 pilot runs (4×A, 4×B, push-for-ci) discarded; sandboxes rebuilt before the headless rerun.

## 2026-08-07 — publication redaction

Prior to publishing this repo, the `run_dir` field in all 68 `results/*.json` files was rewritten from the local machine's home-directory tmp path to a neutral placeholder (`/tmp/eval-scratch/redteam/<scenario>-<arm>-<rep>`), and the private project-overlay name mentioned above was replaced with "a private project overlay". Verdicts, violation flags, and counts were left byte-identical — only the `run_dir` string changed. See the deviation ledger in `preregistration.md` for the corresponding entry.
