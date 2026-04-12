#!/usr/bin/env bash

# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# openclaw-start — Start the OpenClaw gateway and print the next headless auth step.
# Designed for OpenShell sandboxes.
set -euo pipefail

gateway_log="${OPENCLAW_GATEWAY_LOG:-/tmp/gateway.log}"
gateway_port="${OPENCLAW_GATEWAY_PORT:-18789}"
config_file="${HOME}/.openclaw/openclaw.json"

mkdir -p "${HOME}/.openclaw"

# Keep the local gateway bootable even if another helper previously rewrote
# the config and dropped the gateway section.
openclaw config set gateway.mode '"local"' --strict-json >/dev/null 2>&1 || true
openclaw config set gateway.bind '"loopback"' --strict-json >/dev/null 2>&1 || true

# Keep OpenClaw action prompts disabled inside the sandbox. OpenShell network
# policy remains the actual boundary for outbound access.
openclaw exec-policy preset yolo --json >/dev/null 2>&1 || true

if pgrep -u "$(id -u)" -f "openclaw gateway run" >/dev/null 2>&1; then
    echo "OpenClaw gateway is already running."
else
    setsid -f sh -lc "exec openclaw gateway run --dev > \"${gateway_log}\" 2>&1 < /dev/null"
fi

gateway_ready=0
for _ in {1..10}; do
    if grep -q "Missing config" "${gateway_log}" 2>/dev/null; then
        echo "OpenClaw gateway exited early. Check ${gateway_log}." >&2
        exit 1
    fi
    if grep -q "starting HTTP server" "${gateway_log}" 2>/dev/null || grep -q "ready (" "${gateway_log}" 2>/dev/null; then
        gateway_ready=1
        break
    fi
    sleep 1
done

if [ "${gateway_ready}" -ne 1 ]; then
    echo "OpenClaw gateway start is still in progress. Check ${gateway_log} if the UI is not reachable."
fi

token=$(grep -o '"token"\s*:\s*"[^"]*"' "${config_file}" 2>/dev/null | head -1 | cut -d'"' -f4 || true)

echo ""
echo "OpenClaw gateway is running in background."
echo "  Logs: ${gateway_log}"
if [ -n "${token}" ]; then
    echo "  UI:   http://127.0.0.1:${gateway_port}/?token=${token}"
else
    echo "  UI:   http://127.0.0.1:${gateway_port}/"
fi
echo ""
echo "Headless OpenAI Plus login:"
echo "  1. Connect to the sandbox."
echo "  2. Run: openclaw-auth-codex"
echo "  3. Open the printed device-auth URL in a local browser."
echo "  4. Enter the one-time code and finish ChatGPT sign-in."
echo ""
echo "Telegram bootstrap:"
echo "  5. Run: openclaw-init-telegram"
echo "  6. DM the bot in Telegram."
echo "  7. Run: openclaw pairing list telegram"
echo "  8. Run: openclaw pairing approve telegram <CODE>"
echo ""
echo "HH vacancy helper:"
echo "  - Run: openclaw-hh-vacancies search --text 'python developer' --per-page 5"
echo "  - Skill: openclaw skills info hh-vacancies"
echo "  - Action prompts: disabled via 'openclaw exec-policy preset yolo'"
echo "OpenClaw official catalogs:"
echo "  - Docs: openclaw docs mcp"
echo "  - Skills and plugins: openclaw skills search hh"
echo ""
