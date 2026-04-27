#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <gemini|claude|codex> <prompt> <log_name>" >&2
  exit 2
fi

backend="$1"
prompt="$2"
log_name="$3"

mkdir -p logs
log_path="logs/${log_name}.log"
meta_path="logs/${log_name}.meta"
prompt_path="logs/${log_name}.prompt.txt"

printf '%s\n' "$prompt" >"$prompt_path"

case "$backend" in
  gemini)
    cmd=(
      gemini
      -y
      -p "$prompt"
      --output-format stream-json
    )
    ;;
  claude)
    cmd=(claude -p "$prompt" --model claude-sonnet-4-6)
    ;;
  codex)
    cmd=(codex exec --ephemeral "$prompt")
    ;;
  *)
    echo "Unsupported backend: $backend" >&2
    exit 2
    ;;
esac

printf 'Running:'
printf ' %q' "${cmd[@]}"
printf '\nLog: %s\n' "$log_path"
printf 'Meta: %s\n' "$meta_path"
printf 'Prompt: %s\n' "$prompt_path"

{
  printf 'backend=%s\n' "$backend"
  printf 'cwd=%s\n' "$PWD"
  printf 'log=%s\n' "$log_path"
  printf 'prompt_file=%s\n' "$prompt_path"
  printf 'cmd='
  printf '%q ' "${cmd[@]}"
  printf '\n'
} >"$meta_path"

"${cmd[@]}" >"$log_path" 2>&1

echo
echo "Subagent finished. Review summary:"
git status --short
echo
git diff --stat
