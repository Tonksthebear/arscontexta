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
  platforms/codex/.codex-plugin/plugin.json \
  .agents/plugins/marketplace.json \
  platforms/codex/hooks/codex-hooks.json \
  hooks/codex-hooks.json \
  platforms/codex/hooks/codex-hooks.json.template

sh -n \
  hooks/scripts/codex-plugin-hook.sh \
  platforms/codex/hooks/scripts/codex-plugin-hook.sh \
  platforms/codex/hooks/codex-hooks.sh.template

marketplace_path="$(jq -r '.plugins[] | select(.name == "arscontexta") | .source.path' .agents/plugins/marketplace.json)"
[ "$marketplace_path" = "./platforms/codex" ] || fail "Marketplace must point at non-empty Codex plugin root"

skills_path="$(jq -r '.skills' platforms/codex/.codex-plugin/plugin.json)"
[ "$skills_path" = "./skills/" ] || fail "Codex plugin-root manifest must point at translated Codex skills"

[ -f "platforms/codex/reference/kernel.yaml" ] || fail "Codex plugin root must package reference/kernel.yaml"
[ -f "platforms/codex/reference/claim-map.md" ] || fail "Codex plugin root must package reference/claim-map.md"
[ -f "platforms/codex/reference/three-spaces.md" ] || fail "Codex plugin root must package reference/three-spaces.md"
[ -d "platforms/codex/methodology" ] || fail "Codex plugin root must package methodology research graph"
[ "$(find platforms/codex/methodology -type f -name '*.md' | wc -l | tr -d ' ')" -gt 0 ] || fail "Codex plugin methodology graph is empty"

for skill in setup help ask health recommend architect add-domain reseed tutorial upgrade; do
  [ -f "platforms/codex/skills/$skill/SKILL.md" ] || fail "missing Codex skill: $skill"
done

for skill in reduce reflect reweave verify validate seed ralph pipeline tasks stats graph next learn remember rethink refactor; do
  [ -f "platforms/codex/skill-sources/$skill/SKILL.md" ] || fail "missing Codex skill source: $skill"
done

if rg -n '^(context|model|allowed-tools|argument-hint):|CLAUDE_PLUGIN_ROOT|AskUserQuestion' platforms/codex/skills platforms/codex/skill-sources >/tmp/arscontexta-codex-skill-scan.txt; then
  cat /tmp/arscontexta-codex-skill-scan.txt >&2
  fail "Codex skills or skill sources contain Claude-only frontmatter or runtime tokens"
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

printf 'body\n' > "$tmp/notes/bash-bad.md"
output="$(
  cd "$tmp" &&
  printf '%s' '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"printf body > notes/bash-bad.md"}}' |
    ops/scripts/codex-hooks.sh PostToolUse
)"

printf '%s' "$output" | grep -q 'Schema warnings for bash-bad' || fail "Codex dispatcher did not validate Bash redirect payload"

printf 'body\n' > "$tmp/notes/second-bad.md"
output="$(
  cd "$tmp" &&
  printf '%s' '{"hook_event_name":"PostToolUse","tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: notes/bad.md\n@@\n body\n*** Update File: notes/second-bad.md\n@@\n body\n*** End Patch\n"}}' |
    ops/scripts/codex-hooks.sh PostToolUse
)"

printf '%s' "$output" | grep -q 'Schema warnings for bad' || fail "Codex dispatcher did not validate first file in multi-file patch"
printf '%s' "$output" | grep -q 'Schema warnings for second-bad' || fail "Codex dispatcher did not validate second file in multi-file patch"

printf 'body\n' > "$tmp/notes/moved-bad.md"
output="$(
  cd "$tmp" &&
  printf '%s' '{"hook_event_name":"PostToolUse","tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: notes/bad.md\n*** Move to: notes/moved-bad.md\n@@\n body\n*** End Patch\n"}}' |
    ops/scripts/codex-hooks.sh PostToolUse
)"

printf '%s' "$output" | grep -q 'Schema warnings for moved-bad' || fail "Codex dispatcher did not validate apply_patch move target"

if command -v codex >/dev/null 2>&1; then
  codex_home="$tmp/codex-home"
  mkdir -p "$codex_home"
  CODEX_HOME="$codex_home" codex plugin marketplace add . >/dev/null
fi

echo "Codex plugin validation passed"
