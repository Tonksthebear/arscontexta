# platforms/ -- Distribution View

This directory maps distribution layouts for agent platforms. It does not contain
the generation logic itself -- that lives in `generators/`. What `platforms/`
provides is a reference view of what each platform produces and how the shared
components relate to platform-specific ones.

## Relationship to generators/

The `generators/` directory is the working structure:

- `generators/claude-md.md` -- CLAUDE.md generation template
- `generators/features/` -- 14 composable feature blocks

`platforms/` organizes these same components from a distribution perspective:
what does each platform user get, and what remains shared?

## Structure

```
platforms/
├── shared/
│   ├── features/     --> generators/features/ (14 canonical feature blocks)
│   └── templates/    --> reference/templates/ (10 note type templates)
├── claude-code/
│   ├── generator.md  --> generators/claude-md.md (CLAUDE.md generation)
│   └── hooks/        Hook templates for Claude Code platform
├── codex/
│   ├── generator.md  --> CODEX.md generation reference
│   └── hooks/        Hook templates for Codex platform
└── README.md         This file
```

## How platforms/ is used

During plugin packaging (Section 18 of the PRD), the build process references `platforms/` to assemble the distribution:

- **Claude Code plugin** reads `platforms/shared/` and `platforms/claude-code/` to bundle feature blocks, templates, generation logic, and hook templates alongside the `skills/`, `reference/`, and `thinking/` directories.
- **Codex plugin** reads `platforms/shared/` and `platforms/codex/` to expose the same methodology through Codex skills, `CODEX.md`, and Codex-native hook dispatch.

The `generators/` directory remains the canonical source. Files here are not duplicated -- README files document the relationship and provide platform-specific context that the generator files themselves don't carry.

## What the platform produces

| Output | Claude Code | Codex |
|--------|-------------|-------|
| Context file | CLAUDE.md | CODEX.md |
| Hooks | .claude/hooks/ (bash scripts) | Codex hooks -> ops/scripts/codex-hooks.sh |
| Settings | .claude/settings.json | ~/.codex/hooks.json or plugin hook config |
| Skills | Inherited from plugin skills/ | Inherited from plugin skills/ |
| Identity | Embedded in CLAUDE.md | Embedded in CODEX.md |
| Memory bootstrap | Embedded in CLAUDE.md | Embedded in CODEX.md |
