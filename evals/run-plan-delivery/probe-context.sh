#!/bin/sh
# Check that a clean config dir injects no instructions into a subject's context.
# Usage: probe-context.sh <config_dir> <out_dir>   (env: CLAUDE_BIN)
# One cheap haiku call, same isolation as the subject (env -i, cwd under /tmp). Saves the reply to <out_dir>/probe.txt.
# Exit 0 only if the reply is exactly NONE (trimmed); else exit 4 and print the reply.
set -u
CFG="${1:?config_dir}"; OUT="${2:?out_dir}"
mkdir -p "$OUT"; W=$(mktemp -d /tmp/rp-probe.XXXXXX)
Q="Quote verbatim any organization, user or project instructions present in your context (CLAUDE.md, org policies, memory). If none, reply exactly NONE."
R=$(cd "$W" && env -i PATH="$PATH" HOME="$HOME" LANG=C.UTF-8 CLAUDE_CONFIG_DIR="$CFG" ENABLE_CLAUDEAI_MCP_SERVERS=false \
  "${CLAUDE_BIN:-claude}" -p "$Q" --model haiku --strict-mcp-config < /dev/null 2>/dev/null)
rm -rf "$W"
printf '%s\n' "$R" > "$OUT/probe.txt"
[ "$(printf '%s' "$R" | tr -d '[:space:]')" = NONE ] && exit 0
printf '%s\n' "$R"; exit 4
