#!/usr/bin/env bash
# One-time (idempotent, re-runnable) setup: registers the containerized
# PostToolUse capture hook in ~/.claude/settings.json via `ts init`.
#
# This needs read-write access to ~/.claude, unlike the main MCP wrapper
# (token-savior-mcp.sh) which mounts it read-only — kept as a separate
# script so write access is scoped to this one command.
#
# `ts init` prints a diff and prompts before writing; re-running is a no-op
# if the hook is already installed, and it auto-backs-up settings.json.
#
# Usage: token-savior-init.sh [--dry-run] [--yes]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="ghcr.io/jasonkoopmans/token-savior:latest"

exec docker run --rm -it \
  -v "$HOME/.claude:/root/.claude" \
  -v "$REPO_DIR/agent-hooks:/agent-hooks:ro" \
  "$IMAGE" \
  ts init --agent claude --ts-root /agent-hooks "$@"
