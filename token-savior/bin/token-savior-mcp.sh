#!/usr/bin/env bash
# Runs the token-savior MCP server in a container over stdio. This is the
# command a Claude Code MCP client config should point at (see README.md).
#
# Usage: token-savior-mcp.sh [project-dir]   (default: $PWD)
set -euo pipefail

PROJECT_DIR="${1:-$PWD}"
IMAGE="ghcr.io/jasonkoopmans/token-savior:latest"
DB_DIR="$HOME/.local/share/token-savior"

mkdir -p "$DB_DIR"

exec docker run -i --rm \
  -v "$PROJECT_DIR:/workspace" \
  -v "$HOME/.claude:/root/.claude:ro" \
  -v "$DB_DIR:/root/.local/share/token-savior" \
  -e PROJECT_ROOT=/workspace \
  "$IMAGE"
