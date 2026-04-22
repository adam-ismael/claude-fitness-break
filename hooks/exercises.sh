#!/bin/bash
# Manage the user's exercise list for claude-fitness-break.
# Usage: exercises.sh [list|add <exercise>|edit <number> <exercise>|remove <number>|clear|reset|path]
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DATA_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/data/claude-fitness-break"
EXERCISES_FILE="$DATA_DIR/exercises.txt"
DEFAULT_EXERCISES="$PLUGIN_ROOT/defaults/exercises.txt"

mkdir -p "$DATA_DIR"

seed_exercises() {
  if [[ ! -f "$EXERCISES_FILE" && -f "$DEFAULT_EXERCISES" ]]; then
    cp "$DEFAULT_EXERCISES" "$EXERCISES_FILE"
  fi
}

trim() {
  echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

list_exercises() {
  seed_exercises
  if [[ ! -s "$EXERCISES_FILE" ]]; then
    echo "No exercises configured."
    return
  fi

  nl -ba "$EXERCISES_FILE" | sed 's/^[[:space:]]*/  /'
}

cmd="${1:-list}"
shift || true

case "$cmd" in
  list|"")
    list_exercises
    ;;
  add)
    exercise=$(trim "$*")
    if [[ -z "$exercise" ]]; then
      echo "error: provide an exercise to add" >&2
      exit 1
    fi
    seed_exercises
    printf '%s\n' "$exercise" >> "$EXERCISES_FILE"
    echo "Added exercise: $exercise"
    ;;
  edit)
    seed_exercises
    index="${1:-}"
    shift || true
    exercise=$(trim "$*")
    if [[ ! "$index" =~ ^[0-9]+$ ]]; then
      echo "error: provide the exercise number to edit" >&2
      exit 1
    fi
    if [[ -z "$exercise" ]]; then
      echo "error: provide the replacement exercise" >&2
      exit 1
    fi
    total=$(grep -cve '^[[:space:]]*$' "$EXERCISES_FILE" || true)
    if (( index < 1 || index > total )); then
      echo "error: exercise number must be between 1 and $total" >&2
      exit 1
    fi
    old=$(sed -n "${index}p" "$EXERCISES_FILE")
    tmp=$(mktemp)
    awk -v idx="$index" -v repl="$exercise" 'NR == idx {$0 = repl} {print}' "$EXERCISES_FILE" > "$tmp"
    mv "$tmp" "$EXERCISES_FILE"
    echo "Updated exercise $index: $old -> $exercise"
    ;;
  remove|delete|rm)
    seed_exercises
    index="${1:-}"
    if [[ ! "$index" =~ ^[0-9]+$ ]]; then
      echo "error: provide the exercise number to remove" >&2
      exit 1
    fi
    total=$(grep -cve '^[[:space:]]*$' "$EXERCISES_FILE" || true)
    if (( index < 1 || index > total )); then
      echo "error: exercise number must be between 1 and $total" >&2
      exit 1
    fi
    removed=$(sed -n "${index}p" "$EXERCISES_FILE")
    tmp=$(mktemp)
    sed "${index}d" "$EXERCISES_FILE" > "$tmp"
    mv "$tmp" "$EXERCISES_FILE"
    echo "Removed exercise: $removed"
    ;;
  clear)
    : > "$EXERCISES_FILE"
    echo "Cleared all custom exercises. Add one with: /fitness-exercises add <exercise>"
    ;;
  reset)
    if [[ ! -f "$DEFAULT_EXERCISES" ]]; then
      echo "error: default exercises file is missing" >&2
      exit 1
    fi
    cp "$DEFAULT_EXERCISES" "$EXERCISES_FILE"
    echo "Reset exercises to plugin defaults."
    ;;
  path)
    seed_exercises
    echo "$EXERCISES_FILE"
    ;;
  *)
    echo "error: unknown action '$cmd'" >&2
    echo "Usage: /fitness-exercises [list|add <exercise>|edit <number> <exercise>|remove <number>|clear|reset|path]" >&2
    exit 1
    ;;
esac
