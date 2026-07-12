# lastpass-cli — the LastPass command-line client (`lpass`), compiled from the
# upstream release tarball. Recipe follows the maintainers' contrib/Dockerfile
# (https://github.com/lastpass/lastpass-cli), split into a multi-stage build so
# the final image ships only the binary + runtime libraries.
#
# IMPORTANT: keep LASTPASS_CLI_VERSION in sync with ./VERSION (both = 1.6.1).
ARG DEBIAN_TAG=bookworm-slim

# ---- build stage: compile lpass from source ---------------------------------
FROM debian:${DEBIAN_TAG} AS build
ARG LASTPASS_CLI_VERSION=1.6.1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install --no-install-recommends -yqq \
      build-essential \
      cmake \
      pkg-config \
      ca-certificates \
      curl \
      libcurl4-openssl-dev \
      libssl-dev \
      libxml2-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN curl -fsSL "https://github.com/lastpass/lastpass-cli/archive/refs/tags/v${LASTPASS_CLI_VERSION}.tar.gz" \
      | tar -xz --strip-components=1 \
 && make \
 && make install \
 && lpass --version

# ---- runtime stage: binary + shared libs only -------------------------------
FROM debian:${DEBIAN_TAG} AS runtime
ARG LASTPASS_CLI_VERSION=1.6.1

LABEL org.opencontainers.image.title="lastpass-cli" \
      org.opencontainers.image.description="LastPass command-line interface (lpass)" \
      org.opencontainers.image.version="${LASTPASS_CLI_VERSION}" \
      org.opencontainers.image.source="https://github.com/lastpass/lastpass-cli"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install --no-install-recommends -yqq \
      ca-certificates \
      libcurl4 \
      libssl3 \
      libxml2 \
      pinentry-curses \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/bin/lpass /usr/bin/lpass

# lpass stores its encrypted vault + session under ~/.lpass. Mount a volume
# there (e.g. -v lpass:/root/.lpass) to keep your login across `docker run`s.
ENV LPASS_HOME=/root/.lpass

ENTRYPOINT ["lpass"]
CMD ["--help"]
