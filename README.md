# OpenClaw Sandbox

OpenShell sandbox image pre-configured with [OpenClaw](https://github.com/openclaw) for open agent manipulation and control.

## Repository Layout

`.openshell/` is the runnable sandbox contract for this repository.
The repository root is free for repo-level docs and other non-runtime files.

## Runtime Contract

- runnable sandbox files live in `.openshell/`
- create/connect/delete can be executed directly with `openshell` CLI
- OpenClaw configuration is created inside the sandbox in `~/.openclaw/openclaw.json`
- hh vacancy search is available in-sandbox via `openclaw-hh-vacancies` and the custom skill `hh-vacancies`
- ChatGPT device auth is post-launch and headless: the verified command inside the sandbox is `openclaw-auth-codex`, which runs `codex login --device-auth` and switches OpenClaw to `openai-codex/gpt-5.4`
- Telegram is configured post-auth through the native OpenClaw channel setup helper `openclaw-init-telegram`; the bot token is expected to come from an attached OpenShell provider as `TELEGRAM_BOT_TOKEN`
- if `OPENCLAW_TELEGRAM_ALLOW_FROM` is attached at create time, Telegram runs in trusted allowlist mode for those Telegram user ids and skips pairing approval

## Quick Start

From the repository root:

```bash
openshell sandbox create --name openclaw-sandbox --from .openshell --policy .openshell/policy.yaml --forward 18789 -- openclaw-start
openshell sandbox connect openclaw-sandbox
```
