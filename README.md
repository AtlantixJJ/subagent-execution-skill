# subagent-execution-skill

Reusable skill for running an external subagent CLI from a prompt or plan file and then reviewing the resulting git diff. Supports Claude Code, Codex, and Gemini as host agents.

## Branches

| Branch | Host agent | Install target |
|--------|-----------|---------------|
| [`claude`](../../tree/claude) | Claude Code (`claude` CLI) | `~/.claude/skills/` |
| [`codex`](../../tree/codex) | Codex (`codex` CLI) | `~/.codex/skills/` |
| `main` | — | Overview only |

Choose the branch that matches the coding agent you use. Each branch contains a README with agent-specific install instructions.

## Supported Backends

All branches support delegating work to any of these external agent CLIs:

- `claude` — `claude -p "<prompt>" --model claude-sonnet-4-6 --output-format stream-json`
- `gemini` — `gemini -y -p "<prompt>" --output-format stream-json`
- `codex` — `codex exec --ephemeral "<prompt>"`

## Dependencies

- `python3` for rendering the markdown transcript from structured logs
- The CLI for your chosen backend, installed and authenticated
