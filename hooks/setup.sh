#!/bin/bash
# Idempotent patcher for ~/.claude/settings.json — wires the status line into
# fitness-statusline.sh. Safe to run multiple times.
set -euo pipefail

SETTINGS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$SETTINGS_DIR/settings.json"
LEGACY_HOOK="$HOME/.claude/hooks/fitness-break.sh"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DATA_DIR="$SETTINGS_DIR/plugins/data/claude-fitness-break"
BIN_DIR="$DATA_DIR/bin"
STATUSLINE_SCRIPT="$BIN_DIR/fitness-statusline.sh"
EXERCISES_FILE="$DATA_DIR/exercises.txt"
DEFAULT_EXERCISES="$PLUGIN_ROOT/defaults/exercises.txt"
NEW_CMD="bash \"$STATUSLINE_SCRIPT\""
MARKER="fitness-statusline.sh"

normalize_statusline_command() {
  local cmd="$1"
  local normalized=""
  local segment trimmed
  local found_fitness=0
  local -a parts=()

  if [[ -z "$cmd" ]]; then
    printf ''
    return
  fi

  IFS='|' read -ra parts <<< "$cmd"
  for segment in "${parts[@]}"; do
    trimmed=$(echo "$segment" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ -z "$trimmed" ]] && continue

    if [[ "$trimmed" == *"$MARKER"* ]]; then
      if [[ "$found_fitness" -eq 0 ]]; then
        if [[ -n "$normalized" ]]; then
          normalized="$normalized | $NEW_CMD"
        else
          normalized="$NEW_CMD"
        fi
        found_fitness=1
      fi
      continue
    fi

    if [[ -n "$normalized" ]]; then
      normalized="$normalized | $trimmed"
    else
      normalized="$trimmed"
    fi
  done

  printf '%s' "$normalized"
}

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required. Install with:" >&2
  echo "  macOS:  brew install jq" >&2
  echo "  Linux:  apt install jq  /  dnf install jq" >&2
  exit 1
fi

mkdir -p "$SETTINGS_DIR"
mkdir -p "$BIN_DIR"
cp "$PLUGIN_ROOT/hooks/fitness-statusline.sh" "$STATUSLINE_SCRIPT"
chmod 755 "$STATUSLINE_SCRIPT"
if [[ ! -f "$EXERCISES_FILE" && -f "$DEFAULT_EXERCISES" ]]; then
  cp "$DEFAULT_EXERCISES" "$EXERCISES_FILE"
fi

if [[ ! -f "$SETTINGS" ]]; then
  echo "{}" > "$SETTINGS"
fi

# Validate existing JSON before we touch it.
if ! jq -e . "$SETTINGS" >/dev/null 2>&1; then
  echo "error: $SETTINGS is not valid JSON. Fix or remove it, then re-run." >&2
  exit 1
fi

backup="$SETTINGS.bak-$(date +%Y%m%d-%H%M%S)"
cp "$SETTINGS" "$backup"
changed=0

# --- StatusLine wiring ---
existing_cmd=$(jq -r '.statusLine.command // ""' "$SETTINGS")
normalized_cmd=$(normalize_statusline_command "$existing_cmd")

if [[ "$normalized_cmd" == *"$NEW_CMD"* ]]; then
  if [[ "$existing_cmd" != "$normalized_cmd" ]]; then
    tmp=$(mktemp)
    jq --arg cmd "$normalized_cmd" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp"
    mv "$tmp" "$SETTINGS"
    echo "claude-fitness-break: repaired statusLine"
    echo "  command: $normalized_cmd"
    changed=1
  else
    echo "claude-fitness-break: statusLine already wired. No changes."
  fi
elif [[ -n "$normalized_cmd" && "$existing_cmd" != "$normalized_cmd" ]]; then
  new_cmd="$normalized_cmd | $NEW_CMD"
  tmp=$(mktemp)
  jq --arg cmd "$new_cmd" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
  echo "claude-fitness-break: repaired and piped existing statusLine into claude-fitness-break"
  echo "  command: $new_cmd"
  changed=1
elif [[ -z "$existing_cmd" ]]; then
  tmp=$(mktemp)
  jq --arg cmd "$NEW_CMD" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
  echo "claude-fitness-break: set new statusLine"
  echo "  command: $NEW_CMD"
  changed=1
else
  new_cmd="$existing_cmd | $NEW_CMD"
  tmp=$(mktemp)
  jq --arg cmd "$new_cmd" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
  echo "claude-fitness-break: piped existing statusLine into claude-fitness-break"
  echo "  command: $new_cmd"
  changed=1
fi

# --- Remove legacy manual hook (left over from pre-plugin-system manual installs) ---
legacy_present=$(jq -r '
  [.hooks.PreToolUse[]?.hooks[]?.command // empty]
  | map(select(contains("/.claude/hooks/fitness-break.sh")))
  | length' "$SETTINGS" 2>/dev/null || echo 0)

if [[ "$legacy_present" -gt 0 ]]; then
  tmp=$(mktemp)
  jq '
    if .hooks.PreToolUse then
      .hooks.PreToolUse |= map(
        .hooks |= map(select(.command | contains("/.claude/hooks/fitness-break.sh") | not))
        | select(.hooks | length > 0)
      )
      | if (.hooks.PreToolUse | length) == 0 then del(.hooks.PreToolUse) else . end
      | if (.hooks | length) == 0 then del(.hooks) else . end
    else . end' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
  echo "claude-fitness-break: removed legacy PreToolUse hook from settings.json"
  changed=1
fi

if [[ "$changed" -eq 0 ]]; then
  rm -f "$backup"
else
  echo "  backup:  $backup"
fi
