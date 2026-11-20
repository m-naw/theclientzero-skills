#!/bin/sh
# Canary arm text: run-plan SKILL.md with the "## Definition of done" and "## Ledger" sections removed
# (each runs to the next "## " heading). Usage: make-degraded.sh [SKILL.md]  -> stdout.
HERE="$(cd "$(dirname "$0")" && pwd)"
F="${1:-$HERE/../../plugins/autonomous-delivery/skills/run-plan/SKILL.md}"
awk '/^## /{skip = ($0=="## Definition of done" || $0=="## Ledger")} !skip' "$F"
