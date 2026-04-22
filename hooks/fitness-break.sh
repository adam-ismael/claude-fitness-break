#!/bin/bash
# Fires on SubagentStart and legacy PreToolUse(Task|Agent). Picks a random exercise + personality,
# writes a fallback line, fires claude-haiku in the background for a roast.
force=0
print_after=0
if [[ "${1:-}" == "--force" ]]; then
  force=1
elif [[ "${1:-}" == "--now" ]]; then
  force=1
  print_after=1
fi

if [[ "$print_after" -eq 0 ]]; then
  input=$(cat)
else
  input="{}"
fi

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DATA_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/data/claude-fitness-break"
mkdir -p "$DATA_DIR"

LOCK="$DATA_DIR/gen"           # random generation ID (stale-Haiku guard)
COOLDOWN="$DATA_DIR/cooldown"  # unix timestamp for 5-min cooldown
EXERCISE_FILE="$DATA_DIR/exercise"
PIN_FILE="$DATA_DIR/personality"
EXERCISES_FILE="$DATA_DIR/exercises.txt"
DEFAULT_EXERCISES="$PLUGIN_ROOT/defaults/exercises.txt"

load_exercises() {
  local source_file="$1"
  local line

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    exercises+=("$line")
  done < "$source_file"
}

# 5-minute cooldown
if [[ "$force" -eq 0 && -f "$COOLDOWN" ]]; then
  last=$(cat "$COOLDOWN")
  now=$(date +%s)
  if (( now - last < 300 )); then
    echo "{}"
    exit 0
  fi
fi
date +%s > "$COOLDOWN"

# Random generation ID — stale background Haiku jobs check this before writing.
GEN="$RANDOM$RANDOM"
echo "$GEN" > "$LOCK"

if [[ ! -f "$EXERCISES_FILE" && -f "$DEFAULT_EXERCISES" ]]; then
  cp "$DEFAULT_EXERCISES" "$EXERCISES_FILE"
fi

exercises=()
if [[ -f "$EXERCISES_FILE" ]]; then
  load_exercises "$EXERCISES_FILE"
fi
if (( ${#exercises[@]} == 0 )) && [[ ! -f "$EXERCISES_FILE" && -f "$DEFAULT_EXERCISES" ]]; then
  load_exercises "$DEFAULT_EXERCISES"
fi
if (( ${#exercises[@]} == 0 )); then
  echo "{}"
  exit 0
fi
pick="${exercises[$RANDOM % ${#exercises[@]}]}"

# Resolve personality: pinned key, or random across available files.
personality=""
if [[ -f "$PIN_FILE" ]]; then
  pinned=$(tr -d '[:space:]' < "$PIN_FILE")
  if [[ -n "$pinned" && "$pinned" != "random" && -f "$PLUGIN_ROOT/personalities/$pinned.txt" ]]; then
    personality="$pinned"
  fi
fi
if [[ -z "$personality" ]]; then
  shopt -s nullglob
  files=("$PLUGIN_ROOT"/personalities/*.txt)
  shopt -u nullglob
  if (( ${#files[@]} == 0 )); then
    echo "{}"
    exit 0
  fi
  chosen="${files[$RANDOM % ${#files[@]}]}"
  personality=$(basename "$chosen" .txt)
fi

pfile="$PLUGIN_ROOT/personalities/$personality.txt"
header=$(head -n1 "$pfile")
emoji="${header%%|*}"
prompt_tpl=$(tail -n +2 "$pfile")
prompt="${prompt_tpl//\$EXERCISE/$pick}"

# Immediate fallback
printf '%s Drop and do %s.' "$emoji" "$pick" > "$EXERCISE_FILE"

# Background Haiku roast — check generation ID before writing so a stale
# job from a previous /fitness-now call doesn't overwrite the current one.
CLAUDE_BIN=$(which claude 2>/dev/null)
if [[ -n "$CLAUDE_BIN" ]]; then
  nohup bash -c "
    msg=\$(\"$CLAUDE_BIN\" -p --model claude-haiku-4-5-20251001 \"$prompt\" 2>/dev/null | tr -d '\n' | sed 's/^ *//;s/ *\$//')
    if [[ -n \"\$msg\" && \"\$(cat '$LOCK' 2>/dev/null)\" == '$GEN' ]]; then
      printf '%s %s' \"$emoji\" \"\$msg\" > \"$EXERCISE_FILE\"
    fi
  " >/dev/null 2>&1 &
  disown
fi

if [[ "$print_after" -eq 1 ]]; then
  sleep 0.3
  cat "$EXERCISE_FILE"
else
  echo "{}"
fi
