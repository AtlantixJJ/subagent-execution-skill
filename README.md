# subagent-execution-skill

Reusable Codex skill for running an external subagent CLI from a prompt or plan file and then reviewing the resulting git diff.

This branch (`codex`) is tailored for installation with Codex. See the `claude` branch for the Claude Code version and the `main` branch for a backend-agnostic overview.

## Dependencies

- `python3` for rendering the markdown transcript from structured logs
- `codex` CLI installed and authenticated (`codex --version`)

## Install

Clone directly into your Codex skills directory as `cli-subagent`:

```bash
git clone https://github.com/AtlantixJJ/subagent-execution-skill.git -b codex ~/.codex/skills/cli-subagent
```

To update later: `git -C ~/.codex/skills/cli-subagent pull`

Restart Codex after installation so the skill is picked up.

## Usage

Ask Codex:

```text
Run the subagent on my plan file plan.md
```

or

```text
SUBAGENT: execute plan.md using codex backend
```

## Supported Backends

The default backend is `codex`. You can also specify `agy` or `claude`.
