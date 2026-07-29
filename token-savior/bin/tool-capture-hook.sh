#!/usr/bin/env bash
# PostToolUse hook command wired into ~/.claude/settings.json by
# token-savior-init.sh (see ../agent-hooks/hooks/tool-capture-hooks-config.json).
# Claude Code invokes this directly on the host for every matching tool call
# (Bash|WebFetch|Read|Grep|...), piping the event JSON on stdin and reading
# the hook response JSON on stdout. It runs the real hook logic inside the
# token-savior image so the host never needs Python for this — at the cost
# of container-startup latency on every matching tool call. Set
# TS_CAPTURE_DISABLED=1 in your shell to no-op without uninstalling the hook.
set -euo pipefail

IMAGE="ghcr.io/jasonkoopmans/token-savior:latest"
DB_DIR="$HOME/.local/share/token-savior"

mkdir -p "$DB_DIR"

exec docker run --rm -i \
  -v "$DB_DIR:/root/.local/share/token-savior" \
  -e TS_CAPTURE_DISABLED \
  -e TS_CAPTURE_THRESHOLD_BYTES \
  -e TS_CAPTURE_REPLACE \
  --entrypoint python3 \
  "$IMAGE" \
  /usr/local/bin/tool_capture_hook.py
