#!/bin/bash
# Ars Contexta — Auto-Commit Hook (Copilot CLI)
# Commits changes after writes to keep the vault in version control.
# Runs as postToolUse hook.

set -e

# Only run in Ars Contexta vaults
GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
"$GUARD_DIR/vaultguard.sh" || exit 0

# Drain stdin (postToolUse provides input but we don't need it)
cat > /dev/null

# Check config
READ_CONFIG="$GUARD_DIR/read_config.sh"
if [ "$(bash "$READ_CONFIG" "git" "true")" != "true" ]; then
  exit 0
fi

# Only commit if inside a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

# Stage all changes
git add -A 2>/dev/null || exit 0

# Check if there are staged changes
if git diff --cached --quiet 2>/dev/null; then
  exit 0
fi

# Build commit message from changed files
CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null | head -5)
FILE_COUNT=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
STATS=$(git diff --cached --stat 2>/dev/null | tail -1)

if [ "$FILE_COUNT" -eq 1 ]; then
  FILENAME=$(echo "$CHANGED_FILES" | head -1)
  MSG="Auto: $FILENAME"
else
  MSG="Auto: $FILE_COUNT files"
fi

if [ -n "$STATS" ]; then
  MSG="$MSG | $STATS"
fi

git commit -m "$MSG" --no-verify 2>/dev/null || true

exit 0
