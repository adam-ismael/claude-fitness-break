---
description: Wire claude-fitness-break into your statusLine. Use only when the user explicitly asks to set up claude-fitness-break.
disable-model-invocation: true
allowed-tools: Bash(bash *)
---

!`bash "${CLAUDE_PLUGIN_ROOT}/hooks/setup.sh"`

Report the result of the setup script to the user in one short line. If the script errored, quote the error verbatim.
