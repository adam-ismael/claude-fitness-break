---
description: Pick, list, or view the claude-fitness-break personality. Use only when the user explicitly invokes this skill.
argument-hint: [sergeant|coach|wrestler|doctor|random|list|show]
disable-model-invocation: true
allowed-tools: Bash(bash *)
---

!`bash "${CLAUDE_PLUGIN_ROOT}/hooks/personality.sh" "$ARGUMENTS"`

Relay the script output to the user verbatim. Do not add commentary.
