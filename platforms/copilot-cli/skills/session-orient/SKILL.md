---
name: session-orient
description: >
  Orients the agent at the start of a session by loading workspace structure,
  identity, goals, and maintenance signals. Use this skill at the beginning of
  every session, or when you need to re-orient after context compaction.
allowed-tools: bash, view, glob
---

# Session Orientation

This skill replaces the Claude Code SessionStart hook for Copilot CLI. In Claude
Code, the session-orient hook injects context via stdout. Copilot CLI ignores
hook output, so this skill loads the same context on demand.

**Run this at the start of every session.** It takes 5-10 seconds and gives you
full situational awareness.

## Steps

### 1. Workspace Structure

Run `tree` to see the vault layout:

```bash
tree -L 3 --charset ascii -I '.git|node_modules' -P '*.md' .
```

If `tree` is not available, fall back to:

```bash
find . -name "*.md" -not -path "./.git/*" -not -path "*/node_modules/*" -maxdepth 3 | sort
```

### 2. Identity Loading

If a `self/` directory exists, read these files to remember who you are:

1. `self/identity.md` — your identity and operating principles
2. `self/methodology.md` — how you think and work
3. `self/goals.md` — current priorities and objectives

If `self/` doesn't exist, check for `ops/goals.md` instead.

### 3. Session Continuity

Check for previous session state:

```bash
cat ops/sessions/current.json 2>/dev/null
```

If a previous session exists, note its ID and start time for continuity.

### 4. Learned Behaviors

Check for recent methodology notes (behavioral patterns learned from experience):

```bash
ls -t ops/methodology/*.md 2>/dev/null | head -5
```

Read the first 3 lines of each to surface recent learnings.

### 5. Maintenance Signals

Check conditions and surface actionable signals:

| Condition | Check | Action |
|-----------|-------|--------|
| Pending observations ≥ 10 | `ls ops/observations/*.md 2>/dev/null \| wc -l` | Suggest `/rethink` |
| Unresolved tensions ≥ 5 | `ls ops/tensions/*.md 2>/dev/null \| wc -l` | Suggest `/rethink` |
| Unprocessed sessions ≥ 5 | `ls ops/sessions/*.json 2>/dev/null \| grep -cv current` | Suggest `/remember --mine-sessions` |
| Inbox items ≥ 3 | `ls inbox/*.md 2>/dev/null \| wc -l` | Suggest `/reduce` or `/pipeline` |

### 6. Workboard Reconciliation

If `ops/scripts/reconcile.sh` exists, run it:

```bash
bash ops/scripts/reconcile.sh --compact 2>/dev/null
```

### 7. Methodology Staleness

If `ops/methodology/` and `ops/config.yaml` both exist, check if methodology
notes are more than 30 days behind config changes. If so, suggest `/rethink drift`.

## Output

After completing all steps, provide a brief orientation summary:

```
Session oriented. [N notes] in vault, [M items] in inbox.
Identity: [loaded / not configured]
Goals: [loaded / none found]
Maintenance: [any conditions found, or "all clear"]
```
