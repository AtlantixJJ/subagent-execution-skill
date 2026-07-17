#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <agy|codex|claude|hermes> <prompt> <log_name> [work_dir]" >&2
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
work_dir="$(cd -- "$work_dir" && pwd)"

log_root="$PWD/logs"
mkdir -p "$log_root"
log_path="$log_root/${log_name}.log"
meta_path="$log_root/${log_name}.meta"
prompt_path="$log_root/${log_name}.prompt.txt"
markdown_path="$log_root/${log_name}.md"
status_path="$log_root/${log_name}.status"

# Backend logs are progress transcripts. Lifecycle state is kept separately so
# callers do not mistake an API response or stream event for process completion.
write_status() {
  local state="$1" exit_code="${2:-}" render_code="${3:-}" tmp_path
  tmp_path="${status_path}.$$"
  {
    printf 'state=%s\n' "$state"
    printf 'pid=%s\n' "$$"
    printf 'backend=%s\n' "$backend"
    printf 'log=%s\n' "$log_path"
    printf 'started_at=%s\n' "$started_at"
    [ -n "$exit_code" ] && printf 'subagent_exit_code=%s\n' "$exit_code"
    [ -n "$render_code" ] && printf 'transcript_exit_code=%s\n' "$render_code"
    printf 'updated_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } >"$tmp_path"
  mv -f -- "$tmp_path" "$status_path"
}

started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

case "$backend" in
  agy)
    # agy (>=1.0.x) has no JSON/stream output mode; print mode emits plain text.
    # Use --dangerously-skip-permissions for non-interactive auto-approval.
    cmd=(
      agy
      --dangerously-skip-permissions
      --print-timeout 30m
      -p "$prompt"
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
  claude)
    # --verbose is required by the claude CLI when combining -p with
    # --output-format stream-json; skip permissions for non-interactive writes.
    cmd=(
      claude
      -p "$prompt"
      --model claude-sonnet-5
      --output-format stream-json
      --verbose
      --dangerously-skip-permissions
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

write_status running
printf '%s\n' "$prompt" >"$prompt_path"

printf 'Running:'
printf ' %q' "${cmd[@]}"
printf '\nWork dir: %s\n' "$work_dir"
printf 'Log: %s\n' "$log_path"
printf 'Status: %s\n' "$status_path"
printf 'Meta: %s\n' "$meta_path"
printf 'Prompt: %s\n' "$prompt_path"

{
  printf 'backend=%s\n' "$backend"
  printf 'work_dir=%s\n' "$work_dir"
  printf 'log=%s\n' "$log_path"
  printf 'status_file=%s\n' "$status_path"
  printf 'prompt_file=%s\n' "$prompt_path"
  printf 'cmd='
  printf '%q ' "${cmd[@]}"
  printf '\n'
} >"$meta_path"

set +e
(cd -- "$work_dir" && "${cmd[@]}") >"$log_path" 2>&1 </dev/null
status=$?
set -e

write_status exited "$status"

set +e
python3 "$script_dir/parse_log_to_markdown.py" "$log_path" -o "$markdown_path"
render_status=$?
set -e

if [[ "$status" -eq 0 && "$render_status" -eq 0 ]]; then
  write_status complete "$status" "$render_status"
else
  write_status failed "$status" "$render_status"
fi

echo
echo "Subagent finished. Review summary:"
printf 'Markdown transcript: %s\n' "$markdown_path"
printf 'Status: %s\n' "$status_path"
git -C "$work_dir" status --short
echo
git -C "$work_dir" diff --stat

if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi
exit "$render_status"
