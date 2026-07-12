# example

A minimal Alpine-based scaffold that prints a greeting. Use it as the template
for real containers: copy this folder, edit the `Dockerfile`, and commit.

## Image

```
ghcr.io/OWNER/example:latest
ghcr.io/OWNER/example:0.1.0
```

(`OWNER` is your GitHub username/org — it's filled in automatically by CI.)

## Versioning

The version lives in [`VERSION`](VERSION). Bump it in the **same commit** that
changes this container. On push to `main`, CI rebuilds this folder and publishes:

- `:<version>` (e.g. `0.1.0`) — the exact release
- `:0.1` and `:0` — rolling major / major.minor (semver only)
- `:latest` — most recent build
- `:sha-<short>` — the exact commit

## Run locally

```
make run C=example
# or
docker run --rm ghcr.io/OWNER/example:latest
```
