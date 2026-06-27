---
name: cli-subagent
description: Run an external subagent from a plan file or task prompt using the Gemini CLI, Claude CLI, or Codex CLI, then wait for it to finish without intervening and review the resulting file changes with git diff. Use when the user asks to execute a plan with a subagent, mentions SUBAGENT, or wants a passive delegated run followed by a diff review inside this repository.
---

# Subagent Runner

Use this skill when the user wants an external agent CLI to execute a plan or prompt while Codex stays passive during execution.

## Workflow

1. Identify the backend: `gemini`, `claude`, or `codex`.
2. Confirm the plan file exists if the task references one.
3. Determine the working directory the subagent must run in — the repository
   root that contains the plan file and the files to be changed. This is
   required: without it the subagent inherits the skill directory as its cwd and
   wastes the run "searching for plan.md".
4. Build a prompt that points to the plan file and states the execution constraint:
   do the work described by the plan, write files directly, and exit when complete.
   Reference the plan with an absolute path so it resolves regardless of cwd.
5. Run the helper script with `bash` from this skill directory, passing the
   working directory as the fourth argument. The script path below is relative
   to this `SKILL.md` file; `<work_dir>` should be an absolute path:

```bash
bash scripts/run_subagent.sh <backend> "<prompt>" <log_name> <work_dir>
```

If `<work_dir>` is omitted it defaults to the current `$PWD`. Logs are always
written under the invocation directory's `logs/`, while the subagent command runs
inside `<work_dir>`.

6. Wait for the command to exit. Do not send follow-up input or intervene while it runs.
7. The helper writes structured output to `logs/<log_name>.log` and automatically renders a markdown transcript to `logs/<log_name>.md` using `python3 scripts/parse_log_to_markdown.py`. The markdown file starts with the sibling `logs/<log_name>.prompt.txt` and `logs/<log_name>.meta` content, then appends the parsed transcript from the JSON log.
8. After completion, review the repo changes (the helper runs these against `<work_dir>`):
   - inspect `git -C <work_dir> status --short`
   - inspect `git -C <work_dir> diff --stat`
   - inspect `git -C <work_dir> diff` for touched files
9. Verify expected file creation if the plan promised new files.

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
