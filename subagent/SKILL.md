---
name: cli-subagent
description: Run an external subagent from a plan file or task prompt using the Gemini CLI, Claude CLI, or Codex CLI, then wait for it to finish without intervening and review the resulting file changes with git diff. Use when the user asks to execute a plan with a subagent, mentions SUBAGENT, or wants a passive delegated run followed by a diff review inside this repository.
---

# Subagent Runner

Use this skill when the user wants an external agent CLI to execute a plan or prompt while Codex stays passive during execution.

## Workflow

1. Identify the backend: `gemini`, `claude`, or `codex`.
2. Confirm the plan file exists if the task references one.
3. Build a prompt that points to the plan file and states the execution constraint:
   do the work described by the plan, write files directly, and exit when complete.
4. Run the helper script:

```bash
/home/jianjinx/.codex/skills/subagent/scripts/run_subagent.sh <backend> "<prompt>" <log_name>
```

5. Wait for the command to exit. Do not send follow-up input or intervene while it runs.
6. After completion, review the repo changes:
   - inspect `git status --short`
   - inspect `git diff --stat`
   - inspect `git diff` for touched files
7. Verify expected file creation if the plan promised new files.

## Backend Mapping

- `gemini`:
  `gemini -y -p "<prompt>"`
- `claude`:
  `claude -p "<prompt>" --model claude-sonnet-4-6`
- `codex`:
  `codex exec --ephemeral "<prompt>"`

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
