# token-savior — containerized MCP server for cross-session code/context
# memory (github.com/mibayy/token-savior, PyPI: token-savior-recall). Runs as
# a stdio MCP server; see bin/token-savior-mcp.sh for the docker-run wrapper
# Claude Code execs, and README.md for full setup, including the one-time
# `ts init` hook registration and the containerized PostToolUse capture hook.
#
# Multi-stage: the memory-vector extra (onnxruntime/sqlite-vec/fastembed) has
# prebuilt wheels for the common platforms, but build-essential is kept in a
# throwaway builder stage as a hedge in case any transitive dependency lacks
# a wheel for a given arch (e.g. linux/arm64) and falls back to compiling
# from sdist. The final image stays slim either way.
FROM python:3.11-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
    && rm -rf /var/lib/apt/lists/*

# Pin to the version this container's VERSION file tracks; bump both together.
RUN pip install --no-cache-dir --prefix=/install \
      "token-savior-recall[mcp,memory-vector]==4.4.1"

FROM python:3.11-slim

LABEL org.opencontainers.image.title="token-savior" \
      org.opencontainers.image.description="MCP server for cross-session code/context memory (token-savior)" \
      org.opencontainers.image.version="4.4.1" \
      org.opencontainers.image.source="https://github.com/mibayy/token-savior"

# onnxruntime (memory-vector extra) needs libgomp1 (OpenMP runtime) on Debian.
RUN apt-get update && apt-get install -y --no-install-recommends \
      libgomp1 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local

# Copy the bundled PostToolUse capture-hook script to a stable, well-known
# path so the host-side wrapper (bin/tool-capture-hook.sh) doesn't need to
# track Python's internal site-packages layout across image rebuilds.
RUN python3 -c "\
import pathlib, shutil, token_savior; \
src = pathlib.Path(token_savior.__file__).parent / 'hooks' / 'tool_capture_hook.py'; \
shutil.copy(src, '/usr/local/bin/tool_capture_hook.py')"

# Mount point contract: the host wrapper binds the current project directory
# here and points PROJECT_ROOT at it.
WORKDIR /workspace

# Memory DB path (Path.home()/.local/share/token-savior/memory.db) is under
# root's home since the container runs as root by default; the host wrapper
# mounts a persistent host directory there so it survives `--rm`.
ENV PROJECT_ROOT=/workspace \
    TS_CODE_MODE_DISABLE=1

# Deliberately NOT setting TS_BASH_COMPACT/TS_BASH_REWRITE: the user already
# uses a separate tool (rtk) for Bash command rewriting/compaction, and
# running both would mean two competing PreToolUse rewriters. See README.

ENTRYPOINT ["token-savior"]
