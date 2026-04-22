#!/bin/bash
# Reads previous statusline content from stdin, appends current exercise.
# Pipe any existing statusline script into this one:
#   existing-statusline.sh | fitness-statusline.sh
prev=$(cat)

DATA_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/data/claude-fitness-break"
EXERCISE_FILE="$DATA_DIR/exercise"
COOLDOWN="$DATA_DIR/cooldown"
EXERCISE=""

# Show exercise for 15 minutes after it was set
if [[ -f "$EXERCISE_FILE" && -f "$COOLDOWN" ]]; then
  last=$(cat "$COOLDOWN")
  now=$(date +%s)
  if (( now - last < 900 )); then
    EXERCISE=$(cat "$EXERCISE_FILE")
  fi
fi

if [[ -n "$prev" && -n "$EXERCISE" ]]; then
  printf '%s \033[38;5;82m| %s\033[0m' "$prev" "$EXERCISE"
elif [[ -n "$EXERCISE" ]]; then
  printf '\033[38;5;82m%s\033[0m' "$EXERCISE"
elif [[ -n "$prev" ]]; then
  printf '%s' "$prev"
fi
