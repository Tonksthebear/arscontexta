# Path Resolution — Replacing `${CLAUDE_PLUGIN_ROOT}`

## Problem

`${CLAUDE_PLUGIN_ROOT}` is a Claude Code-specific environment variable that
resolves to the plugin's installation directory. It's referenced ~105 times
across skills, agents, and hook configs. Copilot CLI has no equivalent.

## Strategy

Use `$ARSCONTEXTA_ROOT` as a platform-agnostic equivalent. Users set this in
their shell profile. Skills and hook scripts reference it instead.

### Setup

Add to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
export ARSCONTEXTA_ROOT="/path/to/arscontexta"
```

### How It Works

| Context | Claude Code | Copilot CLI |
|---------|------------|-------------|
| Skills (SKILL.md) | `${CLAUDE_PLUGIN_ROOT}/reference/kernel.yaml` | `$ARSCONTEXTA_ROOT/reference/kernel.yaml` |
| Hook scripts | `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/...` | Relative paths (scripts live in `.github/hooks/scripts/`) |
| Agents | `${CLAUDE_PLUGIN_ROOT}/reference/...` | `$ARSCONTEXTA_ROOT/reference/...` |

### During Setup

When `platform = "copilot-cli"`, the setup generator should:

1. Detect whether `$ARSCONTEXTA_ROOT` is set in the environment
2. If not set, prompt the user to add it to their shell profile
3. When generating skills from `skill-sources/`, replace `${CLAUDE_PLUGIN_ROOT}`
   with `$ARSCONTEXTA_ROOT` in the generated SKILL.md files
4. When generating hook scripts, use relative paths (hooks live alongside
   the scripts they call)

### Fallback Detection

If `$ARSCONTEXTA_ROOT` is not set, skills can attempt to find the plugin:

```bash
# Check common locations
ARSCONTEXTA_ROOT="${ARSCONTEXTA_ROOT:-}"
[ -z "$ARSCONTEXTA_ROOT" ] && [ -d "$HOME/.copilot/plugins/arscontexta" ] && ARSCONTEXTA_ROOT="$HOME/.copilot/plugins/arscontexta"
[ -z "$ARSCONTEXTA_ROOT" ] && [ -d "$HOME/.claude/plugins/arscontexta" ] && ARSCONTEXTA_ROOT="$HOME/.claude/plugins/arscontexta"
```

### Scope

This mapping is performed during skill generation (setup Phase 5, Step 9).
The source templates in `skill-sources/` retain `${CLAUDE_PLUGIN_ROOT}` as
the canonical reference. Translation happens at generation time, not in the
templates themselves.
