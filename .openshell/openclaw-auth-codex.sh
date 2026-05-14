#!/usr/bin/env bash

# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# openclaw-auth-codex -- Authenticate via Codex CLI device flow and pin the
# OpenClaw default model and reasoning to the OAuth-backed OpenAI Codex provider.
set -euo pipefail

export HOME="${HOME:-/sandbox}"
export PATH="${HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

require_command() {
    local command_name="$1"
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        printf 'Required command is not available: %s\n' "${command_name}" >&2
        exit 1
    fi
}

require_command codex
require_command openclaw

codex login --device-auth

openclaw models set codex-cli/gpt-5.5
openclaw config set agents.defaults.thinkingDefault '"high"' --strict-json

echo ""
echo "OpenClaw model auth configured."
echo "  Default model: codex-cli/gpt-5.5"
echo "  Reasoning: high"
echo ""
echo "Next:"
echo "  1. Run: openclaw models status --json --agent main"
echo "  2. Run: openclaw-init-telegram"
