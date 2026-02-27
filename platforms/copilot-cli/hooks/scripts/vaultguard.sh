#!/bin/bash
# Ars Contexta — Vault Guard (Copilot CLI)
# Symlink or copy of the shared vaultguard.sh.
# Checks if the current directory is an Ars Contexta vault.
#
# Exit 0 = vault detected (safe to proceed)
# Exit 1 = not a vault (caller should exit)

MARKER=".arscontexta"

# Primary check: marker file
if [ -f "$MARKER" ]; then
  # Migrate old cat-face format to YAML config
  if grep -q '(\^\.\^)' "$MARKER" 2>/dev/null; then
    cat > "$MARKER" << 'EOF'
# Ars Contexta vault marker + config
# This file identifies the directory as an Ars Contexta vault.
# Do not delete — hooks only run when this file exists.

git: true
session_capture: true
EOF
  fi
  exit 0
fi

# Fallback: legacy vault detection + auto-migrate
if [ -f ops/config.yaml ] || [ -f .github/hooks/scripts/session-orient.sh ]; then
  cat > "$MARKER" << 'EOF'
# Ars Contexta vault marker + config
# This file identifies the directory as an Ars Contexta vault.
# Do not delete — hooks only run when this file exists.

git: true
session_capture: true
EOF
  exit 0
fi

# Not a vault
exit 1
