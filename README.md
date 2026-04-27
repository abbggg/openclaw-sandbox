# OpenClaw Sandbox

OpenShell sandbox image pre-configured with [OpenClaw](https://github.com/openclaw) for open agent manipulation and control.

## Repository Layout

`.openshell/` is the runnable sandbox contract for this repository.
The repository root is free for repo-level docs and other non-runtime files.

## Runtime Contract

- runnable sandbox files live in `.openshell/`
- create/connect/delete can be executed directly with `openshell` CLI
- OpenClaw configuration is created inside the sandbox in `~/.openclaw/openclaw.json`
- the preferred host-side create path is `scripts/openclaw_create_env.sh`, which patches the Sandbox CR to launch `/usr/local/bin/openclaw-sandbox-command` on every pod boot
- hh vacancy search is available in-sandbox via `openclaw-hh-vacancies` and the custom skill `hh-vacancies`
- ChatGPT device auth is post-launch and headless: the verified command inside the sandbox is `openclaw-auth-codex`, which runs `codex login --device-auth` and switches OpenClaw to `openai-codex/gpt-5.4`
- Telegram is configured post-auth through the native OpenClaw channel setup helper `openclaw-init-telegram`; the bot token is expected to come from an attached OpenShell provider as `TELEGRAM_BOT_TOKEN`
- Telegram direct messages stay in pairing mode, while `openclaw-start` applies the `yolo` exec preset so OpenClaw does not ask for action approvals inside the sandbox

## Quick Start

From the `robolaba` workspace root:

```bash
scripts/openclaw_create_env.sh --sandbox-id openclaw-sandbox
scripts/openshell_connect_env.sh --sandbox-id openclaw-sandbox openclaw-sandbox
```

`openclaw-start` in that flow is a human-facing helper that prints the next auth steps. The persistent gateway runtime is enabled by the post-create patch applied from `scripts/openclaw_create_env.sh`.
