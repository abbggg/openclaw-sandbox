# OpenClaw Sandbox

OpenShell sandbox image pre-configured with [OpenClaw](https://github.com/openclaw) for open agent manipulation and control.

## OpenShell Layout

This directory is the runnable sandbox contract for OpenShell-compatible tooling.
The repository root may contain any repo-level files that are useful to humans, but it is not used for sandbox materialization.

## What's Included

- **OpenClaw CLI 2026.5.7** -- Agent orchestration and gateway management
- **Codex CLI 0.130.0** -- ChatGPT device auth and `gpt-5.5` runtime support
- **OpenClaw Gateway** -- Local gateway for agent-to-tool communication, enabled persistently by the host-side create helper
- **Node.js 22** -- Runtime required by the OpenClaw gateway
- **HH vacancies helper** -- `openclaw-hh-vacancies` for public or OAuth-backed vacancy search via `api.hh.ru`
- **HH OpenClaw skill** -- custom skill materialized into `~/.agents/skills/hh-vacancies`
- **openclaw-start** -- Helper script that prints the headless OAuth next step and can repair/restart the gateway on demand
- **openclaw-sandbox-command** -- Foreground OpenShell sandbox command that keeps the gateway running across pod restarts
- **openclaw-auth-codex** -- Post-launch helper that runs `codex login --device-auth` and switches OpenClaw to `codex-cli/gpt-5.5` with high reasoning
- **openclaw-init-telegram** -- Post-auth helper that enables the native Telegram channel in pairing mode, disables native Telegram exec approvals, and keeps group access disabled

## Recommended Flow

From the repository root:

```bash
scripts/openclaw_create_env.sh --sandbox-id openclaw-sandbox
scripts/openshell_connect_env.sh --sandbox-id openclaw-sandbox openclaw-sandbox
```

The create step materializes the sandbox from `.openshell/`, applies the bundled `policy.yaml`, attaches a combined OpenShell provider that injects `TELEGRAM_BOT_TOKEN` plus optional `HH_*` credentials from a per-sandbox secrets file, then patches the Sandbox CR so OpenShell launches the baked `openclaw-sandbox-command` on every pod boot.

`openclaw-sandbox-command` repairs `gateway.mode=local`, `gateway.bind=loopback`, and `discovery.mdns.mode=off`, applies the official `openclaw exec-policy preset yolo` preset, and keeps the gateway in the foreground so OpenClaw stays alive across sandbox pod restarts. `scripts/openclaw_create_env.sh` applies the required Sandbox CR patch automatically. `openclaw-start` remains the human-facing helper for first-run instructions and manual recovery if you intentionally stop the gateway inside an existing shell session.

For a second materialization such as `openclaw-natasha`, create a dedicated secrets file first and override only the sandbox id:

```bash
chmod 600 ~/.config/robolaba/openclaw-natasha.env
scripts/openclaw_create_env.sh --sandbox-id openclaw-natasha
scripts/openshell_connect_env.sh --sandbox-id openclaw-natasha openclaw-sandbox
```

Default secret resolution for the helper is `~/.config/robolaba/<sandbox-id>.env`, for example `~/.config/robolaba/openclaw-natasha.env`. OpenShell providers cannot be attached after the sandbox already exists.

The helper always requires `TELEGRAM_BOT_TOKEN`. If any of `HH_CLIENT_ID`, `HH_CLIENT_SECRET`, `HH_REDIRECT_URI`, or `HH_USER_AGENT` is present in that file, all four must be present so one combined provider can inject the full HH credential set.

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
4. Wait for `codex` to finish, then `openclaw-auth-codex` sets `codex-cli/gpt-5.5` as the default model with high reasoning.

Verified result after successful login:

- `openclaw models status --json --agent main` resolves the default model to `codex-cli/gpt-5.5`;
- `openclaw models list --agent main` shows `codex-cli/gpt-5.5` as `default, configured`;
- `~/.openclaw/openclaw.json` stores `agents.defaults.thinkingDefault` as `high`.

## Telegram Bootstrap

Expected precondition:

- the sandbox was created with an attached OpenShell provider that injects `TELEGRAM_BOT_TOKEN`.

Inside the connected sandbox, after OpenAI Plus auth:

```bash
openclaw-init-telegram
```

The helper:

- configures the native OpenClaw Telegram channel via `openclaw channels add --channel telegram --use-env`;
- enforces `dmPolicy: pairing`, so direct messages still require explicit pairing approval;
- disables Telegram-native exec approvals because `openclaw-start` already applies the `yolo` exec preset for in-sandbox actions;
- disables group access with `groupPolicy: disabled`;
- restarts the local `openclaw gateway run --dev` process, or starts it if it is absent, so the channel config is applied immediately;
- relies on OpenShell's provider system for the token, so no Telegram secret is written into `openclaw.json`.

Do not move the gateway into a plain sidecar container. The attached provider credentials arrive as `openshell:resolve:env:*` placeholders and are only resolved correctly on the main OpenShell sandbox command path.

DM the bot from Telegram and approve the pairing request:

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
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

Because the sandbox starts with the `yolo` exec preset, `hh-vacancies` can execute `openclaw-hh-vacancies ...` without per-search OpenClaw approval prompts.

If Telegram claims it cannot read `~/.agents/skills/hh-vacancies/SKILL.md`, verify the skill first with `openclaw skills info hh-vacancies`. If the skill is reported as `Ready`, retry the request before changing filesystem permissions.

## OpenShell Policy

The bundled `policy.yaml` includes network policies for the minimum endpoints needed by this flow:

- `auth.openai.com`
- `chatgpt.com`
- `api.openai.com`
- `docs.openclaw.ai`
- `clawhub.ai`
- `registry.npmjs.org`
- `api.telegram.org`
- `api.hh.ru`
- `gist.github.com`
- `gist.githubusercontent.com`

The policy is scoped to `/usr/bin/openclaw`, `/usr/bin/node`, `/usr/bin/curl`, `/bin/bash`, the Python runtime inside `/sandbox/.venv` / `/sandbox/.uv`, and the local helper `/usr/local/bin/openclaw-hh-vacancies`.

Per the current official OpenClaw docs, `docs.openclaw.ai` is the live docs index used by `openclaw docs`, and ClawHub is the public OpenClaw registry for skills and plugins. `openclaw docs` currently shells out through `npx mcporter` when `mcporter` is not already installed, so the policy also allows `registry.npmjs.org` for that runtime path. The same official docs do not describe a separate hosted OpenClaw MCP marketplace, so remote MCP servers still need their own explicit allowlist entries if you decide to use them.

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

For normal lifecycle this manual step is no longer required: `scripts/openclaw_create_env.sh` patches the sandbox runtime so OpenShell launches `/usr/local/bin/openclaw-sandbox-command` automatically on every pod boot.

## Configuration

OpenClaw stores its state under `~/.openclaw/` inside the sandbox, which resolves to `/sandbox/.openclaw/` in this image. The main config file is `~/.openclaw/openclaw.json`.

Current runtime notes:

- `scripts/openclaw_create_env.sh` patches `OPENSHELL_SANDBOX_COMMAND=/usr/local/bin/openclaw-sandbox-command` into the Sandbox CR and keeps the gateway alive across pod restarts.
- The foreground gateway path uses `openclaw gateway run --dev`; the default agent id inside this sandbox is still `main`, not `dev`.
