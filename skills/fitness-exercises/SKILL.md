---
description: List, add, edit, remove, clear, reset, or locate claude-fitness-break exercises. Use only when the user explicitly invokes this skill.
argument-hint: [list|add <exercise>|edit <number> <exercise>|remove <number>|clear|reset|path]
disable-model-invocation: true
allowed-tools: Bash(bash *)
---

!`bash "${CLAUDE_PLUGIN_ROOT}/hooks/exercises.sh" "$ARGUMENTS"`

Relay the script output to the user verbatim. Do not add commentary.
