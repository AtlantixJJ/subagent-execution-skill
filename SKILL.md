---
name: cli-subagent
description: Run an external subagent from a plan file or task prompt using the Gemini CLI, Claude CLI, Codex CLI, or Hermes CLI, then wait for it to finish without intervening and review the resulting file changes with git diff. Use when the user asks to execute a plan with a subagent, mentions SUBAGENT, or wants a passive delegated run followed by a diff review inside this repository.
---

# Subagent Runner

Use this skill when the user wants an external agent CLI to execute a plan or prompt while Gemini stays passive during execution.

## Workflow

1. Identify the backend: `gemini`, `claude`, `codex`, or `hermes`.
2. Confirm the plan file exists if the task references one.
3. Build a prompt that points to the plan file and states the execution constraint:
   do the work described by the plan, write files directly, and exit when complete.
4. Run the helper script with `bash` from this skill directory. The path below is relative to this `SKILL.md` file:

```bash
bash scripts/run_subagent.sh <backend> "<prompt>" <log_name>
```

5. Wait for the command to exit. Do not send follow-up input or intervene while it runs.
6. The helper writes structured output to `logs/<log_name>.log` and automatically renders a markdown transcript to `logs/<log_name>.md` using `python3 scripts/parse_log_to_markdown.py`. The markdown file starts with the sibling `logs/<log_name>.prompt.txt` and `logs/<log_name>.meta` content, then appends the parsed transcript from the JSON log.
7. After completion, review the repo changes:
   - inspect `git status --short`
   - inspect `git diff --stat`
   - inspect `git diff` for touched files
8. Verify expected file creation if the plan promised new files.

## Backend Mapping

- `gemini`:
  `gemini -y -p "<prompt>"`
- `claude`:
  `claude -p "<prompt>" --model claude-sonnet-5`
- `codex`:
  `codex exec --ephemeral "<prompt>"`
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

- Do not use Gemini's `invoke_agent` tool for this workflow. This skill is for external agent CLIs that operate independently of the current session's tool execution flow.
- Do not intervene after launch. Wait until the subprocess exits.
- Do not revert unrelated user changes while reviewing the diff.
- If the referenced plan file does not exist, stop and report that clearly.

## Prompt Pattern

Use a direct prompt like:

```text
Execute the task described in <plan-file>. Follow that plan exactly. Work in the current repository, make the required file changes, and exit when finished.
```

Add any user-specified constraints verbatim.
