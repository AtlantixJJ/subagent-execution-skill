# subagent-execution-skill

Reusable Claude Code skill for running an external subagent CLI from a prompt or plan file and then reviewing the resulting git diff.

This branch (`claude`) is tailored for installation with Claude Code. See the `codex` branch for the Codex CLI version and the `main` branch for a backend-agnostic overview.

## Dependencies

- `python3` for rendering the markdown transcript from structured logs
- `claude` CLI installed and authenticated (`claude --version`)

## Install

Clone directly into your Claude skills directory as `subagent`:

```bash
git clone https://github.com/AtlantixJJ/subagent-execution-skill.git -b claude ~/.claude/skills/subagent
```

To update later: `git -C ~/.claude/skills/subagent pull`

Restart Claude Code after installation so the skill is picked up.

## Usage

Ask Claude Code:

```text
Run the subagent on my plan file plan.md
```

or

```text
SUBAGENT: execute plan.md using claude backend
```

The runner accepts an optional fourth argument for the repository where the
subagent should work. This is useful when invoking it from the skill directory:

```bash
bash scripts/run_subagent.sh codex "Execute /abs/path/plan.md" run-001 /abs/path/project
```

## Completion detection

Backend logs are progress transcripts and may contain messages that sound like completion while
the agent is still running. The runner writes `logs/<log_name>.status`; wait for the runner process
to exit and require `state=complete` before consuming the result. `state=running` is still active,
and `state=failed` requires investigation. API responses, stream events, and tool results in the
backend log are not completion signals.

## Supported Backends

The default backend is `claude`. You can also specify `agy`, `codex`, or `hermes`.
