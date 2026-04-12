#!/usr/bin/env bash

# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# openclaw-auth-codex -- Authenticate via Codex CLI device flow and pin the
# OpenClaw default model to the OAuth-backed OpenAI Codex provider.
set -euo pipefail

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

openclaw models set openai-codex/gpt-5.4

echo ""
echo "OpenClaw model auth configured."
echo "  Default model: openai-codex/gpt-5.4"
echo ""
echo "Next:"
echo "  1. Run: openclaw models status --json --agent main"
echo "  2. Run: openclaw-init-telegram"
