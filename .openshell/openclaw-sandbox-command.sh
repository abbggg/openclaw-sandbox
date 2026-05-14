#!/usr/bin/env bash

# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# openclaw-sandbox-command — Foreground OpenClaw gateway entrypoint for OpenShell.
set -euo pipefail

export HOME="${HOME:-/sandbox}"
export USER="${USER:-sandbox}"
export SHELL="${SHELL:-/bin/bash}"
export PATH="${HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export OPENCLAW_STATE_DIR="${OPENCLAW_STATE_DIR:-${HOME}/.openclaw}"
export OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-${OPENCLAW_STATE_DIR}/openclaw.json}"
export OPENCLAW_NO_RESPAWN="${OPENCLAW_NO_RESPAWN:-1}"
export NODE_COMPILE_CACHE="${NODE_COMPILE_CACHE:-${HOME}/.cache/openclaw-compile-cache}"

mkdir -p "${HOME}/.cache/openclaw-compile-cache" "${OPENCLAW_STATE_DIR}/logs"

# Keep the local gateway bootable even if another helper previously rewrote
# the config and dropped the gateway section.
openclaw config set gateway.mode '"local"' --strict-json >/dev/null 2>&1 || true
openclaw config set gateway.bind '"loopback"' --strict-json >/dev/null 2>&1 || true
openclaw config set discovery.mdns.mode '"off"' --strict-json >/dev/null 2>&1 || true

# Keep OpenClaw action prompts disabled inside the sandbox. OpenShell policy
# remains the actual boundary for outbound access.
openclaw exec-policy preset yolo --json >/dev/null 2>&1 || true

exec openclaw gateway run --dev
