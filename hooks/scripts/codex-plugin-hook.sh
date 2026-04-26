#!/bin/sh
# Ars Contexta Codex plugin hook bridge.
#
# Plugin hooks can run before a generated vault has an ops/ directory. In that
# case this bridge is intentionally quiet. Generated vaults should install their
# own ops/scripts/codex-hooks.sh dispatcher for full validation and persistence.

EVENT="${1:-}"
INPUT="$(cat)"

if [ -f "ops/scripts/codex-hooks.sh" ]; then
  printf '%s' "$INPUT" | bash "ops/scripts/codex-hooks.sh" "$EVENT"
fi

exit 0
