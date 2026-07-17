#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <gemini|claude|codex|hermes> <prompt> <log_name>" >&2
  exit 2
fi

backend="$1"
prompt="$2"
log_name="$3"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p logs
log_path="logs/${log_name}.log"
meta_path="logs/${log_name}.meta"
prompt_path="logs/${log_name}.prompt.txt"
markdown_path="logs/${log_name}.md"

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
    # --verbose is required by the claude CLI when combining -p with
    # --output-format stream-json; skip permissions for non-interactive writes.
    cmd=(
      claude
      -p "$prompt"
      --model claude-sonnet-4-6
      --output-format stream-json
      --verbose
      --dangerously-skip-permissions
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
  hermes)
    # hermes oneshot mode prints only the final response text (no JSON/stream
    # mode); approvals are auto-bypassed. The parser's plain-text fallback
    # includes the output verbatim under the Transcript section.
    cmd=(
      hermes
      -z "$prompt"
    )
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

set +e
"${cmd[@]}" >"$log_path" 2>&1 </dev/null
status=$?
set -e

python3 "$script_dir/parse_log_to_markdown.py" "$log_path" -o "$markdown_path"

echo
echo "Subagent finished. Review summary:"
printf 'Markdown transcript: %s\n' "$markdown_path"
git status --short
echo
git diff --stat

exit "$status"
