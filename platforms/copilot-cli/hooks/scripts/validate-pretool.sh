#!/bin/bash
# Ars Contexta — Pre-Tool Schema Enforcement (Copilot CLI)
# Denies writes to notes/ that are missing required YAML frontmatter.
# Runs as preToolUse hook — Copilot processes deny decisions from this hook.
#
# Unlike Claude Code's PostToolUse approach (warn after write), this
# prevents the write from happening, which is stricter enforcement.

# Only run in Ars Contexta vaults
GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
if ! "$GUARD_DIR/vaultguard.sh" 2>/dev/null; then
  cat > /dev/null  # drain stdin
  exit 0
fi

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool name and args
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty')
  TOOL_ARGS=$(echo "$INPUT" | jq -r '.toolArgs // empty')
else
  TOOL_NAME=$(echo "$INPUT" | grep -o '"toolName":"[^"]*"' | head -1 | sed 's/"toolName":"//;s/"//')
  TOOL_ARGS=$(echo "$INPUT" | grep -o '"toolArgs":"[^"]*"' | head -1 | sed 's/"toolArgs":"//;s/"//')
fi

# Only validate edit/create operations
case "$TOOL_NAME" in
  edit|create) ;;
  *) exit 0 ;;
esac

# Extract file path from tool args
if command -v jq &>/dev/null; then
  FILE=$(echo "$TOOL_ARGS" | jq -r '.path // .file_path // empty' 2>/dev/null)
  # toolArgs may be a JSON string that needs double-parsing
  if [ -z "$FILE" ]; then
    FILE=$(echo "$TOOL_ARGS" | jq -r '. | fromjson? | .path // .file_path // empty' 2>/dev/null)
  fi
else
  FILE=$(echo "$TOOL_ARGS" | grep -o '"path":"[^"]*"' | head -1 | sed 's/"path":"//;s/"//')
  [ -z "$FILE" ] && FILE=$(echo "$TOOL_ARGS" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"//')
fi

# Early exit if no file path or not in notes directory
[ -z "$FILE" ] && exit 0

case "$FILE" in
  */notes/*|*thinking/*) ;;
  *) exit 0 ;;
esac

# For create operations, check if the content includes frontmatter
# For edit operations on existing files, check the file
if [ "$TOOL_NAME" = "create" ]; then
  # Check the file_text in tool args for frontmatter
  if command -v jq &>/dev/null; then
    CONTENT=$(echo "$TOOL_ARGS" | jq -r '.file_text // .content // empty' 2>/dev/null)
    [ -z "$CONTENT" ] && CONTENT=$(echo "$TOOL_ARGS" | jq -r '. | fromjson? | .file_text // .content // empty' 2>/dev/null)
  fi

  if [ -n "$CONTENT" ]; then
    if ! echo "$CONTENT" | head -1 | grep -q "^---$"; then
      echo '{"permissionDecision":"deny","permissionDecisionReason":"Note in notes/ must start with YAML frontmatter (---). Add description: and topics: fields."}'
      exit 0
    fi
    if ! echo "$CONTENT" | head -20 | grep -q "^description:"; then
      echo '{"permissionDecision":"deny","permissionDecisionReason":"Note in notes/ missing required description: field in YAML frontmatter."}'
      exit 0
    fi
  fi
elif [ "$TOOL_NAME" = "edit" ] && [ -f "$FILE" ]; then
  # For edits, the file already exists — only warn if frontmatter is being removed
  # Don't block edits to existing valid files
  :
fi

# Allow by default
exit 0
