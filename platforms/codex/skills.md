# Codex Skill Adapter

Codex can reuse Ars Contexta skill bodies, but the generated skill text must not
assume Claude Code invocation mechanics.

## Translation Rules

Keep:

- methodology steps
- quality gates
- handoff formats
- domain vocabulary transformation
- file and graph invariants

Translate:

- slash-command-only triggers into natural-language request patterns
- `${CLAUDE_PLUGIN_ROOT}` references into "plugin root" references with a
  fallback: locate the repo/plugin root by finding `reference/kernel.yaml`
- Claude tool names into capability descriptions such as "read files", "edit
  files", "run shell commands", and "search text"
- `AskUserQuestion` instructions into "ask one concise question and wait"
- "restart Claude Code" activation notes into Codex session/plugin activation
  notes

Remove or avoid in Codex-generated skills:

- `allowed-tools` as an execution guarantee
- Claude model routing assumptions
- `/arscontexta:*` as the only way to invoke a workflow
- assumptions that `PostToolUse` payloads contain `tool_input.file_path`

## Description Pattern

Descriptions should include both the workflow name and likely user language:

```yaml
description: Run the reduce/document phase on a source file and create atomic notes. Use when the user asks to process an inbox file, extract claims, summarize into notes, or turn source material into the knowledge graph.
```

## Runtime Path Pattern

When a skill needs bundled references, resolve them in this order:

1. Environment-provided plugin root, if present.
2. Current installed plugin root, if Codex exposes one.
3. Nearest ancestor containing `reference/kernel.yaml`.
4. Ask the user for the Ars Contexta repo/plugin path if none can be found.

Do not hard-code `CLAUDE_PLUGIN_ROOT` in Codex-only generated instructions.
