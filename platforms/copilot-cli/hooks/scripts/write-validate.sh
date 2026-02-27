#!/bin/bash
# Ars Contexta — Schema Enforcement Hook (Copilot CLI — postToolUse)
# Logs schema violations for notes in the knowledge space.
#
# NOTE: Copilot CLI ignores postToolUse output. This hook logs warnings
# but cannot inject them into the conversation. For enforcement that the
# agent can see, use validate-pretool.sh with preToolUse instead.

# Only run in Ars Contexta vaults
GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
if ! "$GUARD_DIR/vaultguard.sh"; then
  cat > /dev/null
  exit 0
fi

# Read JSON from stdin (Copilot provides {timestamp, cwd, toolName, toolArgs, toolResult})
INPUT=$(cat)

# Extract tool name and file path
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty')
  TOOL_ARGS=$(echo "$INPUT" | jq -r '.toolArgs // empty')
  FILE=$(echo "$TOOL_ARGS" | jq -r '.path // .file_path // empty' 2>/dev/null)
  [ -z "$FILE" ] && FILE=$(echo "$TOOL_ARGS" | jq -r '. | fromjson? | .path // .file_path // empty' 2>/dev/null)
else
  TOOL_NAME=$(echo "$INPUT" | grep -o '"toolName":"[^"]*"' | head -1 | sed 's/"toolName":"//;s/"//')
  # toolArgs is stringified JSON with escaped quotes — unescape before parsing
  TOOL_ARGS_RAW=$(echo "$INPUT" | sed 's/.*"toolArgs":"//;s/"[,}].*//' | sed 's/\\"/"/g; s/\\\\/ /g')
  FILE=$(echo "$TOOL_ARGS_RAW" | grep -o '"path":"[^"]*"' | head -1 | sed 's/"path":"//;s/"//')
  [ -z "$FILE" ] && FILE=$(echo "$TOOL_ARGS_RAW" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"//')
fi

# Only validate edit/create on notes
case "$TOOL_NAME" in
  edit|create) ;;
  *) exit 0 ;;
esac

[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

# Only validate notes in the knowledge space
case "$FILE" in
  */notes/*|*thinking/*)
    WARNS=""
    if ! head -20 "$FILE" | grep -q "^description:"; then
      WARNS="${WARNS}Missing description field. "
    fi
    if ! head -20 "$FILE" | grep -q "^topics:"; then
      WARNS="${WARNS}Missing topics field. "
    fi
    if ! head -1 "$FILE" | grep -q "^---$"; then
      WARNS="${WARNS}Missing YAML frontmatter. "
    fi
    if [ -n "$WARNS" ]; then
      FILENAME=$(basename "$FILE" .md)
      # Log to stderr (visible in debug mode) since stdout is ignored
      echo "Schema warning for $FILENAME: $WARNS" >&2
    fi
    ;;
esac

exit 0
