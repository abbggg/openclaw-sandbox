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

apply_codex_yolo_backend() {
    if ! openclaw config patch --stdin >/dev/null <<'JSON'
{
  "agents": {
    "defaults": {
      "cliBackends": {
        "codex-cli": {
          "command": "codex",
          "args": [
            "exec",
            "--json",
            "--color",
            "never",
            "--dangerously-bypass-approvals-and-sandbox",
            "-c",
            "service_tier=\"fast\"",
            "--skip-git-repo-check"
          ],
          "resumeArgs": [
            "exec",
            "resume",
            "{sessionId}",
            "--dangerously-bypass-approvals-and-sandbox",
            "-c",
            "service_tier=\"fast\"",
            "--skip-git-repo-check"
          ]
        }
      }
    }
  }
}
JSON
    then
        echo "Warning: failed to configure Codex CLI yolo backend." >&2
    fi
}

codex login --device-auth

openclaw models set codex-cli/gpt-5.5
openclaw config set agents.defaults.thinkingDefault '"high"' --strict-json
openclaw exec-policy preset yolo --json >/dev/null 2>&1 || true
apply_codex_yolo_backend

echo ""
echo "OpenClaw model auth configured."
echo "  Default model: codex-cli/gpt-5.5"
echo "  Reasoning: high"
echo "  Yolo mode: OpenClaw approvals and nested Codex sandbox disabled"
echo ""
echo "Next:"
echo "  1. Run: openclaw models status --json --agent main"
echo "  2. Run: openclaw-init-telegram"
