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
HOOK_SCRIPT="$REPO_DIR/bin/tool-capture-hook.sh"

# Build a temporary agent-hooks tree with the placeholder resolved to the
# user's actual clone location (the static JSON uses __HOOK_COMMAND__ so the
# repo never contains a machine-specific path).
TMPDIR_HOOKS="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_HOOKS"' EXIT
mkdir -p "$TMPDIR_HOOKS/hooks"
sed "s|__HOOK_COMMAND__|$HOOK_SCRIPT|g" \
  "$REPO_DIR/agent-hooks/hooks/tool-capture-hooks-config.json" \
  > "$TMPDIR_HOOKS/hooks/tool-capture-hooks-config.json"

docker run --rm -it \
  -v "$HOME/.claude:/root/.claude" \
  -v "$TMPDIR_HOOKS:/agent-hooks:ro" \
  "$IMAGE" \
  ts init --agent claude --ts-root /agent-hooks "$@"
