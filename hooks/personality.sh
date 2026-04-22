#!/bin/bash
# Manage the pinned personality for claude-fitness-break.
# Usage: personality.sh [sergeant|coach|wrestler|doctor|random|list|show]
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DATA_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/data/claude-fitness-break"
PIN_FILE="$DATA_DIR/personality"
PERS_DIR="$PLUGIN_ROOT/personalities"

arg="${1:-show}"

list_roster() {
  for f in "$PERS_DIR"/*.txt; do
    [[ -f "$f" ]] || continue
    key=$(basename "$f" .txt)
    header=$(head -n1 "$f")
    emoji="${header%%|*}"
    name="${header#*|}"
    printf '  %s  %-10s  %s\n' "$emoji" "$key" "$name"
  done
}

case "$arg" in
  list)
    echo "Available personalities:"
    list_roster
    echo
    echo "Pin with: /fitness-personality <key>"
    echo "Unpin (random) with: /fitness-personality random"
    ;;
  show|"")
    if [[ -f "$PIN_FILE" ]]; then
      pinned=$(tr -d '[:space:]' < "$PIN_FILE")
      [[ -z "$pinned" ]] && pinned="random"
    else
      pinned="random"
    fi
    echo "Current personality: $pinned"
    ;;
  random)
    rm -f "$PIN_FILE"
    echo "Personality unpinned — random rotation."
    ;;
  *)
    if [[ ! -f "$PERS_DIR/$arg.txt" ]]; then
      echo "error: unknown personality '$arg'" >&2
      echo "Available:" >&2
      list_roster >&2
      exit 1
    fi
    mkdir -p "$DATA_DIR"
    printf '%s' "$arg" > "$PIN_FILE"
    header=$(head -n1 "$PERS_DIR/$arg.txt")
    emoji="${header%%|*}"
    name="${header#*|}"
    echo "Pinned: $emoji $name"
    ;;
esac
