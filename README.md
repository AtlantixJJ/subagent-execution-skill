# subagent-execution-skill

Reusable Claude Code skill for running an external subagent CLI from a prompt or plan file and then reviewing the resulting git diff.

This branch (`claude`) is tailored for installation with Claude Code. See the `codex` branch for the Codex CLI version and the `main` branch for a backend-agnostic overview.

## Dependencies

- `python3` for rendering the markdown transcript from structured logs
- `claude` CLI installed and authenticated (`claude --version`)

## Install

Clone the repository and copy the skill into your Claude skills directory:

```bash
git clone https://github.com/AtlantixJJ/subagent-execution-skill.git -b claude
cp -r subagent-execution-skill/subagent ~/.claude/skills/
```

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

## Supported Backends

The default backend is `claude`. You can also specify `gemini` or `codex`.
