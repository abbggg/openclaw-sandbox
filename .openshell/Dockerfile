# syntax=docker/dockerfile:1.4

# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# OpenClaw sandbox image for OpenShell
#
# Builds on the community base sandbox and adds OpenClaw.
# Build:  docker build -t openshell-openclaw --build-arg BASE_IMAGE=openshell-base .
# Run:    openshell sandbox create --from openclaw

ARG BASE_IMAGE=ghcr.io/nvidia/openshell-community/sandboxes/base:latest
ARG OPENCLAW_VERSION=2026.4.9
FROM ${BASE_IMAGE}

USER root

# Install OpenClaw CLI pinned to the latest verified upstream release.
RUN npm install -g "openclaw@${OPENCLAW_VERSION}"

# Copy sandbox policy
COPY policy.yaml /etc/openshell/policy.yaml

# Copy the OpenClaw startup helper
COPY openclaw-start.sh /usr/local/bin/openclaw-start
RUN chmod +x /usr/local/bin/openclaw-start

# Copy the HH vacancies helper.
COPY bin/openclaw-hh-vacancies /usr/local/bin/openclaw-hh-vacancies
RUN chmod +x /usr/local/bin/openclaw-hh-vacancies

# Copy the OpenAI Codex auth helper.
COPY openclaw-auth-codex.sh /usr/local/bin/openclaw-auth-codex
RUN chmod +x /usr/local/bin/openclaw-auth-codex

# Copy the Telegram bootstrap helper.
COPY openclaw-init-telegram.sh /usr/local/bin/openclaw-init-telegram
RUN chmod +x /usr/local/bin/openclaw-init-telegram

# Seed custom workspace skills and create OpenClaw state dirs.
COPY skills/hh-vacancies /sandbox/.agents/skills/hh-vacancies

RUN mkdir -p /sandbox/.openclaw /sandbox/.agents/skills && \
    chown -R sandbox:sandbox /sandbox/.openclaw /sandbox/.agents

USER sandbox

ENTRYPOINT ["/bin/bash"]
