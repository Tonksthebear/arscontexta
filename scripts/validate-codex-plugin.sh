#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required"

jq empty \
  .codex-plugin/plugin.json \
  .agents/plugins/marketplace.json \
  hooks/codex-hooks.json \
  platforms/codex/hooks/codex-hooks.json.template

sh -n \
  hooks/scripts/codex-plugin-hook.sh \
  platforms/codex/hooks/codex-hooks.sh.template

skills_path="$(jq -r '.skills' .codex-plugin/plugin.json)"
[ "$skills_path" = "./platforms/codex/skills/" ] || fail "Codex manifest must point at translated Codex skills"

for skill in setup help ask health recommend architect add-domain reseed tutorial upgrade; do
  [ -f "platforms/codex/skills/$skill/SKILL.md" ] || fail "missing Codex skill: $skill"
done

if rg -n '^(context|model|allowed-tools|argument-hint):|CLAUDE_PLUGIN_ROOT|AskUserQuestion' platforms/codex/skills >/tmp/arscontexta-codex-skill-scan.txt; then
  cat /tmp/arscontexta-codex-skill-scan.txt >&2
  fail "Codex skills contain Claude-only frontmatter or runtime tokens"
fi

tmp="${TMPDIR:-/tmp}/arscontexta-codex-validate-$$"
mkdir -p "$tmp/notes" "$tmp/ops/scripts"
cp platforms/codex/hooks/codex-hooks.sh.template "$tmp/ops/scripts/codex-hooks.sh"
chmod +x "$tmp/ops/scripts/codex-hooks.sh"
printf 'body\n' > "$tmp/notes/bad.md"

output="$(
  cd "$tmp" &&
  printf '%s' '{"hook_event_name":"PostToolUse","tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: notes/bad.md\n@@\n body\n*** End Patch\n"}}' |
    ops/scripts/codex-hooks.sh PostToolUse
)"

printf '%s' "$output" | grep -q 'Schema warnings for bad' || fail "Codex dispatcher did not validate apply_patch payload"

if command -v codex >/dev/null 2>&1; then
  codex_home="$tmp/codex-home"
  mkdir -p "$codex_home"
  CODEX_HOME="$codex_home" codex plugin marketplace add . >/dev/null
fi

echo "Codex plugin validation passed"
