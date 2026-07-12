# containers

A monorepo of containers I author for myself. One folder per container; each is
versioned and published independently to the
[GitHub Container Registry (GHCR)](https://ghcr.io) on every push to `main`.

## Layout

```
<container>/
  Dockerfile        # required — its presence is what marks a folder as a container
  VERSION           # required — semver string, the source of truth for tags
  README.md         # what it is / how to use it
  .dockerignore     # keep docs + VERSION out of the build context
.github/workflows/
  build.yml         # detect changed containers → scan → build + push only those
  scan.yml          # daily re-scan of published images
  renovate.yml      # self-hosted Renovate (automated dependency updates)
renovate.json       # Renovate config (what to update, auto-merge policy)
.mise.toml          # pinned CLI tools (Trivy, hadolint) for local + CI parity
scripts/new-container.sh
Makefile
```

## Adding a container

```bash
make new C=my-tool        # scaffolds my-tool/ with Dockerfile + VERSION 0.1.0
# edit my-tool/Dockerfile
git add my-tool && git commit -m "add my-tool" && git push
```

The push to `main` builds `my-tool` and publishes it. Nothing else rebuilds.

## Versioning (per container)

Each container owns a [`VERSION`](example/VERSION) file containing a semver
string like `1.4.0`. **Bump it in the same commit** that changes the container.
CI reads it and pushes these tags:

| Tag              | Example        | Meaning                              |
| ---------------- | -------------- | ------------------------------------ |
| `:<version>`     | `:1.4.0`       | the exact release                    |
| `:<major>.<minor>` | `:1.4`       | rolling — latest patch of that minor |
| `:<major>`       | `:1`           | rolling — latest minor of that major |
| `:latest`        | `:latest`      | most recent build                    |
| `:sha-<short>`   | `:sha-a1b2c3d` | the exact commit that built it       |

If you change a container's files but forget to bump `VERSION`, the build still
runs and **overwrites** the existing version tag — CI prints a warning in that
case. The rolling and `sha-` tags always move forward.

## What triggers a build

- **Push to `main`** — CI diffs the push and builds every top-level folder that
  changed and contains a `Dockerfile`. Root-level doc changes are ignored.
- **Manual** — from the repo's *Actions → build → Run workflow*, optionally
  naming a single container; leave it blank to rebuild everything.

Images are built for **`linux/amd64` and `linux/arm64`** (arm64 runs natively on
Apple Silicon and ARM servers). arm64 is emulated under QEMU during the build,
so it's slower; drop `,linux/arm64` from the workflow's `platforms:` for
amd64-only, faster builds.

## Security scanning

Every build scans the exact image **before** it is pushed, using
[Trivy](https://trivy.dev) (pinned in [`.mise.toml`](.mise.toml)):

- **Gate:** the publish is **blocked** if Trivy finds a **fixable HIGH or
  CRITICAL** vulnerability. Un-fixable ones are reported but don't block.
- **Reporting:** all HIGH/CRITICAL findings (plus [hadolint](https://github.com/hadolint/hadolint)
  Dockerfile lint) are uploaded to the repo's **Security → Code scanning** tab.
- **Daily re-scan:** [`scan.yml`](.github/workflows/scan.yml) re-scans the
  already-published images every day, so CVEs disclosed *after* a build still
  surface. A failed scheduled run is the notification.
- **PRs:** pull requests build + scan but do **not** push — that run is the check
  that gates auto-merge (below).

Run the same scan locally: `mise install && trivy image <ref>`.

## Automated updates

[Renovate](https://docs.renovatebot.com) ([`renovate.json`](renovate.json)) runs
as a self-hosted GitHub Action ([`renovate.yml`](.github/workflows/renovate.yml))
and keeps these current:

- **Base images** (`FROM alpine:3.24`) — a base bump is also how a container's
  packaged tool (e.g. `lpass`) moves forward.
- **GitHub Actions** versions in the workflows.
- **Pinned CLI tools** in `.mise.toml` (Trivy, hadolint).

**Auto-merge policy:** digest/patch/minor updates auto-merge **once the build +
scan pass** on the PR; **major** updates open a PR for you to review. This only
works with a real token (see setup) — Renovate's PRs must trigger CI.

## Pulling an image

```bash
docker pull ghcr.io/OWNER/example:1.4.0     # OWNER = your GitHub username/org
```

## First-time setup (one-time, ~2 min)

Everything is free on GHCR for public images (unlimited storage, bandwidth, and
pulls), but a few settings need flipping once:

1. **Create the GitHub repo** and push this code to the `main` branch (see
   below). The workflow authenticates to GHCR automatically via the built-in
   `GITHUB_TOKEN` — no secrets to configure.
2. **After the first successful build**, each image starts as a **private**
   package. For each one, open it under your profile's *Packages* tab →
   *Package settings* → **Change visibility → Public**, and link it to this repo
   under *Manage Actions access* if it isn't already.
3. That's it for publishing — subsequent pushes just work.

> Storage and bandwidth are free today; GitHub has committed to 30 days' notice
> before any GHCR billing begins.

### Enabling automated updates (Renovate)

Renovate needs a token that is **not** the default `GITHUB_TOKEN`, because PRs
opened by `GITHUB_TOKEN` don't trigger other workflows — and the build/scan run
on the PR is what gates auto-merge.

1. Create a **fine-grained PAT** (or classic PAT with `repo` + `workflow`) scoped
   to this repo, with read/write on *Contents*, *Pull requests*, and *Workflows*.
2. Add it as a repo secret named **`RENOVATE_TOKEN`** (*Settings → Secrets and
   variables → Actions*). Until it's set, the `renovate` workflow is a no-op.
3. *(Recommended)* Turn on **branch protection** for `main` requiring the `build`
   check, so nothing merges — auto-merge included — until the scan passes.
4. Trigger the first run manually: *Actions → renovate → Run workflow*.

## Local development

```bash
make list                 # list all containers
make build C=example      # build locally
make run   C=example      # build + run
```

By default `make` derives `OWNER` from your git user name; override it to match
your GitHub handle: `make build C=example OWNER=your-gh-username`.
