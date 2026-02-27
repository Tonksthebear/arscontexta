# Ars Contexta — Agent Instructions

## Session Start

At the beginning of every session, run the `session-orient` skill before doing anything else. This loads your workspace structure, identity, goals, and maintenance signals.

If the skill is not available, manually execute the orientation steps:

1. Run `tree -L 3 --charset ascii -I '.git|node_modules' -P '*.md' .`
2. Read `self/identity.md`, `self/methodology.md`, `self/goals.md` (if they exist)
3. Read `ops/sessions/current.json` for session continuity
4. Check `ops/methodology/*.md` for learned behaviors

## Schema Enforcement

All notes in `notes/` and `thinking/` must include YAML frontmatter with at minimum:

```yaml
---
description: <one-line summary>
topics: [<relevant topics>]
---
```

The `preToolUse` hook will deny writes missing this frontmatter.

## Tool References

This system uses Copilot CLI tool names: `view`, `create`, `edit`, `bash`, `grep`, `glob`, `ask_user`, `task`.
