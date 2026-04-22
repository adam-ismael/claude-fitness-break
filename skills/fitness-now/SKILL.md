---
description: Trigger a new claude-fitness-break exercise immediately, bypassing the cooldown. Use only when the user explicitly invokes this skill.
disable-model-invocation: true
allowed-tools: Bash(bash *)
---

!`bash "${CLAUDE_PLUGIN_ROOT}/hooks/fitness-break.sh" --now`

Show the exercise from the script output above. Tell the user the full roast is generating in the background and will appear in the status bar within a few seconds.
