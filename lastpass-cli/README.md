# lastpass-cli

[`lpass`](https://github.com/lastpass/lastpass-cli), the LastPass command-line
client, compiled from source into a small Debian-based image.

## Image

```
ghcr.io/jasonkoopmans/lastpass-cli:1.6.1
ghcr.io/jasonkoopmans/lastpass-cli:latest
```

The image version tracks the upstream `lpass` release. To bump it, update the
`LASTPASS_CLI_VERSION` arg in the [Dockerfile](Dockerfile) **and** [VERSION](VERSION)
together, then commit.

## Usage

`lpass` is the entrypoint, so arguments are passed straight through:

```bash
docker run --rm ghcr.io/jasonkoopmans/lastpass-cli --version
docker run --rm ghcr.io/jasonkoopmans/lastpass-cli show --help
```

### Persisting your login

`lpass` keeps its encrypted vault and session under `~/.lpass` (`LPASS_HOME`).
A container is ephemeral, so mount a volume there to stay logged in across runs:

```bash
# Log in once (interactive; -it gives lpass a TTY for the password prompt)
docker run --rm -it -v lpass:/root/.lpass \
  ghcr.io/jasonkoopmans/lastpass-cli login you@example.com

# Reuse the session on later runs by mounting the same volume
docker run --rm -v lpass:/root/.lpass \
  ghcr.io/jasonkoopmans/lastpass-cli ls
```

### Non-interactive login (scripts / CI)

Disable pinentry and feed the master password on stdin:

```bash
echo "$LASTPASS_PASSWORD" | docker run --rm -i -v lpass:/root/.lpass \
  -e LPASS_DISABLE_PINENTRY=1 \
  ghcr.io/jasonkoopmans/lastpass-cli login you@example.com
```

### Get a shell instead

```bash
docker run --rm -it --entrypoint bash -v lpass:/root/.lpass \
  ghcr.io/jasonkoopmans/lastpass-cli
```

## Security notes

- The mounted `~/.lpass` volume holds your **decrypted session key while logged
  in** — treat it like a credential. `lpass logout` (or removing the volume)
  clears it.
- Never bake your master password or the vault into the image; pass secrets at
  run time via stdin or the volume only.

## Build locally

```bash
make build C=lastpass-cli
make run   C=lastpass-cli        # runs `lpass --help`
```
