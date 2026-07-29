# token-savior

[token-savior](https://github.com/mibayy/token-savior) (PyPI:
`token-savior-recall`) as a containerized MCP server: tree-sitter based code
indexing, cross-session memory, and transcript analysis for Claude Code —
without installing Python packages on your Mac. Base image: `python:3.11-slim`
(+ `libgomp1` for the `memory-vector` extra's onnxruntime dependency).

## Image

```
ghcr.io/jasonkoopmans/token-savior:4.4.1
ghcr.io/jasonkoopmans/token-savior:latest
```

`VERSION` tracks the pinned `token-savior-recall` PyPI package version, kept
in sync with the `pip install` pin in the [Dockerfile](Dockerfile).

## What's included, what isn't

- **Included:** the MCP server itself (code search/indexing, memory tools,
  `memory-vector` semantic search extra).
- **Included, opt-in:** the `tool_capture` PostToolUse hook, which sandboxes
  large Bash/Read/Grep/WebFetch outputs into token-savior's memory so the
  agent can retrieve them later. Wired up via [bin/token-savior-init.sh](bin/token-savior-init.sh)
  (see below) — it fires on *every* matching tool call, so it adds
  container-startup latency (roughly 100-300ms) to each one. Disable at any
  time without uninstalling by exporting `TS_CAPTURE_DISABLED=1`.
- **Deliberately excluded:** `TS_BASH_COMPACT` / `TS_BASH_REWRITE` (token-savior's
  own Bash-output-compaction and PreToolUse command-rewriting). These
  overlap with [`rtk`](https://github.com/getrtk/rtk), which already handles
  Bash command rewriting for this user — running both would mean two hooks
  competing over the same Bash tool calls. `rtk` remains the only Bash
  rewriter; this container never sets those two env vars or merges the
  `bash-rewriter-config.json` hook.
- **Deliberately excluded:** "code mode" (in-container Node.js execution) —
  `TS_CODE_MODE_DISABLE=1` is set by default, keeping the image Python-only.

## One-time setup

### 1. Build (or pull) the image

```bash
make build C=token-savior          # local build, or:
docker pull ghcr.io/jasonkoopmans/token-savior:latest
```

### 2. Register the capture hook (optional but recommended)

```bash
chmod +x token-savior/bin/*.sh      # if not already executable
token-savior/bin/token-savior-init.sh --dry-run   # review the diff first
token-savior/bin/token-savior-init.sh              # apply (prompts unless --yes)
```

This runs `ts init --agent claude` inside a throwaway container that mounts
`~/.claude` **read-write** just for this one command — the only place this
container touches your Claude Code config with write access. It merges a
hook entry pointing at [bin/tool-capture-hook.sh](bin/tool-capture-hook.sh)
(not a bare `python3` call — see [Design notes](#design-notes)) into
`~/.claude/settings.json`, backing up the original to
`settings.json.bak-YYYYMMDD-HHMMSS` first. Re-running is a no-op if already
installed.

**Note:** the hook command is written as an absolute path to this cloned
repo. If you move or re-clone this repo, re-run `token-savior-init.sh` to
update the path.

### 3. Point Claude Code at the MCP server

Add to your Claude Code MCP config (project `.mcp.json` or user-level
config):

```json
{
  "mcpServers": {
    "token-savior": {
      "command": "/Users/jake/Documents/code/containers/token-savior/bin/token-savior-mcp.sh",
      "args": []
    }
  }
}
```

By default the wrapper mounts `$PWD` as the project root — verify Claude
Code launches the MCP command with your project directory as its working
directory; if it doesn't, pass the project path explicitly instead:

```json
"args": ["/Users/jake/Documents/code/myproject"]
```

## Usage

Once configured, Claude Code starts the container automatically per
session — nothing to run manually. To test directly:

```bash
token-savior/bin/token-savior-mcp.sh /path/to/some/project
```

It should sit waiting on stdio (an MCP client, not a human, talks to it) —
Ctrl-C to stop.

## Persistent state

- **Memory DB** (`~/.local/share/token-savior/memory.db` inside the
  container, i.e. `/root/.local/share/token-savior/memory.db`): mounted from
  `~/.local/share/token-savior` on the host so it survives each ephemeral
  `docker run --rm`. This is the only host directory the containers in this
  package write to.
- **`~/.claude`**: mounted **read-only** by the main MCP wrapper and the
  capture hook (for transcript analysis); mounted **read-write** only by
  `token-savior-init.sh`, and only for that one command.
- **Project directory**: mounted read-write at `/workspace` for the
  duration of each MCP server invocation (needed for code indexing/editing
  tools).

## Design notes

- **Transport:** stdio only — there's no HTTP/SSE mode, so the MCP client
  execs the wrapper script as its "command," which runs `docker run -i --rm`
  and pipes stdio straight through.
- **Why the capture hook isn't a bare `python3` call:** `ts init` normally
  writes a hook command pointing at wherever the package is installed
  (e.g. inside a venv or site-packages). If run from *inside* this
  container, that path only exists in the image, not on the host, so a
  literal `ts init` run there would produce a broken hook. Instead,
  [agent-hooks/hooks/tool-capture-hooks-config.json](agent-hooks/hooks/tool-capture-hooks-config.json)
  is a hand-maintained copy of token-savior's bundled hook config, pointed
  at [bin/tool-capture-hook.sh](bin/tool-capture-hook.sh) — a host-side
  script that itself runs the real hook logic inside a throwaway container,
  keeping the host free of Python for this feature too.
- **Not verified against a live install (flag if something's off):** the
  exact latency of the per-call capture hook, and whether Claude Code sets
  the MCP server's working directory to the active project (affecting the
  `$PWD` default in `token-savior-mcp.sh`). Test both after wiring this up.

## Security notes

- `~/.claude` is read-only everywhere except the one-time init command.
- The memory DB directory (`~/.local/share/token-savior`) is the only
  writable host state; delete it to reset token-savior's memory entirely.
- Never bake secrets into the image — none are required (token-savior is
  stateless besides the mounted memory DB).

## Build locally

```bash
make build C=token-savior
make run   C=token-savior   # runs `token-savior` with no mounts (mostly useful for a smoke test)
```
