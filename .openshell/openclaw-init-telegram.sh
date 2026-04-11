#!/usr/bin/env bash

# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# openclaw-init-telegram -- Enable the native Telegram channel using env-backed auth.
#
# Expected flow:
#   1. sandbox is created with an attached OpenShell provider that injects
#      TELEGRAM_BOT_TOKEN
#   2. user completes OpenAI Plus auth manually
#   3. this helper enables Telegram in pairing mode by default, or in trusted
#      allowlist mode when OPENCLAW_TELEGRAM_ALLOW_FROM is available
set -euo pipefail

require_command() {
    local command_name="$1"
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        printf 'Required command is not available: %s\n' "${command_name}" >&2
        exit 1
    fi
}

require_command openclaw

normalize_numeric_json_array() {
    local raw_value="$1"

    if [[ "${raw_value}" == \[* ]]; then
        printf '%s' "${raw_value}"
        return 0
    fi

    local compact_value="${raw_value//[[:space:]]/}"
    local -a ids=()
    local id=""
    local first=1

    IFS=',' read -r -a ids <<<"${compact_value}"
    if [[ ${#ids[@]} -eq 0 ]]; then
        printf 'OPENCLAW_TELEGRAM_ALLOW_FROM is empty.\n' >&2
        return 1
    fi

    printf '['
    for id in "${ids[@]}"; do
        [[ -n "${id}" ]] || continue
        if [[ ! "${id}" =~ ^[0-9]+$ ]]; then
            printf 'OPENCLAW_TELEGRAM_ALLOW_FROM must contain numeric Telegram user ids. Got: %s\n' "${id}" >&2
            return 1
        fi
        if [[ ${first} -eq 0 ]]; then
            printf ','
        fi
        printf '%s' "${id}"
        first=0
    done
    printf ']'
}

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
openclaw config set channels.telegram.groupPolicy '"disabled"' --strict-json
openclaw config unset channels.telegram.botToken >/dev/null 2>&1 || true
openclaw config unset channels.telegram.tokenFile >/dev/null 2>&1 || true

telegram_mode="pairing"
if [[ -n "${OPENCLAW_TELEGRAM_ALLOW_FROM:-}" ]]; then
    telegram_allow_from_json="$(normalize_numeric_json_array "${OPENCLAW_TELEGRAM_ALLOW_FROM}")"
    telegram_mode="allowlist"

    openclaw config set channels.telegram.allowFrom "${telegram_allow_from_json}" --strict-json
    openclaw config set channels.telegram.dmPolicy '"allowlist"' --strict-json
    openclaw config set channels.telegram.execApprovals.enabled true --strict-json
    openclaw config set channels.telegram.execApprovals.approvers "${telegram_allow_from_json}" --strict-json
    openclaw config set channels.telegram.execApprovals.target '"dm"' --strict-json
    openclaw config set commands.allowFrom.telegram "${telegram_allow_from_json}" --strict-json
    openclaw config set commands.ownerAllowFrom "${telegram_allow_from_json}" --strict-json
    openclaw config set tools.elevated.allowFrom.telegram "${telegram_allow_from_json}" --strict-json
else
    openclaw config set channels.telegram.dmPolicy '"pairing"' --strict-json
    openclaw config unset channels.telegram.allowFrom >/dev/null 2>&1 || true
    openclaw config unset channels.telegram.execApprovals >/dev/null 2>&1 || true
    openclaw config unset commands.allowFrom.telegram >/dev/null 2>&1 || true
    openclaw config unset commands.ownerAllowFrom >/dev/null 2>&1 || true
    openclaw config unset tools.elevated.allowFrom.telegram >/dev/null 2>&1 || true
fi

if pgrep -u "$(id -u)" -f "openclaw gateway run" >/dev/null 2>&1; then
    echo "Restarting OpenClaw gateway to apply Telegram channel config."
    pkill -u "$(id -u)" -f "openclaw gateway run" || true
    sleep 1
    openclaw-start >/dev/null
fi

echo "Telegram channel configured."
echo "  Group policy: disabled"
if [[ "${telegram_mode}" == "allowlist" ]]; then
    echo "  DM policy: allowlist"
    echo "  Allowed Telegram user ids: ${OPENCLAW_TELEGRAM_ALLOW_FROM}"
    echo ""
    echo "Next:"
    echo "  1. DM the bot in Telegram from an allowlisted account."
    echo "  2. Optional check: openclaw channels status --probe"
else
    echo "  DM policy: pairing"
    echo ""
    echo "Next:"
    echo "  1. DM the bot in Telegram."
    echo "  2. Run: openclaw pairing list telegram"
    echo "  3. Run: openclaw pairing approve telegram <CODE>"
    echo "  4. Optional check: openclaw channels status --probe"
fi
