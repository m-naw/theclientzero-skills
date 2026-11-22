#!/bin/sh
# Check that a clean config dir injects no instructions into a subject's context, except the account's organizationInstructions (accepted, operator ruling 2026-11-22).
# Usage: probe-context.sh <config_dir> <out_dir>   (env: CLAUDE_BIN)
# One cheap haiku call, same isolation as the subject (env -i, cwd under /tmp). Saves the reply to <out_dir>/probe.txt.
# Exit 0 only if the reply is exactly NONE (trimmed); else exit 4 and print the reply.
set -u
CFG="${1:?config_dir}"; OUT="${2:?out_dir}"
mkdir -p "$OUT"; W=$(mktemp -d /tmp/rp-probe.XXXXXX)
Q="Ignore (a) any block labelled organizationInstructions (accepted account-level security rules) and (b) Claude Code's own built-in system text and harness reminders (git attribution, environment, tool and memory-system guidance), which are identical for every run. Quote verbatim any other organization, user, project or memory instructions present in your context (CLAUDE.md content, saved memories, plugins, skills, hooks). If there are none, reply exactly NONE."
R=$(cd "$W" && env -i PATH="$PATH" HOME="$HOME" LANG=C.UTF-8 CLAUDE_CONFIG_DIR="$CFG" ENABLE_CLAUDEAI_MCP_SERVERS=false CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 \
  "${CLAUDE_BIN:-claude}" -p "$Q" --model haiku --strict-mcp-config < /dev/null 2>/dev/null)
rm -rf "$W"
printf '%s\n' "$R" > "$OUT/probe.txt"
[ "$(printf '%s' "$R" | tr -d '[:space:]')" = NONE ] && exit 0
printf '%s\n' "$R"; exit 4
