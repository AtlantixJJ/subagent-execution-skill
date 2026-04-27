# subagent-execution-skill

Reusable Codex skill for running an external subagent CLI from a prompt or plan file and then reviewing the resulting git diff.

## Install

```bash
python /home/jianjinx/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo AtlantixJJ/subagent-execution-skill \
  --path subagent
```

Restart Codex after installation so the skill is picked up.
