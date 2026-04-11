#!/usr/bin/env bash

# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# openclaw-init-telegram -- Enable the native Telegram channel using env-backed auth.
#
# Expected flow:
#   1. sandbox is created with an attached OpenShell provider that injects
#      TELEGRAM_BOT_TOKEN
#   2. user completes OpenAI Plus auth manually
#   3. this helper enables Telegram with dmPolicy=pairing
set -euo pipefail

require_command() {
    local command_name="$1"
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        printf 'Required command is not available: %s\n' "${command_name}" >&2
        exit 1
    fi
}

require_command openclaw

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
    cat >&2 <<'EOF'
TELEGRAM_BOT_TOKEN is not available in the sandbox environment.
Recreate the sandbox with an attached OpenShell provider that injects TELEGRAM_BOT_TOKEN.
EOF
    exit 1
fi

if ! openclaw config get channels.telegram.enabled >/dev/null 2>&1; then
    openclaw channels add --channel telegram --use-env
fi

openclaw config set channels.telegram.enabled true --strict-json
openclaw config set channels.telegram.dmPolicy '"pairing"' --strict-json
openclaw config set channels.telegram.groupPolicy '"disabled"' --strict-json
openclaw config unset channels.telegram.botToken >/dev/null 2>&1 || true
openclaw config unset channels.telegram.tokenFile >/dev/null 2>&1 || true

if pgrep -u "$(id -u)" -f "openclaw gateway run" >/dev/null 2>&1; then
    echo "Restarting OpenClaw gateway to apply Telegram channel config."
    pkill -u "$(id -u)" -f "openclaw gateway run" || true
    sleep 1
    openclaw-start >/dev/null
fi

echo "Telegram channel configured."
echo "  DM policy: pairing"
echo "  Group policy: disabled"
echo ""
echo "Next:"
echo "  1. DM the bot in Telegram."
echo "  2. Run: openclaw pairing list telegram"
echo "  3. Run: openclaw pairing approve telegram <CODE>"
echo "  4. Optional check: openclaw channels status --probe"
