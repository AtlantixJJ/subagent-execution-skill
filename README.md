# subagent-execution-skill

Reusable Codex skill for running an external subagent CLI from a prompt or plan file and then reviewing the resulting git diff.

## Dependencies

- `python3` for rendering the markdown transcript from structured logs

## Install

Clone directly into your Codex skills directory as `subagent`:

```bash
git clone https://github.com/AtlantixJJ/subagent-execution-skill.git -b codex ~/.codex/skills/subagent
```

To update later: `git -C ~/.codex/skills/subagent pull`

Restart Codex after installation so the skill is picked up.
