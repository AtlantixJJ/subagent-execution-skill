---
name: cli-subagent
description: Run an external subagent from a plan file or task prompt using the agy CLI, Claude CLI, Codex CLI, or Hermes CLI, then wait for it to finish without intervening and review the resulting file changes with git diff. Use when the user asks to execute a plan with a subagent, mentions SUBAGENT, or wants a passive delegated run followed by a diff review inside this repository.
---

# Subagent Runner

Use this skill when the user wants an external agent CLI to execute a plan or prompt while Codex stays passive during execution.

## Workflow

1. Identify the backend: `agy`, `codex` (default), `claude`, or `hermes`.
2. Confirm the plan file exists if the task references one.
3. Determine the working directory the subagent must run in — the repository
   root that contains the plan file and the files to be changed.
4. Build a prompt that points to the plan file and states the execution constraint:
   do the work described by the plan, write files directly, and exit when complete.
   Use an absolute plan path when the runner is invoked outside the project root.
5. Run the helper script with `bash`, passing the working directory as the fourth
   argument when needed:

```bash
bash ~/.codex/skills/cli-subagent/scripts/run_subagent.sh <backend> "<prompt>" <log_name> [work_dir]
```

If `work_dir` is omitted it defaults to the current `$PWD`. Logs are written
under the invocation directory, while the subagent runs inside `work_dir`.

6. Wait for the command to exit. Do not send follow-up input or intervene while it runs.
7. The helper writes backend output to `logs/<log_name>.log`, lifecycle state to
   `logs/<log_name>.status`, and automatically renders a markdown transcript to
   `logs/<log_name>.md` using `python3 scripts/parse_log_to_markdown.py`. The status sidecar is
   authoritative: `state=running` means the subprocess has not exited; `state=complete` means
   both the subprocess and transcript renderer succeeded; `state=failed` means at least one
   failed. Never infer completion from backend log lines such as API responses, stream-complete
   events, or tool results.
8. After the runner exits, confirm the sidecar says `state=complete`, then review the repo changes
   using `git -C <work_dir> status --short`, `git -C <work_dir> diff --stat`, and
   `git -C <work_dir> diff`.
9. Verify expected file creation if the plan promised new files.

## Backend Mapping

- `agy`:
  `agy --dangerously-skip-permissions --print-timeout 30m -p "<prompt>"`
  (agy >=1.0.x has no JSON/stream output mode; print mode emits plain text,
  which the parser includes verbatim under the Transcript section.)
- `codex` (default):
  `codex exec --ephemeral "<prompt>"`
- `claude`:
  `claude -p "<prompt>" --model claude-sonnet-5`
- `hermes`:
  `hermes -z "<prompt>"`
  (oneshot mode prints only the final response text; no JSON/stream output
  mode, so the parser's plain-text fallback includes it verbatim under the
  Transcript section. Approvals are auto-bypassed in oneshot mode.
  CAUTION: on long multi-step prompts hermes's tool-call formatting can
  degrade mid-run — tool calls leak into the output as text and it exits 0
  having changed nothing. Keep hermes dispatches small and single-purpose,
  and verify file changes rather than trusting exit code or its claims.)

The helper script writes stdout and stderr to `logs/<log_name>.log`.

## Constraints

- Do not use Codex `spawn_agent` for this workflow. This skill is for external agent CLIs.
- Do not intervene after launch. Wait until the subprocess exits.
- Do not revert unrelated user changes while reviewing the diff.
- If the referenced plan file does not exist, stop and report that clearly.

## Prompt Pattern

Use a direct prompt like:

```text
Execute the task described in <plan-file>. Follow that plan exactly. Work in the current repository, make the required file changes, and exit when finished.
```

Add any user-specified constraints verbatim.
