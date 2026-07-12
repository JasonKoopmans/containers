# Example container — copy this folder (or run `make new C=<name>`) to start a new one.
# See ../README.md for how versioning, tagging, and publishing work.
FROM alpine:3.24

LABEL org.opencontainers.image.title="example" \
      org.opencontainers.image.description="Example container scaffold."

RUN apk add --no-cache ca-certificates

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
