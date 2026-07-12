# lastpass-cli — the LastPass command-line client (`lpass`).
#
# Installed from Alpine's community package rather than compiled from source:
# the Alpine maintainers keep it patched for the current toolchain, and unpatched
# upstream v1.6.1 no longer builds on modern GCC/musl. The `lpass` version tracks
# the Alpine release (alpine:3.24 ships lpass 1.6.1); bump the base image to move
# it, and keep ./VERSION in sync with the shipped lpass version.
FROM alpine:3.24

LABEL org.opencontainers.image.title="lastpass-cli" \
      org.opencontainers.image.description="LastPass command-line interface (lpass)" \
      org.opencontainers.image.version="1.6.1" \
      org.opencontainers.image.source="https://github.com/lastpass/lastpass-cli"

# pinentry gives lpass an interactive password prompt; ca-certificates for TLS.
RUN apk add --no-cache lastpass-cli pinentry ca-certificates

# lpass stores its encrypted vault + session under ~/.lpass. Mount a volume
# there (e.g. -v lpass:/root/.lpass) to keep your login across `docker run`s.
ENV LPASS_HOME=/root/.lpass

ENTRYPOINT ["lpass"]
CMD ["--help"]
