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
  (excludes `README.md`, `VERSION`, `DESCRIPTION`).
- **`<container>/DESCRIPTION`** (optional): one or two sentences used as the GHCR
  package-page description. CI collapses it to one line and publishes it as an
  **index** annotation `org.opencontainers.image.description` (a plain LABEL is
  NOT read for multi-arch package pages), plus a `documentation` link to the
  container's README. **GHCR limitation:** the package README *body* always shows
  the repo root `README.md` — there is no per-folder/per-package README, so
  `DESCRIPTION` (blurb + link) is the only per-package surface.

## CI model — [.github/workflows/build.yml](.github/workflows/build.yml)

- **Triggers:** push to `main`, **pull_request** to `main` (root docs —
  `README.md`, `AGENTS.md`, `CLAUDE.md`, `.gitignore`, `LICENSE` — are
  path-ignored), or manual `workflow_dispatch`.
- **`detect` job:** maps each changed file to its top-level folder, keeps only
  folders that contain a `Dockerfile`, and emits them as a JSON build matrix. Diff
  base is `github.event.before` (push) or the PR base sha (pull_request). A first
  push / force-push / missing base → builds **all** containers. `workflow_dispatch`
  takes an optional `container` input (blank = all).
- **`build` job:** one matrix leg per changed container. Installs Trivy + hadolint
  via mise, lints the Dockerfile (report-only), builds an amd64 image with
  `load: true`, **scans it with Trivy, and gates on fixable HIGH/CRITICAL**, then
  builds + pushes `linux/amd64,linux/arm64`. **The push step is skipped on
  `pull_request`** — PRs build + scan only (the gating check for auto-merge).
- **No external secrets** for building. `permissions: packages: write` lets
  `GITHUB_TOKEN` push to GHCR; `security-events: write` uploads SARIF.
- The matrix builder is intentionally **jq-free** (pure bash). Do not reintroduce
  a `jq` dependency (see gotchas).

## Security scanning & automated updates

- **Scanner:** Trivy, pinned in `.mise.toml` (with hadolint). Same tool/version
  local and CI. Gate policy: block on **fixable HIGH/CRITICAL**; everything else
  is reported to the GitHub Security tab (SARIF).
- **`scan.yml`:** daily scheduled re-scan of the *published* GHCR images (matrix
  over all containers), so post-build CVEs surface. Report-only + fails the run on
  fixable HIGH/CRITICAL as a notification.
- **Updates:** self-hosted Renovate (`renovate.json` + `.github/workflows/renovate.yml`)
  updates base images, GitHub Actions, and `.mise.toml` tools. Auto-merges
  digest/patch/minor once CI passes; majors get a PR. Needs a **`RENOVATE_TOKEN`**
  secret (a PAT/App token, NOT `GITHUB_TOKEN`, so its PRs trigger CI). The workflow
  is a no-op until that secret exists.
- **Base image = tool version** for package-based containers (e.g. `lastpass-cli`
  installs `lpass` via `apk`), so bumping `FROM alpine:X` is what advances the
  tool; keep the container's `VERSION` + `image.version` label in sync when it does.

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
