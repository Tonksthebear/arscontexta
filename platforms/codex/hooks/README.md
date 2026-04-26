# Codex Hook Templates

Codex hooks use the same event names as Claude for the lifecycle events Ars
Contexta needs, but the payloads differ. The Codex adapter therefore routes all
events through a dispatcher instead of reusing Claude hook scripts directly.

## Events

Generated vault hook configuration lives in
`platforms/codex/hooks/codex-hooks.json.template`, and the dispatcher script
template lives in `platforms/codex/hooks/codex-hooks.sh.template`.
Plugin-level hook configuration lives at `hooks/codex-hooks.json` and delegates
only when a generated vault dispatcher is present.

### SessionStart

Runs vault orientation:

- print a compact workspace map
- load identity and goals when present
- surface queue, inbox, observation, and tension counts
- reconcile condition-based maintenance signals

### PostToolUse

Runs after tool calls. Codex 0.125.0 has been validated to emit `PostToolUse`
for:

- `apply_patch` file edits
- `Bash` commands, including shell-based file writes

The dispatcher should inspect the JSON payload from stdin. For `apply_patch`,
extract changed paths from the patch text or tool response. For `Bash`, inspect
the command text and, when necessary, fall back to checking recently changed
vault files.

### Stop

Captures session metadata and persists operational state.

## Matcher Guidance

Use both `Write` and `Bash` matchers for post-write validation:

- `Write` covers Codex file-edit tools such as `apply_patch`
- `Bash` covers shell commands that can write files

Do not assume Claude's `tool_input.file_path` shape exists. Codex payloads
include `tool_name`, `tool_input`, `tool_response`, `cwd`, `session_id`, and
other metadata.
