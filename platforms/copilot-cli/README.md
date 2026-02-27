# Copilot CLI Platform — Ars Contexta

Platform adapter for running Ars Contexta-generated vaults with GitHub Copilot CLI.

## Relationship to Claude Code Platform

Ars Contexta was built for Claude Code. This adapter maps the same concepts to Copilot CLI equivalents. The shared core — research graph, kernel primitives, derivation engine, processing pipeline — is identical. Only the integration layer differs.

## Platform Mapping

| Concept | Claude Code | Copilot CLI |
|---------|------------|-------------|
| Context file | `CLAUDE.md` | `CLAUDE.md` (Copilot reads it natively) |
| Custom instructions | `CLAUDE.md` | `CLAUDE.md`, `.github/copilot-instructions.md`, `AGENTS.md` |
| Hook config | `.claude/settings.json` | `.github/hooks/*.json` |
| Hook scripts | `.claude/hooks/scripts/` | `.github/hooks/scripts/` |
| Skills | `.claude/skills/` | `.github/skills/` |
| Agents | `.claude/agents/` | `.github/agents/` |
| MCP config | `.mcp.json` | `~/.copilot/mcp-config.json` |
| Plugin manifest | `.claude-plugin/plugin.json` | `plugin.json` (Copilot CLI plugin format) |

## Hook Event Mapping

| Claude Code Event | Copilot CLI Event | Notes |
|-------------------|-------------------|-------|
| `SessionStart` | `sessionStart` | ⚠️ Copilot ignores stdout — use skill for context injection |
| `PostToolUse` (matcher: Write) | `postToolUse` | ⚠️ Copilot ignores output — use `preToolUse` for enforcement |
| `Stop` | `sessionEnd` / `agentStop` | Output ignored in both |
| N/A | `preToolUse` | ✅ Copilot processes deny decisions — use for schema enforcement |
| N/A | `userPromptSubmitted` | Available for prompt logging |
| N/A | `errorOccurred` | Available for error tracking |
| N/A | `subagentStop` | Available for pipeline orchestration |

### Critical Difference: Hook Output Semantics

**Claude Code:**
- `SessionStart` hook stdout is injected into the conversation context
- `PostToolUse` hooks can return `{"additionalContext": "..."}` to inject warnings

**Copilot CLI:**
- `sessionStart` output is **ignored**
- `postToolUse` output is **ignored**
- Only `preToolUse` output is processed (for `permissionDecision: deny`)

**Workaround:** Session orientation is implemented as a **skill** (`session-orient`) instead of relying on hook stdout. Schema validation uses a **preToolUse** hook that denies writes missing frontmatter.

## Tool Name Mapping

Skills reference tool names in their instructions. Claude Code and Copilot CLI use different names:

| Claude Code | Copilot CLI | Notes |
|------------|-------------|-------|
| `Read` | `view` | |
| `Write` | `create` | For new files |
| `Write` | `edit` | For existing files |
| `Edit` | `edit` | |
| `Bash` | `bash` | |
| `Grep` | `grep` | |
| `Glob` | `glob` | |
| `AskUserQuestion` | `ask_user` | |
| `Task` (subagent) | `task` | Same name, different config |

## Environment Variable Mapping

| Claude Code | Copilot CLI | Notes |
|------------|-------------|-------|
| `${CLAUDE_PLUGIN_ROOT}` | No equivalent | Skills must use relative paths or `$ARSCONTEXTA_ROOT` convention |
| `$CLAUDE_PROJECT_DIR` | `cwd` in hook input JSON | Use `$(pwd)` as fallback |
| `$CLAUDE_ENV_FILE` | No equivalent | Cannot export env vars from hooks |

### Recommended: `$ARSCONTEXTA_ROOT`

Set in your shell profile to point at the plugin installation directory. See the [Installation](#installation) section for the correct path based on your install method.

This replaces `${CLAUDE_PLUGIN_ROOT}` references in skill files.

## What the Copilot Platform Produces

A Copilot CLI deployment generates:

| Output | Location | Purpose |
|--------|----------|---------|
| Context file | `CLAUDE.md` (git root) | Auto-loaded by Copilot CLI |
| Hook config | `.github/hooks/arscontexta.json` | Event-driven automation |
| Hook scripts | `.github/hooks/scripts/` | Session orient, validate, auto-commit, capture |
| Skills | `.github/skills/` | Processing pipeline commands |
| Agents | `.github/agents/` | knowledge-guide subagent |
| MCP config | Merged into `~/.copilot/mcp-config.json` | qmd semantic search |

## Installation

### Option A: Install as Plugin (Recommended)

From GitHub (once merged):

```bash
copilot plugin install agenticnotetaking/arscontexta:platforms/copilot-cli
```

From a local clone:

```bash
git clone https://github.com/Tonksthebear/arscontexta.git
copilot plugin install ./arscontexta/platforms/copilot-cli
```

Verify it loaded:

```bash
copilot plugin list
```

Then in a Copilot CLI session:

```
/skills list          # Should show session-orient
```

### Option B: Manual Copy (Per-Project)

1. Copy hooks and skills to your vault:
   ```bash
   cp -r platforms/copilot-cli/hooks/ .github/hooks/
   cp -r platforms/copilot-cli/skills/ .github/skills/
   cp platforms/copilot-cli/AGENTS.md ./AGENTS.md
   ```
2. Run the session-orient skill on first session: `/session-orient`

### Setting ARSCONTEXTA_ROOT

For either installation method, set `ARSCONTEXTA_ROOT` in your shell profile so skills can reference the methodology and kernel:

```bash
# Plugin install — points to plugin cache
export ARSCONTEXTA_ROOT="$HOME/.copilot/state/installed-plugins/arscontexta"

# Local clone — points to your clone
export ARSCONTEXTA_ROOT="/path/to/arscontexta"
```

## Prerequisites

| Dependency | Required | Purpose |
|-----------|----------|---------|
| [Copilot CLI](https://docs.github.com/copilot/concepts/agents/about-copilot-cli) | Yes | Agent host |
| `tree` | Yes | Workspace structure injection |
| `ripgrep` (`rg`) | Yes | YAML queries, schema validation |
| `jq` | Yes | JSON parsing in hook scripts (Copilot sends JSON on stdin) |
| [qmd](https://github.com/tobi/qmd) | Optional | Semantic search |
