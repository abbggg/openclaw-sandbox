# OpenClaw Sandbox

OpenShell sandbox image pre-configured with [OpenClaw](https://github.com/openclaw) for open agent manipulation and control.

## OpenShell Layout

This directory is the runnable sandbox contract for OpenShell-compatible tooling.
The repository root may contain any repo-level files that are useful to humans, but it is not used for sandbox materialization.

## What's Included

- **OpenClaw CLI 2026.4.9** -- Agent orchestration and gateway management
- **OpenClaw Gateway** -- Local gateway for agent-to-tool communication
- **Node.js 22** -- Runtime required by the OpenClaw gateway
- **HH vacancies helper** -- `openclaw-hh-vacancies` for public or OAuth-backed vacancy search via `api.hh.ru`
- **HH OpenClaw skill** -- custom skill materialized into `~/.agents/skills/hh-vacancies`
- **openclaw-start** -- Helper script that bootstraps local dev config, starts the gateway, and prints the headless OAuth next step
- **openclaw-auth-codex** -- Post-launch helper that runs `codex login --device-auth` and switches OpenClaw to `openai-codex/gpt-5.4`
- **openclaw-init-telegram** -- Post-auth helper that enables the native Telegram channel in pairing mode or trusted allowlist mode

## Recommended Flow

From the repository root:

```bash
openshell sandbox create --name openclaw-sandbox --from .openshell --policy .openshell/policy.yaml --forward 18789 -- openclaw-start
openshell sandbox connect openclaw-sandbox
```

The create step materializes the sandbox from `.openshell/`, applies the bundled `policy.yaml`, starts `openclaw gateway run --dev` in the background, and forwards the local Control UI to `http://127.0.0.1:18789/`.

`openclaw-start` also normalizes local exec settings for this sandbox: it keeps `tools.exec.host=auto` and pre-allowlists `/usr/local/bin/openclaw-hh-vacancies`, so the HH skill can call the helper without extra exec approvals.

If you want Telegram in this sandbox, attach an OpenShell provider that injects `TELEGRAM_BOT_TOKEN` at sandbox create time. OpenShell providers cannot be attached after the sandbox already exists.

If `OPENCLAW_TELEGRAM_ALLOW_FROM` is present in the current shell or in `~/.config/robolaba/secrets.env`, `scripts/openclaw_create_env.sh` also passes it into the sandbox. That switches `openclaw-init-telegram` to trusted allowlist mode for the listed Telegram user ids and avoids the pairing approval step.

If `HH_CLIENT_ID`, `HH_CLIENT_SECRET`, `HH_REDIRECT_URI`, and `HH_USER_AGENT` are present in the current shell or in `~/.config/robolaba/secrets.env`, `scripts/openclaw_create_env.sh` can also attach an optional HH provider during create.

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
- enforces `dmPolicy: pairing` by default;
- switches to `dmPolicy: allowlist` when `OPENCLAW_TELEGRAM_ALLOW_FROM` is present;
- wires the same allowlist into `commands.allowFrom`, `commands.ownerAllowFrom`, and `tools.elevated.allowFrom` so trusted Telegram operators can trigger exec-backed skills without extra approval prompts;
- enables Telegram-native exec approval fallback for the allowlisted ids in case a tool still requests human confirmation;
- disables group access with `groupPolicy: disabled`;
- restarts the local `openclaw gateway run --dev` process so the channel config is applied immediately;
- relies on OpenShell's provider system for the token, so no Telegram secret is written into `openclaw.json`.

Recommended operator allowlist value:

```bash
OPENCLAW_TELEGRAM_ALLOW_FROM=156859844
```

If `OPENCLAW_TELEGRAM_ALLOW_FROM` is not set, DM the bot from Telegram and approve the pairing request:

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

If `OPENCLAW_TELEGRAM_ALLOW_FROM` is set, pairing is skipped and only the listed Telegram user ids are accepted in direct messages.

If the local UI is not reachable right after `create`, re-run the local tunnel from the machine that is running OpenShell:

```bash
openshell forward start 18789 openclaw-sandbox
```

## HH Vacancy Search

Inside the connected sandbox:

```bash
openclaw-hh-vacancies search --text 'python developer' --per-page 5
openclaw-hh-vacancies search --text 'data engineer' --param schedule=remote --format json
openclaw skills info hh-vacancies
```

The default path is public search without OAuth. If HH starts requiring additional verification or you need authenticated behaviour, run manual OAuth from inside the sandbox:

```bash
openclaw-hh-vacancies login-user
openclaw-hh-vacancies me
openclaw-hh-vacancies search --auth-mode require --text 'python developer' --format json
```

The helper stores tokens in `~/.config/hh_api/token.json`, which resolves to `/sandbox/.config/hh_api/token.json` inside this image.

Verified behaviour in the current sandbox:

- public vacancy search works from inside the sandbox;
- `openclaw-hh-vacancies me` works with a valid applicant OAuth token;
- `search --auth-mode require` may still return `403 forbidden` for that applicant token on `/vacancies`.

Because of that, the helper's default `auto` mode falls back to public search if authenticated vacancy search is forbidden.

The HH helper binary is pre-allowlisted in local OpenClaw approvals, so `hh-vacancies` can execute `openclaw-hh-vacancies ...` without prompting for `/approve` on each search.

## OpenShell Policy

The bundled `policy.yaml` includes network policies for the minimum endpoints needed by this flow:

- `auth.openai.com`
- `chatgpt.com`
- `api.openai.com`
- `api.telegram.org`
- `api.hh.ru`
- `gist.github.com`
- `gist.githubusercontent.com`

The policy is scoped to `/usr/bin/openclaw`, `/usr/bin/node`, `/usr/bin/curl`, `/bin/bash`, the Python runtime inside `/sandbox/.venv` / `/sandbox/.uv`, and the local helper `/usr/local/bin/openclaw-hh-vacancies`.

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
