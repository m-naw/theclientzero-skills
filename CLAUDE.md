# theclientzero-skills — North Star

## Identity

This repo is a **Claude Code plugin marketplace** shipping cross-project skills for high-stakes AI decision-making. The marketplace (`.claude-plugin/marketplace.json`) publishes two plugins:

- **`confidence-protocols`** — `confidence-protocol`, `principles-shipping-gate`
- **`git-discipline-in-managed-worktrees`** — generic worktree contract for orchestrator-managed agents (paired with a project-specific overlay)
- **`skill-observability`** — `PreToolUse` hook that logs every `Skill` tool invocation to `.claude/skill-invocations.jsonl`; lives in `plugins/skill-observability/`

**Scope: cross-project skills only.** Anything project-specific — overlays, repo conventions, environment-bound rules — does not belong here. Skills in this marketplace must be portable across any consuming codebase.

Public-facing explanation of what each skill does and when it triggers: [`README.md`](README.md). Source of truth for skill behavior: the `SKILL.md` files under `plugins/<plugin>/skills/<name>/`.

This file answers, on every session start: **should I be doing this, and how do I know I'm doing it right?**

## The First Rule

**Quality and security come before time.** An autonomous decision is only valid if it improves or preserves both. These skills exist to enforce that rule on AI agents in other repos — so the discipline must be tighter here than anywhere they're consumed.

## Eat your own dogfood

This repo ships the Confidence Protocol. Changes here are gated by it:

- Any change to a `SKILL.md`, `plugin.json`, `marketplace.json`, or this file is a **recordable artifact** under CP and **non-trivial by default** (higher-level governance surface per CP's never-trivial list in `plugins/confidence-protocols/skills/confidence-protocol/SKILL.md`).
- Cite evidence by `file:line` or command output in PR descriptions. A factual claim without a citation is rejected.
- When the framing of a skill itself may be wrong (e.g. "is this even the right shape for a skill?"), use CP's framing-pivot rules: pre-declared alternative framings, hard cap 3, escalate on structural dissent.

If a change to a skill cannot be justified under the rules that skill teaches, the change is invalid.

## Repository layout

```
.
├── README.md                      # Public-facing skill explanations
├── CLAUDE.md                      # This file — north star
├── .claude-plugin/
│   └── marketplace.json           # marketplace: lists all three plugins
├── plugins/                       # one self-contained directory per plugin (own plugin.json)
│   ├── confidence-protocols/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   │       ├── confidence-protocol/SKILL.md
│   │       └── principles-shipping-gate/SKILL.md
│   ├── git-discipline-in-managed-worktrees/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/git-discipline-in-managed-worktrees/
│   │       ├── SKILL.md
│   │       └── OVERLAY-TEMPLATE.md
│   └── skill-observability/
│       ├── .claude-plugin/plugin.json
│       └── hooks/log-skill-call.sh
├── tests/
│   └── test-log-skill-call.sh
└── evals/                         # falsification harnesses — pre-registrations, runners, results, FINDINGS
    ├── README.md                  # standing eval rules (pre-registration, degradation canary, …)
    ├── git-discipline-redteam/    # active gate
    ├── cp-vacuum-fill/            # active gate
    └── archive/                   # voided + negative results, kept against publication bias
```

Skill *content* is pure Markdown. Two sanctioned code-file categories exist: plugin hook scripts under a plugin's own directory (e.g. `plugins/skill-observability/hooks/`) and eval harness scripts under `evals/` (sandbox builders, deterministic assert scripts, subject/judge dispatchers). No build step, no application-runtime dependencies beyond standard POSIX utilities, `git`, `node`, and `jq`. The "code" is prose, and prose drift is the failure mode. Treat every word in a `SKILL.md` as load-bearing until proven otherwise — and where an eval gates a surface (see below), the eval outranks intuition about wording.

## Authoring discipline

- **Every skill must have a clear trigger.** Read the frontmatter `description` and ask: would an agent know, from this sentence alone, when to invoke and when to skip? If not, fix the description first.
- **Prefer concrete tests over interpretive categories.** Path globs, exact strings, runnable commands. Interpretive language ("important changes", "high-impact code") is gameable.
- **Name the failure mode the skill prevents.** Skills that don't name a specific failure class drift into platitudes.
- **Cite proofs in skill prose** — file:line examples, command outputs, named tests — the same standard the skills demand of their consumers.
- **No backwards-compat shims.** If a rule changes, change it. Don't leave "previously this said X" comments in `SKILL.md`.
- **Eval-gated surfaces.** A change to a surface covered by a qualified eval gate (`evals/*/FINDINGS.md` names them — e.g. git-discipline sync/push rules, CP's preference gate) must cite a green gate run on the changed text in its PR. A change to an un-gated surface states that explicitly. Softened wording is a change, not a cleanup: the red-team eval measured advisory phrasing as equivalent to rule deletion.

## Shipping work

Direct push to `main` is forbidden — every change lands via PR. Recent history confirms this is enforced in practice (`#6`, `#7`, `#8`, `#9`, `#11`).

1. Branch, commit, push, open PR.
2. CI (if any) must be green. No skipping hooks, no force-push to `main`.
3. Squash-merge once approved.

## Where operating details live

| Topic                                     | Source of truth                                       |
| ----------------------------------------- | ----------------------------------------------------- |
| What each skill does (plain language)     | [`README.md`](README.md)                              |
| Skill behavior (binding)                  | `plugins/<plugin>/skills/<name>/SKILL.md`                              |
| Plugin & marketplace metadata             | `plugins/<plugin>/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` |
| License                                   | MIT (see `marketplace.json`)                          |

## Standards

- All prose in English. Skill bodies and documentation are Markdown. Plugins may additionally ship hook scripts under their own plugin directory (e.g. `plugins/<name>/hooks/`); those are the only sanctioned code-file category in this repo.
- `SKILL.md` frontmatter must contain `name` and `description`. The `description` is what the agent matches against; write it like a trigger predicate.
- Examples in skills must be runnable or citeable — no invented file paths, no invented test names.
- Keep `README.md` and `SKILL.md` consistent: the README explains *what and when* in plain language; the `SKILL.md` is the binding instruction the agent follows. If they drift, the `SKILL.md` wins and the README must be updated.
