#!/bin/bash
# Ars Contexta — Session Orientation Hook (Copilot CLI)
# Handles session tracking (capture to ops/sessions/).
#
# NOTE: In Copilot CLI, sessionStart hook stdout is IGNORED.
# Context injection is handled by the session-orient SKILL instead.
# This hook only performs the side-effect work: session file management and git commits.

# Only run in Ars Contexta vaults
GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
"$GUARD_DIR/vaultguard.sh" || exit 0

# Read JSON input from stdin (Copilot provides {timestamp, cwd, source, initialPrompt})
INPUT=$(cat)

SESSION_ID=""
if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.timestamp // empty')
else
  SESSION_ID=$(echo "$INPUT" | grep -o '"timestamp":[0-9]*' | head -1 | sed 's/"timestamp"://')
fi

# Use timestamp as session identifier (Copilot doesn't provide session_id)
[ -z "$SESSION_ID" ] && SESSION_ID=$(date -u +"%Y%m%d-%H%M%S")

READ_CONFIG="$GUARD_DIR/read_config.sh"

if [ -n "$SESSION_ID" ] && [ "$(bash "$READ_CONFIG" "session_capture" "true")" = "true" ]; then
  TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
  mkdir -p ops/sessions

  # Promote previous session if exists
  if [ -f ops/sessions/current.json ]; then
    if command -v jq &>/dev/null; then
      PREV_STARTED=$(jq -r '.started // empty' ops/sessions/current.json)
    else
      PREV_STARTED=$(grep -o '"started":"[^"]*"' ops/sessions/current.json | head -1 | sed 's/"started":"//;s/"//')
    fi

    ARCHIVE_TS="${PREV_STARTED:-$TIMESTAMP}"
    mv ops/sessions/current.json "ops/sessions/${ARCHIVE_TS}.json"
  fi

  # Write current session
  cat > ops/sessions/current.json << EOF
{
  "id": "$SESSION_ID",
  "started": "$TIMESTAMP",
  "status": "active",
  "platform": "copilot-cli"
}
EOF

  # Git commit if enabled
  if [ "$(bash "$READ_CONFIG" "git" "true")" = "true" ] && git rev-parse --is-inside-work-tree &>/dev/null; then
    git add ops/sessions/ 2>/dev/null
    [ -f self/goals.md ] && git add self/goals.md 2>/dev/null
    [ -f ops/goals.md ] && git add ops/goals.md 2>/dev/null
    git commit -m "Session start: ${TIMESTAMP}" --quiet --no-verify 2>/dev/null || true
  fi
fi

exit 0
