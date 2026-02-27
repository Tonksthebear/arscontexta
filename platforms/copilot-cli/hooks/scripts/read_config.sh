#!/bin/bash
# Ars Contexta — Config Reader (Copilot CLI)
# Reads values from .arscontexta vault marker (which doubles as config).
# Usage: read_config.sh <key> [default]

KEY="$1"
DEFAULT="${2:-true}"

if [ -z "$KEY" ]; then
  echo "$DEFAULT"
  exit 0
fi

PROJECT_DIR="$(pwd)"
CONFIG_FILE="$PROJECT_DIR/.arscontexta"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "$DEFAULT"
  exit 0
fi

VALUE=$(grep -E "^${KEY}:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^["'"'"']//;s/["'"'"']$//' | sed 's/[[:space:]]*$//')

if [ -z "$VALUE" ]; then
  echo "$DEFAULT"
else
  echo "$VALUE"
fi
