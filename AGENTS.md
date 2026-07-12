# AGENTS.md

Guidance for AI agents (and humans) working in this repository. User-facing
setup lives in [README.md](README.md); this file captures conventions, the CI
model, and environment gotchas needed to work here safely.

## What this is

A monorepo of personal container images. **Each top-level folder that contains a
`Dockerfile` is one container**, built and published independently to the GitHub
Container Registry (GHCR) on every push to `main`.

- Owner / registry: `ghcr.io/jasonkoopmans/<container>` (CI lowercases image refs).
- Repo: https://github.com/JasonKoopmans/containers

## Conventions

- **One container per top-level folder.** A folder is a build target **iff** it
  contains a `Dockerfile`. Folders without one (`.github/`, `scripts/`) are never
  built, and neither are root-level files.
- **Every container folder must have a `VERSION` file** holding a semver string
  (e.g. `1.4.0`). It is the per-container source of truth for image tags.
- **Bump `VERSION` in the same commit** that changes a container. If you change a
  container's files without bumping `VERSION`, CI still builds and **overwrites**
  the existing version tag — it prints a non-blocking warning in that case.
- Keep docs/metadata out of the image via each folder's `.dockerignore`
  (excludes `README.md` and `VERSION`).

## CI model — [.github/workflows/build.yml](.github/workflows/build.yml)

- **Triggers:** push to `main` (root docs — `README.md`, `AGENTS.md`,
  `CLAUDE.md`, `.gitignore`, `LICENSE` — are path-ignored), or manual
  `workflow_dispatch`.
- **`detect` job:** diffs `github.event.before`..`github.sha`, maps each changed
  file to its top-level folder, keeps only folders that contain a `Dockerfile`,
  and emits them as a JSON build matrix. A first push / force-push / missing base
  → builds **all** containers. `workflow_dispatch` takes an optional `container`
  input (blank = all).
- **`build` job:** one matrix leg per changed container. Reads
  `<container>/VERSION`, computes tags, logs into GHCR with the built-in
  `GITHUB_TOKEN`, and builds + pushes for `linux/amd64,linux/arm64`.
- **No external secrets.** `permissions: packages: write` on the workflow is what
  lets `GITHUB_TOKEN` push to GHCR.
- The matrix builder is intentionally **jq-free** (pure bash). Do not reintroduce
  a `jq` dependency (see gotchas).

## Tagging scheme (per container, derived from `VERSION`)

For `VERSION=1.4.0`, CI pushes: `1.4.0`, `1.4`, `1`, `latest`, `sha-<shortsha>`.
A non-semver `VERSION` value only gets `<version>`, `latest`, and `sha-*` (the
rolling `major` / `major.minor` tags are skipped).

## Adding a container

```bash
make new C=my-tool     # scaffolds my-tool/{Dockerfile,VERSION=0.1.0,README.md,.dockerignore}
# edit my-tool/Dockerfile, then:
git add my-tool && git commit -m "add my-tool" && git push
```

The **first** build of each new package creates a **private** GHCR package;
visibility must be flipped to Public manually in the GitHub UI (Packages → the
image → Package settings). **Agents must not change package visibility or other
access controls programmatically — leave that to the user.**

## Local development

```bash
make list              # list containers
make build C=example   # build locally
make run   C=example   # build + run
```

`OWNER` defaults to the lowercased git user name; override to match GHCR:
`make build C=example OWNER=jasonkoopmans`.

## Environment gotchas

- **`jq` on this machine is a Docker shim** (`ghcr.io/jqlang/jqexport`), not a
  native binary — it needs network + GHCR auth and fails offline/unauthenticated.
  Use `python3 -c` for JSON locally. (CI runners have a real `jq`, but the
  workflow avoids it regardless.)
- **Multi-arch builds emulate arm64 under QEMU** → slower. Drop `,linux/arm64`
  from the workflow's `platforms:` for faster amd64-only builds.
- The **"Node.js 20 is deprecated"** annotations in Actions runs are harmless
  (GitHub runtime deprecation); the pinned action majors are current.

## Working style here

- Validate the workflow after edits: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build.yml'))"`.
- Commit a container's changes together with its `VERSION` bump.
- Commit/push only when the user asks.
