# Tool Name Mapping — Claude Code ↔ Copilot CLI

When adapting skill-source templates for Copilot CLI, the following tool names
must be translated in skill instructions and `allowed-tools` frontmatter.

## Tool Mapping

| Claude Code | Copilot CLI | Notes |
|------------|-------------|-------|
| `Read` | `view` | Read file contents |
| `Write` | `create` | Create new file |
| `Write` | `edit` | Modify existing file (Copilot separates create/edit) |
| `Edit` | `edit` | Modify existing file |
| `Bash` | `bash` | Execute shell commands |
| `Grep` | `grep` | Search file contents (both use ripgrep) |
| `Glob` | `glob` | Find files by pattern |
| `AskUserQuestion` | `ask_user` | Prompt user for input |
| `Task` | `task` | Spawn subagent |

## Frontmatter Translation

**Claude Code:**
```yaml
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
```

**Copilot CLI:**
```yaml
allowed-tools: view, create, edit, bash, glob, grep, ask_user
```

## Key Differences

1. **Write vs create/edit:** Claude Code uses `Write` for both new and existing files.
   Copilot CLI separates `create` (new files only) and `edit` (existing files only).
   Skills that call `Write` should be updated to use both `create` and `edit`.

2. **Case:** Claude Code tools are PascalCase; Copilot CLI tools are snake_case/lowercase.

3. **MCP tools:** Both platforms support `mcp__qmd__*` tool names identically.

## Automated Translation

During setup, when `platform = "copilot-cli"`, the skill generation step should
apply this mapping to `allowed-tools` in SKILL.md frontmatter and to tool
references in skill instruction text.
