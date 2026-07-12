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
  build.yml         # detect changed containers → build + push only those
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
3. That's it — subsequent pushes just work.

> Storage and bandwidth are free today; GitHub has committed to 30 days' notice
> before any GHCR billing begins.

## Local development

```bash
make list                 # list all containers
make build C=example      # build locally
make run   C=example      # build + run
```

By default `make` derives `OWNER` from your git user name; override it to match
your GitHub handle: `make build C=example OWNER=your-gh-username`.
