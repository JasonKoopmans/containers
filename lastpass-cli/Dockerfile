# lastpass-cli — the LastPass command-line client (`lpass`), compiled from the
# upstream release tarball on Alpine (musl). lastpass-cli is packaged in Alpine's
# community repo, so musl support is well-tested. Multi-stage build: compile in a
# builder, ship only the binary + runtime libs (~17 MB total).
#
# IMPORTANT: keep LASTPASS_CLI_VERSION in sync with ./VERSION (both = 1.6.1).
ARG ALPINE_TAG=3.20

# ---- build stage: compile lpass from source ---------------------------------
FROM alpine:${ALPINE_TAG} AS build
ARG LASTPASS_CLI_VERSION=1.6.1

RUN apk add --no-cache \
      build-base \
      cmake \
      pkgconf \
      curl \
      ca-certificates \
      curl-dev \
      openssl-dev \
      libxml2-dev

WORKDIR /src
RUN curl -fsSL "https://github.com/lastpass/lastpass-cli/archive/refs/tags/v${LASTPASS_CLI_VERSION}.tar.gz" \
      | tar -xz --strip-components=1 \
 && make \
 && make install \
 && lpass --version

# ---- runtime stage: binary + shared libs only -------------------------------
FROM alpine:${ALPINE_TAG} AS runtime
ARG LASTPASS_CLI_VERSION=1.6.1

LABEL org.opencontainers.image.title="lastpass-cli" \
      org.opencontainers.image.description="LastPass command-line interface (lpass)" \
      org.opencontainers.image.version="${LASTPASS_CLI_VERSION}" \
      org.opencontainers.image.source="https://github.com/lastpass/lastpass-cli"

# libcurl pulls in the openssl (libcrypto/libssl) runtime libs that lpass links.
RUN apk add --no-cache \
      libcurl \
      libxml2 \
      pinentry \
      ca-certificates

COPY --from=build /usr/bin/lpass /usr/bin/lpass

# lpass stores its encrypted vault + session under ~/.lpass. Mount a volume
# there (e.g. -v lpass:/root/.lpass) to keep your login across `docker run`s.
ENV LPASS_HOME=/root/.lpass

ENTRYPOINT ["lpass"]
CMD ["--help"]
