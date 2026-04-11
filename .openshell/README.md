# OpenClaw Sandbox

OpenShell sandbox image pre-configured with [OpenClaw](https://github.com/openclaw) for open agent manipulation and control.

## OpenShell Layout

This directory is the runnable sandbox contract for OpenShell-compatible tooling.
The repository root may contain any repo-level files that are useful to humans, but it is not used for sandbox materialization.

## What's Included

- **OpenClaw CLI 2026.4.9** -- Agent orchestration and gateway management
- **OpenClaw Gateway** -- Local gateway for agent-to-tool communication
- **Node.js 22** -- Runtime required by the OpenClaw gateway
- **openclaw-start** -- Helper script that bootstraps local dev config, starts the gateway, and prints the headless OAuth next step
- **openclaw-auth-codex** -- Post-launch helper that runs `codex login --device-auth` and switches OpenClaw to `openai-codex/gpt-5.4`
- **openclaw-init-telegram** -- Post-auth helper that enables the native Telegram channel with `dmPolicy: pairing`

## Recommended Flow

From the repository root:

```bash
openshell sandbox create --name openclaw-sandbox --from .openshell --policy .openshell/policy.yaml --forward 18789 -- openclaw-start
openshell sandbox connect openclaw-sandbox
```

The create step materializes the sandbox from `.openshell/`, applies the bundled `policy.yaml`, starts `openclaw gateway run --dev` in the background, and forwards the local Control UI to `http://127.0.0.1:18789/`.

If you want Telegram in this sandbox, attach an OpenShell provider that injects `TELEGRAM_BOT_TOKEN` at sandbox create time. OpenShell providers cannot be attached after the sandbox already exists.

## Headless ChatGPT Device Auth

This sandbox is intentionally configured for post-launch OAuth. No ChatGPT/OpenAI credentials are stored in Git or pre-baked into repository files.

Inside the connected sandbox, run:

```bash
openclaw-auth-codex
```

Because the sandbox runs headless, the supported flow is ChatGPT device auth through the bundled Codex CLI:

1. Copy the device-auth URL printed by `codex`.
2. Open it in a local browser and complete the ChatGPT sign-in flow.
3. Enter the one-time code shown in the sandbox terminal.
4. Wait for `codex` to finish, then `openclaw-auth-codex` sets `openai-codex/gpt-5.4` as the default model.

Verified result after successful login:

- `openclaw models status --json --agent dev` resolves the default model to `openai-codex/gpt-5.4`;
- `openclaw models list --agent dev` shows `openai-codex/gpt-5.4` as `default, configured`.

## Telegram Bootstrap

Expected precondition:

- the sandbox was created with an attached OpenShell provider that injects `TELEGRAM_BOT_TOKEN`.

Inside the connected sandbox, after OpenAI Plus auth:

```bash
openclaw-init-telegram
```

The helper:

- configures the native OpenClaw Telegram channel via `openclaw channels add --channel telegram --use-env`;
- enforces `dmPolicy: pairing`;
- disables group access with `groupPolicy: disabled`;
- restarts the local `openclaw gateway run --dev` process so the channel config is applied immediately;
- relies on OpenShell's provider system for the token, so no Telegram secret is written into `openclaw.json`.

After that, DM the bot from Telegram and approve the pairing request:

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

If the local UI is not reachable right after `create`, re-run the local tunnel from the machine that is running OpenShell:

```bash
openshell forward start 18789 openclaw-sandbox
```

## OpenShell Policy

The bundled `policy.yaml` includes network policies for the minimum endpoints needed by this flow:

- `auth.openai.com`
- `chatgpt.com`
- `api.openai.com`
- `api.telegram.org`

The policy is scoped to `/usr/bin/openclaw` and `/usr/bin/node`.

## Build

```bash
docker build -t openshell-openclaw .
```

To build against a specific base image:

```bash
docker build -t openshell-openclaw --build-arg BASE_IMAGE=ghcr.io/nvidia/openshell-community/sandboxes/base:latest .
```

## Manual Startup

If you prefer to start OpenClaw manually inside the sandbox:

```bash
openclaw-start
openclaw-auth-codex
openclaw-init-telegram
```

## Configuration

OpenClaw stores its state under `~/.openclaw/` inside the sandbox, which resolves to `/sandbox/.openclaw/` in this image. The main config file is `~/.openclaw/openclaw.json`.
