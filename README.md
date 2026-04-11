# OpenClaw Sandbox

OpenShell sandbox image pre-configured with [OpenClaw](https://github.com/openclaw) for open agent manipulation and control.

## Repository Layout

`.openshell/` is the runnable sandbox contract for this repository.
The repository root is free for repo-level docs and other non-runtime files.

## Runtime Contract

- runnable sandbox files live in `.openshell/`
- create/connect/delete can be executed directly with `openshell` CLI
- OpenClaw configuration is created inside the sandbox in `~/.openclaw/openclaw.json`
- OpenAI Plus auth is post-launch and headless: the verified command inside the sandbox is `openclaw models auth --agent dev login --provider openai-codex --set-default`, after which the user pastes the full redirect URL back into the CLI

## Quick Start

From the repository root:

```bash
openshell sandbox create --name openclaw-sandbox --from .openshell --policy .openshell/policy.yaml --forward 18789 -- openclaw-start
openshell sandbox connect openclaw-sandbox
```
