#!/bin/bash
# Ars Contexta — Session Capture Hook (Copilot CLI)
# Persists session state on session end and auto-commits.
# Runs as sessionEnd hook.
#
# Copilot provides: {timestamp, cwd, reason}
# reason is one of: "complete", "error", "abort", "timeout", "user_exit"

# Only run in Ars Contexta vaults
GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
"$GUARD_DIR/vaultguard.sh" || exit 0

# Read JSON input
INPUT=$(cat)

READ_CONFIG="$GUARD_DIR/read_config.sh"

if [ "$(bash "$READ_CONFIG" "session_capture" "true")" != "true" ]; then
  exit 0
fi

# Extract reason
REASON="unknown"
if command -v jq &>/dev/null; then
  REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"')
else
  REASON=$(echo "$INPUT" | grep -o '"reason":"[^"]*"' | head -1 | sed 's/"reason":"//;s/"//')
fi

TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")

# Update session status
if [ -f ops/sessions/current.json ]; then
  if command -v jq &>/dev/null; then
    jq --arg status "ended" --arg reason "$REASON" --arg ended "$TIMESTAMP" \
      '. + {status: $status, reason: $reason, ended: $ended}' \
      ops/sessions/current.json > ops/sessions/current.json.tmp \
      && mv ops/sessions/current.json.tmp ops/sessions/current.json
  else
    # Simple sed fallback — update status field
    sed -i.bak "s/\"active\"/\"ended\"/" ops/sessions/current.json 2>/dev/null
    rm -f ops/sessions/current.json.bak
  fi
fi

# Git commit if enabled
if [ "$(bash "$READ_CONFIG" "git" "true")" = "true" ] && git rev-parse --is-inside-work-tree &>/dev/null; then
  git add -A 2>/dev/null
  if ! git diff --cached --quiet 2>/dev/null; then
    git commit -m "Session end: ${TIMESTAMP} (${REASON})" --quiet --no-verify 2>/dev/null || true
  fi
fi

exit 0
