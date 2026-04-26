# Codex Platform -- Generation Reference

## Generator Status

Codex support is a platform adapter over the same Ars Contexta methodology used
by Claude Code. The derivation logic remains shared: the platform changes the
generated runtime files, not the knowledge architecture.

## What Codex Platform Generates

### 1. CODEX.md

The primary Codex runtime guide. It adapts the generated system's methodology to
plain-language Codex requests instead of Claude slash commands.

It should contain:

- the same operating philosophy and three-space architecture as the Claude guide
- a Claude-command to Codex-request translation table
- the session rhythm: orient, work, persist
- validation expectations and manual fallback commands
- platform-specific caveats for hooks, skills, and MCP

`CLAUDE.md` may still be generated for dual-runtime vaults, but `CODEX.md` is
the Codex-native entry point.

### 2. ops/scripts/codex-hooks.sh

Codex hook dispatcher. It receives native Codex hook JSON on stdin and routes to
vault-local behavior:

- `SessionStart` -> orientation output and session metadata
- `PostToolUse` -> changed-file extraction, note validation, optional auto-commit
- `Stop` -> session capture and persistence

Codex 0.125.0 emits `PostToolUse` for `apply_patch` and `Bash`. Unlike Claude's
`Write` payload, Codex file paths can appear in patch text, command text, or
tool responses, so the dispatcher must extract changed paths from Codex payloads
instead of assuming `tool_input.file_path`.

Template source: `platforms/codex/hooks/codex-hooks.sh.template`.

### 3. ~/.codex/hooks.json or Plugin Hook Config

Generated vaults can install the hook template globally or receive it from a
Codex plugin:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ops/scripts/codex-hooks.sh SessionStart",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash ops/scripts/codex-hooks.sh PostToolUse",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ops/scripts/codex-hooks.sh PostToolUse",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ops/scripts/codex-hooks.sh Stop",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### 4. Skills

Codex uses natural-language skill discovery rather than Claude slash commands.
Generated Codex skills should keep the methodology instructions but avoid
depending on:

- slash-command invocation as the only trigger
- Claude-only tool names
- `${CLAUDE_PLUGIN_ROOT}`
- `AskUserQuestion`
- Claude model routing fields

Descriptions should name both the conceptual operation and common user phrasing,
for example: "Run the reduce/document phase on a source file and create atomic
notes."

Detailed translation rules live in `platforms/codex/skills.md`.

### 5. MCP

Codex supports MCP through the user's Codex configuration and plugin manifests.
Generated qmd configuration remains additive: preserve existing servers and add
the qmd server only when semantic search is enabled.

## Platform Characteristics

| Aspect | Detail |
|--------|--------|
| Context loading | `CODEX.md` plus installed Codex skills |
| Hook language | Bash dispatcher called by native Codex hooks |
| Hook events | `SessionStart`, `PostToolUse`, `Stop` |
| File edits | `apply_patch` and `Bash` both emit `PostToolUse` in Codex 0.125.0 |
| Skill format | `SKILL.md` with Codex-readable frontmatter and natural-language triggers |
| Slash commands | Not required; translate intent to direct requests |
| MCP support | Yes, through Codex config/plugin MCP manifests |
