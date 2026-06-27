#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <gemini|claude|codex> <prompt> <log_name> [work_dir]" >&2
  exit 2
fi

backend="$1"
prompt="$2"
log_name="$3"
work_dir="${4:-$PWD}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$work_dir" ]]; then
  echo "Working directory does not exist: $work_dir" >&2
  exit 2
fi
# Resolve to an absolute path so the subagent runs in a stable, known root.
work_dir="$(cd -- "$work_dir" && pwd)"

# Keep logs alongside the invocation directory, not the subagent work dir.
log_root="$PWD/logs"
mkdir -p "$log_root"
log_path="$log_root/${log_name}.log"
meta_path="$log_root/${log_name}.meta"
prompt_path="$log_root/${log_name}.prompt.txt"
markdown_path="$log_root/${log_name}.md"

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
    cmd=(
      claude
      -p "$prompt"
      --model claude-sonnet-4-6
      --output-format stream-json
    )
    ;;
  codex)
    cmd=(
      codex
      exec
      --ephemeral
      --json
      "$prompt"
    )
    ;;
  *)
    echo "Unsupported backend: $backend" >&2
    exit 2
    ;;
esac

printf 'Running:'
printf ' %q' "${cmd[@]}"
printf '\nWork dir: %s\n' "$work_dir"
printf 'Log: %s\n' "$log_path"
printf 'Meta: %s\n' "$meta_path"
printf 'Prompt: %s\n' "$prompt_path"

{
  printf 'backend=%s\n' "$backend"
  printf 'work_dir=%s\n' "$work_dir"
  printf 'log=%s\n' "$log_path"
  printf 'prompt_file=%s\n' "$prompt_path"
  printf 'cmd='
  printf '%q ' "${cmd[@]}"
  printf '\n'
} >"$meta_path"

set +e
(cd -- "$work_dir" && "${cmd[@]}") >"$log_path" 2>&1
status=$?
set -e

python3 "$script_dir/parse_log_to_markdown.py" "$log_path" -o "$markdown_path"

echo
echo "Subagent finished. Review summary:"
printf 'Markdown transcript: %s\n' "$markdown_path"
git -C "$work_dir" status --short
echo
git -C "$work_dir" diff --stat

exit "$status"
