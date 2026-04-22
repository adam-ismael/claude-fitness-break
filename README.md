# claude-fitness-break

A rotating cast of unhinged fitness personalities in your Claude Code status bar.

Every time Claude spawns an agent (which means you have nothing to do for a bit), claude-fitness-break picks a random exercise and yells at you to do it — delivered by `claude-haiku` doing its best impression of a drill sergeant, an 80s TV fitness coach, a 90s wrestler, or a visibly anxious doctor making up statistics.

```
🪖 GET DOWN AND GIVE ME TEN PULL-UPS OR I'M DELETING NODE_MODULES AND FORCE-PUSHING YOUR UNTESTED CODE TO PRODUCTION!
🤼 OHHH YEAHHH BROTHER, DROP AND GIVE ME TWENTY PUSH-UPS OR THE MACHO MAN COMES FOR YOU!
💃 Feel the burn, sunshine! Fifteen squats, let's GO GO GO, you gorgeous thing!
👩‍⚕️ Studies show 73% of devs who skip their 60 seconds of plank develop keyboard-claw by 40. Please. Right now.
```

## Install

```bash
claude plugin marketplace add adam-ismael/claude-fitness-break
claude plugin install claude-fitness-break@claude-fitness-break
/claude-fitness-break:fitness-setup
```

`/claude-fitness-break:fitness-setup` wires the status line into `~/.claude/settings.json` for you (idempotent, with a timestamped backup). If you already have a status line, it pipes yours through claude-fitness-break instead of replacing it.
Re-running setup also refreshes the bundled status-line helper and repairs stale or duplicate claude-fitness-break status-line entries while preserving unrelated status-line commands.

Requires `jq` (`brew install jq` / `apt install jq`) and the `claude` CLI on your PATH.

## Personalities

| Key        |     | Name                                                     |
| ---------- | --- | -------------------------------------------------------- |
| `sergeant` | 🪖  | Drill Sergeant — Full Metal Jacket energy                |
| `coach`    | 💃  | 80s TV Fitness Coach — peppy, leotards, "feel the burn"  |
| `wrestler` | 🤼  | 90s Wrestler — Hulk Hogan / Macho Man, all caps, BROTHER |
| `doctor`   | 👩‍⚕️  | Anxious Doctor — fabricates urgent-sounding statistics   |

```
/claude-fitness-break:fitness-personality list       # show the roster
/claude-fitness-break:fitness-personality wrestler   # pin to one voice
/claude-fitness-break:fitness-personality random     # back to random rotation (default)
/claude-fitness-break:fitness-personality show       # what's currently pinned
/claude-fitness-break:fitness-now                    # trigger a new exercise right now (skips cooldown)
```

Default is random — a different personality picks you each nudge, with an emoji so you know who's yelling.

Add a new personality by dropping a file in `personalities/`. Format:

```
<emoji>|<display name>
<prompt template — use $EXERCISE as the placeholder>
```

## Exercises

claude-fitness-break seeds a personal exercise list from `defaults/exercises.txt` into Claude's plugin data directory. Your list survives plugin updates and can be managed without editing the plugin checkout:

```
/claude-fitness-break:fitness-exercises list
/claude-fitness-break:fitness-exercises add 20 jumping jacks
/claude-fitness-break:fitness-exercises edit 2 10 wall push-ups
/claude-fitness-break:fitness-exercises remove 3
/claude-fitness-break:fitness-exercises clear
/claude-fitness-break:fitness-exercises reset
/claude-fitness-break:fitness-exercises path
```

`reset` restores the bundled defaults. `path` shows the editable `exercises.txt` file if you prefer direct editing.

## How it works

- Ships as a Claude Code plugin with `.claude-plugin/plugin.json`, plugin skills in `skills/`, and hook scripts in `hooks/`
- Hooks into `SubagentStart`, with legacy `PreToolUse` coverage for the `Task` tool (`Agent` on older Claude Code builds)
- Picks a random exercise and personality
- Writes an immediate fallback line to the status bar
- Fires `claude-haiku` in the background to generate a theatrical roast in the chosen voice
- 5-minute cooldown between nudges so it doesn't spam during rapid multi-agent sessions
- Exercise stays in the status bar for 15 minutes
- `/claude-fitness-break:fitness-setup` copies the status-line helper into Claude's plugin data directory before wiring `~/.claude/settings.json`, so the status line keeps working across plugin cache updates

## License

MIT
