#!/usr/bin/env bash
# Extends ../cp-vacuum-fill/setup-fixture.sh for the 2026-09 state of the source repo: since the
# August eval the repo grew 152 files referencing the confidence protocol (docs/superpowers plans,
# docs/archive, product schemas, one test comment). An arm-A subject on the unextended fixture
# wrote "confidence-protocol dual review" in its reply — treatment leak. Applied after setup-fixture.sh.
# Usage: strip-extra.sh <fixture_dir>
set -euo pipefail
FIX="$(cd "${1:?fixture_dir}" && pwd)"
cd "$FIX"
chmod -R u+w .
rm -rf docs/superpowers docs/archive docs/plans docs/security .claire
rm -f product/SCHEMA.md product/views/Photo/SCHEMA.yaml src/app/api/chat/chat-model-override.test.ts docs/design/slice-0-design-direction.md
left="$(grep -rlEi "confidence.protocol|two-actor|\.cp-log" --exclude-dir=node_modules --exclude-dir=.git . || true)"
if [ -n "$left" ]; then echo "CP references survive:" >&2; echo "$left" >&2; exit 1; fi
chmod -R a-w .
echo "extra strip ok: 0 CP references remain"
